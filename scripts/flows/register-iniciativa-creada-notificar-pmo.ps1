#Requires -Version 7.0
<#
.SYNOPSIS
    Registra el flow 'INNOVA - Iniciativa Creada - Notificar PMO' en Dataverse via Web API (SP).

.DESCRIPTION
    Lee solutions/innova-flows/flows/INNOVA-iniciativa-creada-notificar-pmo.json y
    crea o actualiza la row en la tabla workflow con:
      - category = 5 (Modern Flow)
      - type = 1 (Definition)
      - primaryentity = "pas_iniciativa" (Dataverse trigger)
      - clientdata = contenido del JSON serializado (incluye connectionReferences)
      - solution = innova_core (por ahora; futuro: innova_flows)

    Idempotente: busca por uniquename; si existe hace PATCH del clientdata.

    Prerrequisitos:
      1. Parametros de notificacion sembrados:
         pwsh ./scripts/setup/09-seed-parametros-notificaciones.ps1
      2. Connection References creadas en innova_core:
         - pas_innova_dataverse (apuntando a la conexion Dataverse del env)
         - pas_innova_office365 (apuntando a la conexion Office365 Outlook)
      3. Plantilla iniciativa_creada_pmo activa en pas_plantillacorreo (ya seedeada en PR #52)

    Importante: este script NO activa el flow (statecode queda 0=Draft). La activacion
    requiere validar las conexiones de los conectores; eso es user-context. Despues de
    registrar, abrir el flow en maker portal y hacer Turn on (asigna las conexiones
    interactivamente).

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER FlowJsonPath
    Path al JSON del flow. Default: solutions/innova-flows/flows/INNOVA-iniciativa-creada-notificar-pmo.json.

.PARAMETER SolutionUniqueName
    Solution donde registrar. Default 'innova_core'.

.EXAMPLE
    pwsh ./scripts/flows/register-iniciativa-creada-notificar-pmo.ps1
#>
[CmdletBinding()]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',

    [string]$FlowJsonPath = 'solutions/innova-flows/flows/INNOVA-iniciativa-creada-notificar-pmo.json',

    [string]$SolutionUniqueName = 'innova_core'
)

$ErrorActionPreference = 'Stop'

# === 1. Resolver paths y cargar .env ===
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envFile = Join-Path $repoRoot ".env.$Environment"
if (-not (Test-Path $envFile)) { throw "No existe $envFile. Configurar Service Principal primero (runbook 05)." }

$jsonPath = if ([System.IO.Path]::IsPathRooted($FlowJsonPath)) { $FlowJsonPath } else { Join-Path $repoRoot $FlowJsonPath }
if (-not (Test-Path $jsonPath)) { throw "No existe el JSON del flow: $jsonPath" }

$envVars = @{}
Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

Write-Host "`n=== INNOVA: Registrar flow Notificar PMO en $($Environment.ToUpper()) ===" -ForegroundColor Cyan
Write-Host "  Source : $jsonPath" -ForegroundColor DarkGray
Write-Host "  Env    : $envUrl" -ForegroundColor DarkGray
Write-Host "  Sol    : $SolutionUniqueName" -ForegroundColor DarkGray

# === 2. Parsear flow y extraer clientdata ===
$templateRaw = Get-Content $jsonPath -Raw
$template = $templateRaw | ConvertFrom-Json -Depth 50

$displayName = $template.properties.displayName
if ([string]::IsNullOrWhiteSpace($displayName)) { throw "displayName vacio en el flow JSON" }

$uniqueName = 'pas_innova_iniciativa_creada_notificar_pmo'

# clientdata: stringified JSON con properties.connectionReferences + properties.definition
$clientDataObj = [pscustomobject]@{
    properties = [pscustomobject]@{
        connectionReferences = $template.properties.connectionReferences
        definition           = $template.properties.definition
    }
    schemaVersion = '1.0.0.0'
}
$clientDataString = $clientDataObj | ConvertTo-Json -Depth 50 -Compress

