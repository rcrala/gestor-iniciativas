#Requires -Version 7.0
<#
.SYNOPSIS
    Registra todos los plug-ins de INNOVA en Dataverse via Web API (SP).

.DESCRIPTION
    Data-driven: el array $TypesManifest declara que types registrar y que steps
    crear para cada uno. Idempotente: actualiza Content del PluginAssembly si ya
    existe; salta PluginType y Step si ya estan creados (busqueda por name).

    Tambien crea SdkMessageProcessingStepImage (Pre-Image) cuando un step lo
    declara — necesario para Update steps que dependen de valores actuales no
    incluidos en el target.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER AssemblyPath
    Path al DLL. Default: el de bin/Release/netstandard2.0/.

.EXAMPLE
    pwsh ./scripts/plugins/register-plugin.ps1
#>
[CmdletBinding()]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',

    [string]$AssemblyPath = 'plugins/Pasqui.Innova.Plugins/bin/Release/netstandard2.0/Pasqui.Innova.Plugins.dll'
)

$ErrorActionPreference = 'Stop'

# === Manifest de types + steps a registrar ===
$TypesManifest = @(
    @{
        TypeName = 'Pasqui.Innova.Plugins.Iniciativa.IniciativaPreCreatePlugin'
        FriendlyName = 'INNOVA - Iniciativa Pre-Create (consecutivo)'
        Description = 'Asigna pas_consecutivo automaticamente al crear una iniciativa. Ver docs/architecture/numeracion-consecutivos.md'
        Steps = @(
            @{
                StepName = 'Pasqui.Innova.Plugins.Iniciativa.IniciativaPreCreatePlugin: Create of pas_iniciativa'
                Description = 'Pre-operation Create de pas_iniciativa: asigna pas_consecutivo, pas_consecutivo_secuencia, pas_anio'
                Message = 'Create'
                EntityName = 'pas_iniciativa'
                Stage = 20
                Mode = 0
                Rank = 1
                FilteringAttributes = $null
                PreImages = @()
            }
        )
    },
    # ==========================================================================
    # IniciativaEstadoTransitionPlugin - NO REGISTRADO en este momento
    # ==========================================================================
    # El plug-in CODE esta completo (146 tests passing) pero NO se puede registrar
    # en DEV hasta que se complete la migracion del attribute pas_iniciativa.pas_estado
    # del optionset viejo 'pas_estados' (3 valores 1/5/10) al nuevo
    # 'pas_iniciativa_estado' (17 valores 100000000+) documentado en CHANGELOG v1.4.
    #
    # Bloqueador: la migracion via scripts/setup/migrate-pas-estado-to-17values.ps1
    # falla por 3 dependencias (form refs + step refs). Requiere PR dedicado que:
    #   1. Strip pas_estado de form INNOVA - Iniciativa - Formulario Principal
    #   2. Delete attribute pas_estado
    #   3. Recreate con GlobalOptionSet pas_iniciativa_estado
    #   4. Re-attach al form
    #   5. Activar bloque comentado abajo
    #
    # Ver docs/architecture/estados-iniciativa.md para el flujo de transiciones.
    # ==========================================================================
    # @{
    #     TypeName = 'Pasqui.Innova.Plugins.Iniciativa.IniciativaEstadoTransitionPlugin'
    #     FriendlyName = 'INNOVA - Iniciativa Validacion Transicion Estado'
    #     Description = 'Valida transiciones de pas_estado contra matriz documentada'
    #     Steps = @(
    #         @{ StepName='...Create of pas_iniciativa'; Message='Create'; ... }
    #         @{ StepName='...Update of pas_iniciativa'; Message='Update'; FilteringAttributes='pas_estado'; PreImages=@(@{...}) }
    #     )
    # },
    @{
        TypeName = 'Pasqui.Innova.Plugins.Iniciativa.IniciativaRoiPlugin'
        FriendlyName = 'INNOVA - Iniciativa ROI (auto-calculo)'
        Description = 'Calcula pas_roi_porcentaje = (ahorro - monto) / monto * 100 en Create/Update de pas_iniciativa'
        Steps = @(
            @{
                StepName = 'Pasqui.Innova.Plugins.Iniciativa.IniciativaRoiPlugin: Create of pas_iniciativa'
                Description = 'Pre-operation Create: calcula ROI cuando se pasa monto + ahorro'
                Message = 'Create'
                EntityName = 'pas_iniciativa'
                Stage = 20
                Mode = 0
                Rank = 2  # despues del consecutivo
                FilteringAttributes = $null
                PreImages = @()
            },
            @{
                StepName = 'Pasqui.Innova.Plugins.Iniciativa.IniciativaRoiPlugin: Update of pas_iniciativa'
                Description = 'Pre-operation Update: recalcula ROI cuando cambia monto o ahorro'
                Message = 'Update'
                EntityName = 'pas_iniciativa'
                Stage = 20
                Mode = 0
                Rank = 1
                FilteringAttributes = 'pas_monto_estimado,pas_ahorro_anual_estimado'
                PreImages = @(
                    @{
                        ImageName = 'PreImage'
                        ImageType = 0   # 0=PreImage, 1=PostImage, 2=Both
                        Attributes = 'pas_monto_estimado,pas_ahorro_anual_estimado,pas_roi_porcentaje'
                    }
                )
            }
        )
    }
)

