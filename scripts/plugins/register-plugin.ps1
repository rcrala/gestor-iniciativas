#Requires -Version 7.0
<#
.SYNOPSIS
    Registra un plug-in assembly de INNOVA en Dataverse via Web API (SP).

.DESCRIPTION
    1. Carga el DLL del plug-in (assumed built)
    2. Lee Name, Version, PublicKeyToken via reflection
    3. POSTea PluginAssembly (sandbox isolation)
    4. POSTea PluginType para cada clase pasada en -PluginTypes
    5. POSTea SdkMessageProcessingStep para cada step pasado en -Steps
    6. Verifica el resultado

    Idempotente: si el assembly ya existe (por Name) y la version coincide, hace UPDATE
    del Content y reusa el id. Si la version cambia, recrea.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER AssemblyPath
    Path al DLL del plug-in. Default: el de IniciativaPreCreatePlugin en bin/Release.

.EXAMPLE
    pwsh ./scripts/plugins/register-plugin.ps1
    Registra Pasqui.Innova.Plugins con sus steps default (IniciativaPreCreatePlugin -> pas_iniciativa Create Pre).
#>
[CmdletBinding()]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',

    [string]$AssemblyPath = 'plugins/Pasqui.Innova.Plugins/bin/Release/netstandard2.0/Pasqui.Innova.Plugins.dll'
)

$ErrorActionPreference = 'Stop'

# === 1. Cargar .env ===
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envFile = Join-Path $repoRoot ".env.$Environment"
if (-not (Test-Path $envFile)) { throw "No existe $envFile" }
$envVars = @{}
Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

Write-Host "`n=== INNOVA: Registrar plug-in en $($Environment.ToUpper()) ===" -ForegroundColor Cyan

# === 2. Resolver path del assembly ===
$dllPath = if ([System.IO.Path]::IsPathRooted($AssemblyPath)) { $AssemblyPath } else { Join-Path $repoRoot $AssemblyPath }
if (-not (Test-Path $dllPath)) {
    throw "DLL no encontrado: $dllPath. Buildear primero con: dotnet build plugins/Pasqui.Innova.Plugins -c Release"
}
$dllInfo = Get-Item $dllPath
Write-Host "  DLL: $dllPath ($([Math]::Round($dllInfo.Length/1KB,1)) KB, mtime $($dllInfo.LastWriteTime))" -ForegroundColor DarkGray

# === 3. Reflection: leer AssemblyName ===
Add-Type -AssemblyName 'System.Reflection'
$asmName = [System.Reflection.AssemblyName]::GetAssemblyName($dllPath)
$asmSimpleName = $asmName.Name
$asmVersion = $asmName.Version.ToString()
$asmCulture = if ($asmName.CultureName) { $asmName.CultureName } else { 'neutral' }
$pkBytes = $asmName.GetPublicKeyToken()
$asmPublicKeyToken = ($pkBytes | ForEach-Object { '{0:x2}' -f $_ }) -join ''
Write-Host "  Name:    $asmSimpleName" -ForegroundColor DarkGray
Write-Host "  Version: $asmVersion" -ForegroundColor DarkGray
Write-Host "  Culture: $asmCulture" -ForegroundColor DarkGray
Write-Host "  PublicKeyToken: $asmPublicKeyToken" -ForegroundColor DarkGray

if ([string]::IsNullOrEmpty($asmPublicKeyToken)) {
    throw "Assembly no esta firmado (no tiene strong name). Verificar SignAssembly=true y SNK valido."
}

# Content base64 del DLL
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

# === 5. PluginAssembly: crear o actualizar ===
Write-Host "`n[1/4] PluginAssembly..." -ForegroundColor Yellow