# === 3. Token SP ===
Write-Host "`n[1/5] Obteniendo token SP..." -ForegroundColor Yellow
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
$hWrite['MSCRM.SolutionUniqueName'] = $SolutionUniqueName
Write-Host "  Token OK" -ForegroundColor Green

# === 4. Resolver solution + owner ===
Write-Host "`n[2/5] Resolviendo solution + owner..." -ForegroundColor Yellow
$solRes = Invoke-RestMethod -Uri "$apiBase/solutions?`$filter=uniquename eq '$SolutionUniqueName'&`$select=solutionid,uniquename" -Headers $h
if ($solRes.value.Count -eq 0) { throw "Solution '$SolutionUniqueName' no existe en $Environment" }
$solutionId = $solRes.value[0].solutionid
Write-Host "  Solution: $solutionId" -ForegroundColor DarkGray

$whoAmI = Invoke-RestMethod -Uri "$apiBase/WhoAmI" -Headers $h
$ownerId = $whoAmI.UserId
Write-Host "  Owner (SP user): $ownerId" -ForegroundColor DarkGray

# === 5. Verificar prerrequisitos (plantilla + parametros) ===
Write-Host "`n[3/5] Verificando prerrequisitos..." -ForegroundColor Yellow

$plantillaRes = Invoke-RestMethod -Uri "$apiBase/pas_plantillacorreos?`$filter=pas_nombre_clave eq 'iniciativa_creada_pmo' and pas_activa eq true&`$select=pas_nombre_clave" -Headers $h
if ($plantillaRes.value.Count -eq 0) {
    Write-Host "  [WARN] Plantilla 'iniciativa_creada_pmo' NO existe o esta inactiva. Sembrar con: pwsh ./scripts/setup/07-seed-catalogos.ps1; luego: pwsh ./scripts/setup/08-update-plantillas-html.ps1" -ForegroundColor Yellow
} else {
    Write-Host "  Plantilla iniciativa_creada_pmo: OK" -ForegroundColor Green
}

foreach ($paramKey in @('PmoDestinatariosCorreo', 'AdminCorreo', 'UrlBaseApp')) {
    $pRes = Invoke-RestMethod -Uri "$apiBase/pas_parametros?`$filter=pas_clave eq '$paramKey'&`$select=pas_clave,pas_valor_texto&`$top=1" -Headers $h
    if ($pRes.value.Count -eq 0) {
        Write-Host "  [WARN] Parametro '$paramKey' NO existe. Sembrar con: pwsh ./scripts/setup/09-seed-parametros-notificaciones.ps1" -ForegroundColor Yellow
    } else {
        Write-Host "  Parametro $paramKey : '$($pRes.value[0].pas_valor_texto)'" -ForegroundColor Green
    }
}

# === 6. Buscar workflow existente ===
Write-Host "`n[4/5] Buscando workflow existente..." -ForegroundColor Yellow
$escName = $uniqueName -replace "'", "''"
$wfQuery = "$apiBase/workflows?`$filter=uniquename eq '$escName'&`$select=workflowid,name,statecode,statuscode,category,type"
$existing = Invoke-RestMethod -Uri $wfQuery -Headers $h

$wfBody = @{
    name              = $displayName
    uniquename        = $uniqueName
    description       = "Primer flow productivo derivado de la plantilla canonica (S0-8). Issue #55 / S1-01. Notifica al PMO via correo cuando se crea una iniciativa. Ver tests/flows/iniciativa-creada-notificar-pmo-test-plan.md."
    type              = 1                          # Definition
    category          = 5                          # Modern Flow (Cloud Flow)
    primaryentity     = 'pas_iniciativa'           # trigger Dataverse Create sobre esta entidad
    mode              = 0                          # Background
    scope             = 4                          # Organization
    ondemand          = $false                     # NO ondemand: dispara por trigger Dataverse
    iscustomizable    = @{ Value = $true }
    clientdata        = $clientDataString
    'ownerid@odata.bind' = "/systemusers($ownerId)"
}

