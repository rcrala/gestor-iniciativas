#Requires -Version 7.0
<#
.SYNOPSIS
    Registra el flow plantilla canonica en Dataverse via Web API (SP).

.DESCRIPTION
    Lee solutions/innova-flows/templates/flow-canonico-plantilla.json y crea o
    actualiza la row en la tabla workflow con:
      - category = 5 (Modern Flow)
      - type = 1 (Definition)
      - primaryentity = "none" (trigger manual)
      - clientdata = contenido del JSON serializado
      - solution = innova_core (porque innova_flows aun no esta provisionada)

    Idempotente: busca por uniquename; si existe hace PATCH del clientdata.

    Importante: este script NO activa el flow (statecode queda en 0=Draft).
    Para activarlo, el dueno debe abrirlo en maker portal y hacer click en Turn on.
    Razon: la activacion requiere validar conexiones del trigger, que solo el
    contexto del UI puede resolver. Service Principal puede crear/editar pero
    no garantizar la activacion clean del trigger.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER TemplatePath
    Path al JSON de la plantilla. Default: el de solutions/innova-flows/templates/.

.PARAMETER SolutionUniqueName
    Solution donde registrar el flow. Default: 'innova_core' (la unica
    provisionada en DEV al momento). Cambiar a 'innova_flows' cuando exista.

.EXAMPLE
    pwsh ./scripts/flows/register-flow-template.ps1
#>
[CmdletBinding()]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',

    [string]$TemplatePath = 'solutions/innova-flows/templates/flow-canonico-plantilla.json',

    [string]$SolutionUniqueName = 'innova_core'
)

$ErrorActionPreference = 'Stop'

# === 1. Resolver paths y cargar .env ===
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envFile = Join-Path $repoRoot ".env.$Environment"
if (-not (Test-Path $envFile)) { throw "No existe $envFile. Configurar Service Principal primero (ver docs/runbooks/05-service-principal.md)." }

$jsonPath = if ([System.IO.Path]::IsPathRooted($TemplatePath)) { $TemplatePath } else { Join-Path $repoRoot $TemplatePath }
if (-not (Test-Path $jsonPath)) { throw "No existe el JSON de la plantilla: $jsonPath" }

$envVars = @{}
Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

Write-Host "`n=== INNOVA: Registrar flow plantilla en $($Environment.ToUpper()) ===" -ForegroundColor Cyan
Write-Host "  Source : $jsonPath" -ForegroundColor DarkGray
Write-Host "  Env    : $envUrl" -ForegroundColor DarkGray
Write-Host "  Sol    : $SolutionUniqueName" -ForegroundColor DarkGray

# === 2. Parsear plantilla y extraer clientdata ===
$templateRaw = Get-Content $jsonPath -Raw
$template = $templateRaw | ConvertFrom-Json -Depth 50

$displayName = $template.properties.displayName
if ([string]::IsNullOrWhiteSpace($displayName)) { throw "displayName vacio en la plantilla" }

# El uniquename debe llevar prefijo de publisher y solo [a-z0-9_]
$uniqueName = 'pas_innova_plantilla_patron_estandar'

# clientdata: stringified JSON con {properties:{connectionReferences, definition}, schemaVersion}
$clientDataObj = [pscustomobject]@{
    properties = [pscustomobject]@{
        connectionReferences = $template.properties.connectionReferences
        definition           = $template.properties.definition
    }
    schemaVersion = '1.0.0.0'
}
$clientDataString = $clientDataObj | ConvertTo-Json -Depth 50 -Compress

# === 3. Token SP ===
Write-Host "`n[1/4] Obteniendo token SP..." -ForegroundColor Yellow
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

# === 4. Resolver solution + business unit + system user (owner) ===
Write-Host "`n[2/4] Resolviendo solution + owner..." -ForegroundColor Yellow
$solRes = Invoke-RestMethod -Uri "$apiBase/solutions?`$filter=uniquename eq '$SolutionUniqueName'&`$select=solutionid,uniquename" -Headers $h
if ($solRes.value.Count -eq 0) { throw "Solution '$SolutionUniqueName' no existe en $Environment" }
$solutionId = $solRes.value[0].solutionid
Write-Host "  Solution: $solutionId" -ForegroundColor DarkGray