# === 1. Cargar .env ===
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envFile = Join-Path $repoRoot ".env.$Environment"
if (-not (Test-Path $envFile)) { throw "No existe $envFile" }
$envVars = @{}
Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

Write-Host "`n=== INNOVA: Registrar plug-ins en $($Environment.ToUpper()) ===" -ForegroundColor Cyan

# === 2. Resolver path del assembly ===
$dllPath = if ([System.IO.Path]::IsPathRooted($AssemblyPath)) { $AssemblyPath } else { Join-Path $repoRoot $AssemblyPath }
if (-not (Test-Path $dllPath)) {
    throw "DLL no encontrado: $dllPath. Buildear primero con: dotnet build plugins/Pasqui.Innova.Plugins -c Release"
}
$dllInfo = Get-Item $dllPath
Write-Host "  DLL: $dllPath ($([Math]::Round($dllInfo.Length/1KB,1)) KB, mtime $($dllInfo.LastWriteTime))" -ForegroundColor DarkGray

# === 3. Reflection ===
$asmName = [System.Reflection.AssemblyName]::GetAssemblyName($dllPath)
$asmSimpleName = $asmName.Name
$asmVersion = $asmName.Version.ToString()
$asmCulture = if ($asmName.CultureName) { $asmName.CultureName } else { 'neutral' }
$pkBytes = $asmName.GetPublicKeyToken()
$asmPublicKeyToken = ($pkBytes | ForEach-Object { '{0:x2}' -f $_ }) -join ''
Write-Host "  Name: $asmSimpleName, Version: $asmVersion, PKT: $asmPublicKeyToken" -ForegroundColor DarkGray

if ([string]::IsNullOrEmpty($asmPublicKeyToken)) {
    throw "Assembly no esta firmado. Verificar SignAssembly=true y SNK valido."
}
$dllBytes = [System.IO.File]::ReadAllBytes($dllPath)
$contentBase64 = [Convert]::ToBase64String($dllBytes)

# === 4. Token SP ===
$tokenRes = Invoke-RestMethod -Method POST `
    -Uri "https://login.microsoftonline.com/$($envVars['INNOVA_TENANT_ID'])/oauth2/v2.0/token" `
    -Body @{
        client_id = $envVars['INNOVA_SP_CLIENT_ID']
        client_secret = $envVars['INNOVA_SP_CLIENT_SECRET']
        scope = "$envUrl/.default"
        grant_type = 'client_credentials'
    }
$apiBase = "$envUrl/api/data/v9.2"
$h = @{
    Authorization = "Bearer $($tokenRes.access_token)"
    Accept = 'application/json'
    'OData-MaxVersion' = '4.0'
    'OData-Version' = '4.0'
}
$hWrite = $h.Clone()
$hWrite['Content-Type'] = 'application/json; charset=utf-8'
$hWrite['MSCRM.SolutionUniqueName'] = 'innova_core'