if ($existing.value.Count -gt 0) {
    $wfId = $existing.value[0].workflowid
    Write-Host "  Existe (id $wfId). Actualizando clientdata..." -ForegroundColor DarkGray

    if ($existing.value[0].statecode -eq 1) {
        Write-Host "  Flow esta activado; desactivando temporalmente para PATCH..." -ForegroundColor DarkGray
        $deactivateBody = @{ statecode = 0; statuscode = 1 } | ConvertTo-Json
        Invoke-RestMethod -Uri "$apiBase/workflows($wfId)" -Method PATCH -Headers $hWrite -Body $deactivateBody | Out-Null
    }

    $patchBody = @{
        name        = $displayName
        description = $wfBody.description
        clientdata  = $clientDataString
    } | ConvertTo-Json -Depth 50
    Invoke-RestMethod -Uri "$apiBase/workflows($wfId)" -Method PATCH -Headers $hWrite -Body $patchBody | Out-Null
    Write-Host "  clientdata actualizado" -ForegroundColor Green
} else {
    Write-Host "  No existe. Creando..." -ForegroundColor DarkGray
    $createBody = $wfBody | ConvertTo-Json -Depth 50
    try {
        $resp = Invoke-WebRequest -Uri "$apiBase/workflows" -Method POST -Headers $hWrite -Body $createBody
        $wfId = ($resp.Headers['OData-EntityId'] -join '') -replace '.*workflows\(','' -replace '\).*',''
        Write-Host "  Creado: $wfId" -ForegroundColor Green
    } catch {
        $errMsg = $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            try { $errMsg = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message } catch { $errMsg = $_.ErrorDetails.Message }
        }
        Write-Host "  FALLO crear workflow: $errMsg" -ForegroundColor Red
        Write-Host @"

  Si el error es sobre connection references no resueltas:
    1. Abrir maker portal -> Solutions -> innova_core
    2. + New -> More -> Connection reference
    3. Crear pas_innova_dataverse apuntando a una Connection Dataverse del env
    4. Crear pas_innova_office365 apuntando a una Connection Office365 Outlook
    5. Re-ejecutar este script

  Si el error es sobre primaryentity o category, ver fallback manual en:
    docs/runbooks/09-flow-template-canonico.md (mismo procedimiento aplica)
"@ -ForegroundColor Yellow
        throw
    }
}

# === 7. Resumen ===
Write-Host "`n[5/5] Verificando..." -ForegroundColor Yellow
$check = Invoke-RestMethod -Uri "$apiBase/workflows($wfId)?`$select=workflowid,name,statecode,statuscode,category,primaryentity" -Headers $h
Write-Host "  workflowid    : $($check.workflowid)" -ForegroundColor DarkGray
Write-Host "  name          : $($check.name)" -ForegroundColor DarkGray
Write-Host "  primaryentity : $($check.primaryentity)" -ForegroundColor DarkGray
Write-Host "  category      : $($check.category) (5 = Modern Flow)" -ForegroundColor DarkGray
Write-Host "  statecode     : $($check.statecode) (0 = Draft; activar manualmente)" -ForegroundColor DarkGray

Write-Host "`n=== Listo ===" -ForegroundColor Green
Write-Host "Pasos siguientes:" -ForegroundColor Cyan
Write-Host "  1. Abrir maker portal -> Solutions -> $SolutionUniqueName" -ForegroundColor White
Write-Host "  2. Buscar 'INNOVA - Iniciativa Creada - Notificar PMO'" -ForegroundColor White
Write-Host "  3. Edit: deberian aparecer 4 scopes con runAfter correcto" -ForegroundColor White
Write-Host "  4. Asignar conexiones a las 2 connection references si pide" -ForegroundColor White
Write-Host "  5. Turn on (activar)" -ForegroundColor White
Write-Host "  6. Probar: crear una pas_iniciativa via API y verificar correo a PMO" -ForegroundColor White
Write-Host "     Test plan: tests/flows/iniciativa-creada-notificar-pmo-test-plan.md" -ForegroundColor White