# Owner del flow = el SP user. Sin owner, el flow no es activable.
$whoAmI = Invoke-RestMethod -Uri "$apiBase/WhoAmI" -Headers $h
$ownerId = $whoAmI.UserId
Write-Host "  Owner (SP user): $ownerId" -ForegroundColor DarkGray

# === 5. Buscar workflow existente ===
Write-Host "`n[3/4] Buscando workflow existente..." -ForegroundColor Yellow
$escName = $uniqueName -replace "'", "''"
$wfQuery = "$apiBase/workflows?`$filter=uniquename eq '$escName'&`$select=workflowid,name,statecode,statuscode,category,type"
$existing = Invoke-RestMethod -Uri $wfQuery -Headers $h

$wfBody = @{
    name              = $displayName
    uniquename        = $uniqueName
    description       = 'PLANTILLA canonica de Power Automate flow para INNOVA. NO MODIFICAR - COPIAR PARA FLOWS NUEVOS. Ver solutions/innova-flows/templates/README.md'
    type              = 1                # Definition
    category          = 5                # Modern Flow (Cloud Flow)
    primaryentity     = 'none'           # trigger manual
    mode              = 0                # Background
    scope             = 4                # Organization
    ondemand          = $true
    iscustomizable    = @{ Value = $true }
    clientdata        = $clientDataString
    'ownerid@odata.bind' = "/systemusers($ownerId)"
}

if ($existing.value.Count -gt 0) {
    $wfId = $existing.value[0].workflowid
    Write-Host "  Existe (id $wfId). Actualizando clientdata..." -ForegroundColor DarkGray

    # Si esta activado (statecode=1), Dataverse rechaza PATCH del clientdata.
    # Hay que desactivarlo primero (statecode=0).
    if ($existing.value[0].statecode -eq 1) {
        Write-Host "  Flow esta activado; desactivando temporalmente para hacer PATCH..." -ForegroundColor DarkGray
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
            try {
                $errMsg = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
            } catch { $errMsg = $_.ErrorDetails.Message }
        }
        Write-Host "  FALLO crear workflow: $errMsg" -ForegroundColor Red
        Write-Host @"

  Si el error menciona 'Modern flow', 'BPF', o 'category', es probable que esta
  via no funcione para Cloud Flows v2 en este environment. Alternativa:

    1. Abrir maker portal -> Solutions -> $SolutionUniqueName -> + New -> Cloud flow -> Instant
    2. Trigger: 'Manually trigger a flow'
    3. Asignar nombre: $displayName
    4. Usar 'My flows' -> Export -> Package (.zip), abrir el .zip y reemplazar el
       definition.json con el contenido de solutions/innova-flows/templates/flow-canonico-plantilla.json
    5. Reimportar el .zip

  Ver docs/runbooks/09-flow-template-canonico.md para el procedimiento manual.
"@ -ForegroundColor Yellow
        throw
    }
}

# === 6. Resumen ===
Write-Host "`n[4/4] Verificando..." -ForegroundColor Yellow
$check = Invoke-RestMethod -Uri "$apiBase/workflows($wfId)?`$select=workflowid,name,statecode,statuscode,category" -Headers $h
Write-Host "  workflowid : $($check.workflowid)" -ForegroundColor DarkGray
Write-Host "  name       : $($check.name)" -ForegroundColor DarkGray
Write-Host "  category   : $($check.category) (5 = Modern Flow)" -ForegroundColor DarkGray
Write-Host "  statecode  : $($check.statecode) (0 = Draft; activar manualmente)" -ForegroundColor DarkGray

Write-Host "`n=== Listo ===" -ForegroundColor Green
Write-Host "Pasos siguientes:" -ForegroundColor Cyan
Write-Host "  1. Abrir maker portal -> Solutions -> $SolutionUniqueName" -ForegroundColor White
Write-Host "  2. Encontrar '$displayName'" -ForegroundColor White
Write-Host "  3. Edit -> revisar la estructura visual" -ForegroundColor White
Write-Host "  4. Turn on (activar)" -ForegroundColor White
Write-Host "  5. Probar con: pwsh ./scripts/flows/test-flow-template.ps1" -ForegroundColor White