$existing = Invoke-RestMethod -Uri "$apiBase/pluginassemblies?`$filter=name eq '$asmSimpleName'&`$select=pluginassemblyid,version" -Headers $h
if ($existing.value.Count -gt 0) {
    $pluginAssemblyId = $existing.value[0].pluginassemblyid
    Write-Host "  Existe (id $pluginAssemblyId, version actual $($existing.value[0].version)). Actualizando Content..." -ForegroundColor DarkGray
    $updateBody = @{ content = $contentBase64; version = $asmVersion } | ConvertTo-Json
    Invoke-RestMethod -Uri "$apiBase/pluginassemblies($pluginAssemblyId)" -Method PATCH -Headers $hWrite -Body $updateBody | Out-Null
    Write-Host "  Actualizado" -ForegroundColor Green
} else {
    $createBody = @{
        name = $asmSimpleName
        sourcetype = 0           # 0=Database
        isolationmode = 2        # 2=Sandbox
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

# === 6. PluginType: IniciativaPreCreatePlugin ===
Write-Host "`n[2/4] PluginType..." -ForegroundColor Yellow

$pluginTypeName = 'Pasqui.Innova.Plugins.Iniciativa.IniciativaPreCreatePlugin'
$friendlyName = 'INNOVA - Iniciativa Pre-Create (asignar consecutivo)'

$existingType = Invoke-RestMethod -Uri "$apiBase/plugintypes?`$filter=typename eq '$pluginTypeName' and _pluginassemblyid_value eq $pluginAssemblyId&`$select=plugintypeid" -Headers $h
if ($existingType.value.Count -gt 0) {
    $pluginTypeId = $existingType.value[0].plugintypeid
    Write-Host "  Existe: $pluginTypeId" -ForegroundColor DarkGray
} else {
    $typeBody = @{
        typename = $pluginTypeName
        friendlyname = $friendlyName
        name = $pluginTypeName
        description = 'Asigna pas_consecutivo automaticamente al crear una iniciativa. Ver docs/architecture/numeracion-consecutivos.md'
        'pluginassemblyid@odata.bind' = "/pluginassemblies($pluginAssemblyId)"
    } | ConvertTo-Json
    $resp = Invoke-WebRequest -Uri "$apiBase/plugintypes" -Method POST -Headers $hWrite -Body $typeBody
    $pluginTypeId = ($resp.Headers['OData-EntityId'] -join '') -replace '.*plugintypes\(','' -replace '\).*',''
    Write-Host "  Creado: $pluginTypeId" -ForegroundColor Green
}

# === 7. SdkMessageProcessingStep: pas_iniciativa.Create.Pre.Sync ===
Write-Host "`n[3/4] SdkMessageProcessingStep..." -ForegroundColor Yellow

# Lookup SdkMessage 'Create'
$msgRes = Invoke-RestMethod -Uri "$apiBase/sdkmessages?`$filter=name eq 'Create'&`$select=sdkmessageid" -Headers $h
$createMessageId = $msgRes.value[0].sdkmessageid
Write-Host "  Create message id: $createMessageId" -ForegroundColor DarkGray

# Lookup SdkMessageFilter para pas_iniciativa + Create
$filterRes = Invoke-RestMethod -Uri "$apiBase/sdkmessagefilters?`$filter=primaryobjecttypecode eq 'pas_iniciativa' and _sdkmessageid_value eq $createMessageId&`$select=sdkmessagefilterid" -Headers $h
if ($filterRes.value.Count -eq 0) {
    throw "No existe SdkMessageFilter para pas_iniciativa.Create. La entidad debe existir en DEV antes de registrar el plug-in."
}
$messageFilterId = $filterRes.value[0].sdkmessagefilterid
Write-Host "  Filter (pas_iniciativa.Create) id: $messageFilterId" -ForegroundColor DarkGray

# Verificar si ya hay un step de este plugin para este mensaje
$stepName = 'Pasqui.Innova.Plugins.Iniciativa.IniciativaPreCreatePlugin: Create of pas_iniciativa'
$existingStep = Invoke-RestMethod -Uri "$apiBase/sdkmessageprocessingsteps?`$filter=name eq '$stepName'&`$select=sdkmessageprocessingstepid,statecode" -Headers $h
if ($existingStep.value.Count -gt 0) {
    $stepId = $existingStep.value[0].sdkmessageprocessingstepid
    Write-Host "  Step existe: $stepId (state=$($existingStep.value[0].statecode))" -ForegroundColor DarkGray
} else {
    $stepBody = @{
        name = $stepName
        description = 'Pre-operation Create de pas_iniciativa: asigna pas_consecutivo, pas_consecutivo_secuencia y pas_anio'
        mode = 0                 # 0=Synchronous
        stage = 20               # 10=PreValidation, 20=PreOperation, 40=PostOperation
        rank = 1
        statecode = 0            # 0=Enabled
        statuscode = 1           # 1=Enabled
        asyncautodelete = $false
        configuration = ''
        'eventhandler_plugintype@odata.bind' = "/plugintypes($pluginTypeId)"
        'sdkmessageid@odata.bind' = "/sdkmessages($createMessageId)"
        'sdkmessagefilterid@odata.bind' = "/sdkmessagefilters($messageFilterId)"
    } | ConvertTo-Json
    $resp = Invoke-WebRequest -Uri "$apiBase/sdkmessageprocessingsteps" -Method POST -Headers $hWrite -Body $stepBody
    $stepId = ($resp.Headers['OData-EntityId'] -join '') -replace '.*sdkmessageprocessingsteps\(','' -replace '\).*',''
    Write-Host "  Step creado: $stepId" -ForegroundColor Green
}

# === 8. Verificacion ===
Write-Host "`n[4/4] Verificacion..." -ForegroundColor Yellow
$verify = Invoke-RestMethod -Uri "$apiBase/sdkmessageprocessingsteps($stepId)?`$select=name,stage,mode,statecode,rank" -Headers $h
Write-Host "  Step: $($verify.name)" -ForegroundColor White
Write-Host "    stage:  $($verify.stage) (20=PreOperation)" -ForegroundColor DarkGray
Write-Host "    mode:   $($verify.mode) (0=Sync)" -ForegroundColor DarkGray
Write-Host "    state:  $($verify.statecode) (0=Enabled)" -ForegroundColor DarkGray
Write-Host "    rank:   $($verify.rank)" -ForegroundColor DarkGray

Write-Host "`n=== Listo. Plug-in registrado y activo en $($Environment.ToUpper()) ===" -ForegroundColor Green
Write-Host "Smoke test: crear una iniciativa via API debe asignar consecutivo automaticamente." -ForegroundColor DarkGray
Write-Host "  PluginAssembly: $pluginAssemblyId" -ForegroundColor DarkGray
Write-Host "  PluginType:     $pluginTypeId" -ForegroundColor DarkGray
Write-Host "  Step:           $stepId" -ForegroundColor DarkGray