# === 5. PluginAssembly ===
Write-Host "`n[1/N] PluginAssembly..." -ForegroundColor Yellow
$existing = Invoke-RestMethod -Uri "$apiBase/pluginassemblies?`$filter=name eq '$asmSimpleName'&`$select=pluginassemblyid,version" -Headers $h
if ($existing.value.Count -gt 0) {
    $pluginAssemblyId = $existing.value[0].pluginassemblyid
    Write-Host "  Existe (id $pluginAssemblyId). Actualizando Content..." -ForegroundColor DarkGray
    $updateBody = @{ content = $contentBase64; version = $asmVersion } | ConvertTo-Json
    Invoke-RestMethod -Uri "$apiBase/pluginassemblies($pluginAssemblyId)" -Method PATCH -Headers $hWrite -Body $updateBody | Out-Null
    Write-Host "  Content actualizado" -ForegroundColor Green
} else {
    $createBody = @{
        name = $asmSimpleName
        sourcetype = 0           # Database
        isolationmode = 2        # Sandbox
        culture = $asmCulture
        version = $asmVersion
        publickeytoken = $asmPublicKeyToken
        content = $contentBase64
        description = 'INNOVA plug-ins (generado por scripts/plugins/register-plugin.ps1)'
    } | ConvertTo-Json
    $resp = Invoke-WebRequest -Uri "$apiBase/pluginassemblies" -Method POST -Headers $hWrite -Body $createBody
    $pluginAssemblyId = ($resp.Headers['OData-EntityId'] -join '') -replace '.*pluginassemblies\(','' -replace '\).*',''
    Write-Host "  Creado: $pluginAssemblyId" -ForegroundColor Green
}

# === 6. Loop sobre el manifest ===
$msgIdCache = @{}
$filterIdCache = @{}

function Get-MessageId([string]$message) {
    if ($msgIdCache.ContainsKey($message)) { return $msgIdCache[$message] }
    $res = Invoke-RestMethod -Uri "$apiBase/sdkmessages?`$filter=name eq '$message'&`$select=sdkmessageid" -Headers $h
    if ($res.value.Count -eq 0) { throw "SdkMessage '$message' no encontrado" }
    $msgIdCache[$message] = $res.value[0].sdkmessageid
    return $msgIdCache[$message]
}

function Get-FilterId([string]$entityName, [string]$messageId) {
    $key = "$entityName|$messageId"
    if ($filterIdCache.ContainsKey($key)) { return $filterIdCache[$key] }
    $res = Invoke-RestMethod -Uri "$apiBase/sdkmessagefilters?`$filter=primaryobjecttypecode eq '$entityName' and _sdkmessageid_value eq $messageId&`$select=sdkmessagefilterid" -Headers $h
    if ($res.value.Count -eq 0) { throw "SdkMessageFilter para $entityName + msg $messageId no encontrado" }
    $filterIdCache[$key] = $res.value[0].sdkmessagefilterid
    return $filterIdCache[$key]
}

$typeIdx = 0
foreach ($typeDef in $TypesManifest) {
    $typeIdx++
    Write-Host ("`n[Type {0}/{1}] {2}..." -f $typeIdx, $TypesManifest.Count, $typeDef.TypeName) -ForegroundColor Yellow

    # PluginType
    $existingType = Invoke-RestMethod -Uri "$apiBase/plugintypes?`$filter=typename eq '$($typeDef.TypeName)' and _pluginassemblyid_value eq $pluginAssemblyId&`$select=plugintypeid" -Headers $h
    if ($existingType.value.Count -gt 0) {
        $pluginTypeId = $existingType.value[0].plugintypeid
        Write-Host "  PluginType existe: $pluginTypeId" -ForegroundColor DarkGray
    } else {
        $typeBody = @{
            typename = $typeDef.TypeName
            friendlyname = $typeDef.FriendlyName
            name = $typeDef.TypeName
            description = $typeDef.Description
            'pluginassemblyid@odata.bind' = "/pluginassemblies($pluginAssemblyId)"
        } | ConvertTo-Json
        $resp = Invoke-WebRequest -Uri "$apiBase/plugintypes" -Method POST -Headers $hWrite -Body $typeBody
        $pluginTypeId = ($resp.Headers['OData-EntityId'] -join '') -replace '.*plugintypes\(','' -replace '\).*',''
        Write-Host "  PluginType creado: $pluginTypeId" -ForegroundColor Green
    }

    # Steps
    foreach ($stepDef in $typeDef.Steps) {
        $messageId = Get-MessageId $stepDef.Message
        $filterId = Get-FilterId $stepDef.EntityName $messageId

        $existingStep = Invoke-RestMethod -Uri "$apiBase/sdkmessageprocessingsteps?`$filter=name eq '$($stepDef.StepName)'&`$select=sdkmessageprocessingstepid" -Headers $h
        if ($existingStep.value.Count -gt 0) {
            $stepId = $existingStep.value[0].sdkmessageprocessingstepid
            Write-Host ("  Step '{0}' existe: {1}" -f $stepDef.Message, $stepId) -ForegroundColor DarkGray
        } else {
            $stepBody = [ordered]@{
                name = $stepDef.StepName
                description = $stepDef.Description
                mode = $stepDef.Mode
                stage = $stepDef.Stage
                rank = $stepDef.Rank
                statecode = 0
                statuscode = 1
                asyncautodelete = $false
                configuration = ''
                'eventhandler_plugintype@odata.bind' = "/plugintypes($pluginTypeId)"
                'sdkmessageid@odata.bind' = "/sdkmessages($messageId)"
                'sdkmessagefilterid@odata.bind' = "/sdkmessagefilters($filterId)"
            }
            if ($stepDef.FilteringAttributes) {
                $stepBody['filteringattributes'] = $stepDef.FilteringAttributes
            }
            $resp = Invoke-WebRequest -Uri "$apiBase/sdkmessageprocessingsteps" -Method POST -Headers $hWrite -Body ($stepBody | ConvertTo-Json)
            $stepId = ($resp.Headers['OData-EntityId'] -join '') -replace '.*sdkmessageprocessingsteps\(','' -replace '\).*',''
            Write-Host ("  Step '{0}' creado: {1}" -f $stepDef.Message, $stepId) -ForegroundColor Green
        }

        # PreImages
        foreach ($imgDef in $stepDef.PreImages) {
            $existingImg = Invoke-RestMethod -Uri "$apiBase/sdkmessageprocessingstepimages?`$filter=name eq '$($imgDef.ImageName)' and _sdkmessageprocessingstepid_value eq $stepId&`$select=sdkmessageprocessingstepimageid" -Headers $h
            if ($existingImg.value.Count -gt 0) {
                Write-Host ("    Image '{0}' existe" -f $imgDef.ImageName) -ForegroundColor DarkGray
            } else {
                $imgBody = @{
                    name = $imgDef.ImageName
                    entityalias = $imgDef.ImageName
                    imagetype = $imgDef.ImageType
                    attributes = $imgDef.Attributes
                    messagepropertyname = 'Target'
                    'sdkmessageprocessingstepid@odata.bind' = "/sdkmessageprocessingsteps($stepId)"
                } | ConvertTo-Json
                Invoke-RestMethod -Uri "$apiBase/sdkmessageprocessingstepimages" -Method POST -Headers $hWrite -Body $imgBody | Out-Null
                Write-Host ("    Image '{0}' creada" -f $imgDef.ImageName) -ForegroundColor Green
            }
        }
    }
}

Write-Host "`n=== Listo. $($TypesManifest.Count) types registrados/actualizados en $($Environment.ToUpper()) ===" -ForegroundColor Green
Write-Host "PluginAssembly: $pluginAssemblyId" -ForegroundColor DarkGray
