#Requires -Version 7.0
<#
.SYNOPSIS
    G5 (issue #32): migra pas_clasificacion (en pas_iniciativa) y pas_clasificacion_pmo
    (en pas_evaluacionpmo) de Picklist a MultiSelectPicklist, y ajusta las opciones
    del global choice pas_iniciativa_clasificacion a las 4 que pidio el cliente:
    Regulatoria, Operativa, Estrategica, Tecnologia.

.DESCRIPTION
    Pre-condicion: 0 records en pas_iniciativa Y 0 records en pas_evaluacionpmo
    (DEV/QA tipicamente vacios; en PROD esto no se ejecuta).

    Razon del script: Dataverse no permite ALTER de tipo de columna; hay que
    DROP + CREATE para cambiar de Picklist a MultiSelectPicklist. Adicionalmente
    el global choice cambia su cardinal (de 6 a 4 opciones) y los labels que se
    conservan (3 y 4) se renombran.

    Orden de operaciones:
      1. Pre-check: 0 records en ambas tablas
      2. DELETE pas_iniciativa.pas_clasificacion         (libera binding al choice)
      3. DELETE pas_evaluacionpmo.pas_clasificacion_pmo  (libera binding al choice)
      4. Sincronizar opciones del choice:
         - InsertOptionValue 7 'Operativa'
         - InsertOptionValue 8 'Estrategica'
         - UpdateOptionValue 3 -> label 'Regulatoria'
         - UpdateOptionValue 4 -> label 'Tecnologia'
         - DeleteOptionValue 1 (Mejora de proceso)
         - DeleteOptionValue 2 (Nuevo proceso)
         - DeleteOptionValue 5 (Infraestructura)
         - DeleteOptionValue 6 (Otro)
      5. CREATE pas_iniciativa.pas_clasificacion como MultiSelectPicklist
      6. CREATE pas_evaluacionpmo.pas_clasificacion_pmo como MultiSelectPicklist

    Idempotente: si las columnas ya son MultiSelect (re-corrida del script) sale OK
    sin tocar nada.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER Force
    Permite continuar aunque haya >0 records (peligroso, solo para escenarios extremos).

.EXAMPLE
    pwsh ./scripts/setup/migrate-pas-clasificacion-to-multiselect.ps1 -Environment dev
#>
[CmdletBinding()]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# ==============================================================================
# Cargar entorno y obtener token (mismo patron que migrate-pas-estado-to-17values.ps1)
# ==============================================================================

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envFile  = Join-Path $repoRoot ".env.$Environment"
if (-not (Test-Path $envFile)) { throw "No existe $envFile. Crear segun .env.dev.template" }

$envVars = @{}
Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

$tokenRes = Invoke-RestMethod -Method POST `
    -Uri "https://login.microsoftonline.com/$($envVars['INNOVA_TENANT_ID'])/oauth2/v2.0/token" `
    -Body @{
        client_id     = $envVars['INNOVA_SP_CLIENT_ID']
        client_secret = $envVars['INNOVA_SP_CLIENT_SECRET']
        scope         = "$envUrl/.default"
        grant_type    = 'client_credentials'
    }
$apiBase = "$envUrl/api/data/v9.2"
$h = @{ Authorization = "Bearer $($tokenRes.access_token)"; Accept = 'application/json' }
$hWrite = $h.Clone()
$hWrite['Content-Type'] = 'application/json; charset=utf-8'
$hWrite['MSCRM.SolutionUniqueName'] = 'innova_core'

Write-Host "`n=== G5 (issue #32): Migrar pas_clasificacion(_pmo) a MultiSelectPicklist ===" -ForegroundColor Cyan

# ==============================================================================
# Helpers locales
# ==============================================================================

function Get-Attribute {
    param([string]$Entity, [string]$Attribute)
    try {
        return Invoke-RestMethod -Uri "$apiBase/EntityDefinitions(LogicalName='$Entity')/Attributes(LogicalName='$Attribute')" -Headers $h
    } catch {
        if ($_.Exception.Message -match '404|does not exist|Could not find') { return $null }
        throw
    }
}

function Get-AttributeTypeCode {
    param([string]$Entity, [string]$Attribute)
    $attr = Get-Attribute -Entity $Entity -Attribute $Attribute
    if (-not $attr) { return $null }
    # Dataverse particularity: MultiSelectPicklist se reporta como AttributeType='Virtual'
    # (internamente vive en tabla auxiliar de N filas, no como columna escalar). El tipo
    # real esta en AttributeTypeName.Value -> 'MultiSelectPicklistType'.
    if ($attr.AttributeType -eq 'Virtual' -and $attr.AttributeTypeName -and $attr.AttributeTypeName.Value -eq 'MultiSelectPicklistType') {
        return 'MultiSelectPicklist'
    }
    return $attr.AttributeType  # 'Picklist', 'String', 'Money', etc.
}

function Delete-Attribute {
    param([string]$Entity, [string]$Attribute)
    Invoke-RestMethod -Uri "$apiBase/EntityDefinitions(LogicalName='$Entity')/Attributes(LogicalName='$Attribute')" -Method DELETE -Headers $hWrite | Out-Null
}

function Create-MultiSelectAttribute {
    param(
        [string]$Entity,
        [string]$SchemaName,
        [string]$LogicalName,
        [string]$DisplayLabel,
        [string]$DescriptionText,
        [string]$GlobalOptionSetName
    )
    $gos = Invoke-RestMethod -Uri "$apiBase/GlobalOptionSetDefinitions(Name='$GlobalOptionSetName')" -Headers $h
    $body = @{
        '@odata.type'  = 'Microsoft.Dynamics.CRM.MultiSelectPicklistAttributeMetadata'
        SchemaName     = $SchemaName
        LogicalName    = $LogicalName
        DisplayName    = @{ LocalizedLabels = @(@{ Label = $DisplayLabel; LanguageCode = 1033 }) }
        Description    = @{ LocalizedLabels = @(@{ Label = $DescriptionText; LanguageCode = 1033 }) }
        RequiredLevel  = @{ Value = 'None'; CanBeChanged = $true; ManagedPropertyLogicalName = 'canmodifyrequirementlevelsettings' }
        'GlobalOptionSet@odata.bind' = "/GlobalOptionSetDefinitions($($gos.MetadataId))"
    }
    Invoke-RestMethod -Uri "$apiBase/EntityDefinitions(LogicalName='$Entity')/Attributes" `
        -Method POST -Headers $hWrite -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
}

function Insert-OptionValue {
    param([string]$OptionSetName, [int]$Value, [string]$Label)
    $body = @{
        OptionSetName = $OptionSetName
        Value         = $Value
        Label         = @{ LocalizedLabels = @(@{ Label = $Label; LanguageCode = 1033 }) }
        SolutionUniqueName = 'innova_core'
    }
    Invoke-RestMethod -Uri "$apiBase/InsertOptionValue" -Method POST -Headers $hWrite -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
}

function Delete-OptionValue {
    param([string]$OptionSetName, [int]$Value)
    $body = @{
        OptionSetName = $OptionSetName
        Value         = $Value
        SolutionUniqueName = 'innova_core'
    }
    Invoke-RestMethod -Uri "$apiBase/DeleteOptionValue" -Method POST -Headers $hWrite -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
}

function Update-OptionLabel {
    param([string]$OptionSetName, [int]$Value, [string]$NewLabel)
    $body = @{
        OptionSetName = $OptionSetName
        Value         = $Value
        Label         = @{ LocalizedLabels = @(@{ Label = $NewLabel; LanguageCode = 1033 }) }
        MergeLabels   = $false
        SolutionUniqueName = 'innova_core'
    }
    Invoke-RestMethod -Uri "$apiBase/UpdateOptionValue" -Method POST -Headers $hWrite -Body ($body | ConvertTo-Json -Depth 10) | Out-Null
}

function Get-ChoiceCurrentOptions {
    param([string]$Name)
    $os = Invoke-RestMethod -Uri "$apiBase/GlobalOptionSetDefinitions(Name='$Name')/Microsoft.Dynamics.CRM.OptionSetMetadata?`$select=Options" -Headers $h
    $map = @{}
    foreach ($o in $os.Options) {
        $map[[int]$o.Value] = $o.Label.UserLocalizedLabel.Label
    }
    return $map
}

# ==============================================================================
# 1. Pre-check: 0 records
# ==============================================================================

Write-Host "`n[1/5] Verificando que no haya data..." -ForegroundColor Yellow
$iniCount = (Invoke-RestMethod -Uri "$apiBase/pas_iniciativas?`$select=pas_iniciativaid&`$top=1" -Headers $h).value.Count
$pmoCount = (Invoke-RestMethod -Uri "$apiBase/pas_evaluacionpmos?`$select=pas_evaluacionpmoid&`$top=1" -Headers $h).value.Count
Write-Host "  pas_iniciativa: $iniCount records" -ForegroundColor DarkGray
Write-Host "  pas_evaluacionpmo: $pmoCount records" -ForegroundColor DarkGray
if (($iniCount -gt 0 -or $pmoCount -gt 0) -and -not $Force) {
    throw "Hay records en alguna de las tablas. Migracion abortada para evitar data loss. Usa -Force si estas 100% seguro."
}
Write-Host "  OK: sin data, seguro proceder" -ForegroundColor Green

# ==============================================================================
# 2-3. DELETE attributes Picklist (libera binding al choice)
# ==============================================================================

$work = @(
    @{ Entity = 'pas_iniciativa';    Attr = 'pas_clasificacion';     SchemaName = 'pas_Clasificacion';     Display = 'Clasificacion';     Desc = 'G5: multi-select; cliente puede marcar varias categorias (Regulatoria/Operativa/Estrategica/Tecnologia)' }
    @{ Entity = 'pas_evaluacionpmo'; Attr = 'pas_clasificacion_pmo'; SchemaName = 'pas_Clasificacion_PMO'; Display = 'Clasificacion PMO'; Desc = 'G5: multi-select; el PMO puede confirmar/ajustar varias categorias evaluadas' }
)

Write-Host "`n[2/5] Eliminando columnas Picklist actuales (si existen)..." -ForegroundColor Yellow
foreach ($w in $work) {
    $type = Get-AttributeTypeCode -Entity $w.Entity -Attribute $w.Attr
    if (-not $type) {
        Write-Host "  $($w.Entity).$($w.Attr): no existe, skip DELETE" -ForegroundColor DarkYellow
        continue
    }
    if ($type -eq 'MultiSelectPicklist') {
        Write-Host "  $($w.Entity).$($w.Attr): ya es MultiSelectPicklist, skip DELETE" -ForegroundColor DarkYellow
        continue
    }
    Write-Host "  Eliminando $($w.Entity).$($w.Attr) (era $type)..." -ForegroundColor Cyan
    Delete-Attribute -Entity $w.Entity -Attribute $w.Attr
    Write-Host "    [OK] eliminado" -ForegroundColor Green
}
Start-Sleep -Seconds 3  # esperar invalidacion de metadata cache antes de tocar el choice

# ==============================================================================
# 4. Sincronizar opciones del choice (insert nuevos, delete obsoletos, update labels)
# ==============================================================================

Write-Host "`n[3/5] Sincronizando opciones del choice pas_iniciativa_clasificacion..." -ForegroundColor Yellow
$current = Get-ChoiceCurrentOptions -Name 'pas_iniciativa_clasificacion'
Write-Host "  Opciones actuales: $($current.Count)" -ForegroundColor DarkGray
foreach ($k in ($current.Keys | Sort-Object)) {
    Write-Host "    [$k] $($current[$k])" -ForegroundColor DarkGray
}

# Target final segun cliente (G5)
$target = @(
    @{ Value = 3; Label = 'Regulatoria' }
    @{ Value = 4; Label = 'Tecnologia' }
    @{ Value = 7; Label = 'Operativa' }
    @{ Value = 8; Label = 'Estrategica' }
)
$targetValues = $target | ForEach-Object { $_.Value }

# 4a. Insertar nuevos values que no existen
foreach ($t in $target) {
    if ($current.ContainsKey($t.Value)) { continue }
    Write-Host "  [INSERT] Value=$($t.Value) '$($t.Label)'" -ForegroundColor Cyan
    Insert-OptionValue -OptionSetName 'pas_iniciativa_clasificacion' -Value $t.Value -Label $t.Label
}

# 4b. Update labels donde value coincide pero label difiere
foreach ($t in $target) {
    if (-not $current.ContainsKey($t.Value)) { continue }
    if ($current[$t.Value] -eq $t.Label) { continue }
    Write-Host "  [UPDATE] Value=$($t.Value): '$($current[$t.Value])' -> '$($t.Label)'" -ForegroundColor Cyan
    Update-OptionLabel -OptionSetName 'pas_iniciativa_clasificacion' -Value $t.Value -NewLabel $t.Label
}

# 4c. Delete values obsoletos (existen pero no estan en target)
foreach ($v in ($current.Keys | Sort-Object)) {
    if ($targetValues -contains $v) { continue }
    Write-Host "  [DELETE] Value=$v '$($current[$v])'" -ForegroundColor Cyan
    Delete-OptionValue -OptionSetName 'pas_iniciativa_clasificacion' -Value $v
}

Write-Host "  Choice sincronizado." -ForegroundColor Green
Start-Sleep -Seconds 3

# ==============================================================================
# 5-6. CREATE attributes MultiSelectPicklist
# ==============================================================================

Write-Host "`n[4/5] Creando columnas MultiSelectPicklist..." -ForegroundColor Yellow
foreach ($w in $work) {
    $type = Get-AttributeTypeCode -Entity $w.Entity -Attribute $w.Attr
    if ($type -eq 'MultiSelectPicklist') {
        Write-Host "  $($w.Entity).$($w.Attr): ya existe como MultiSelectPicklist, skip CREATE" -ForegroundColor DarkYellow
        continue
    }
    Write-Host "  Creando $($w.Entity).$($w.Attr) (MultiSelectPicklist)..." -ForegroundColor Cyan
    Create-MultiSelectAttribute `
        -Entity $w.Entity `
        -SchemaName $w.SchemaName `
        -LogicalName $w.Attr `
        -DisplayLabel $w.Display `
        -DescriptionText $w.Desc `
        -GlobalOptionSetName 'pas_iniciativa_clasificacion'
    Write-Host "    [OK] creada" -ForegroundColor Green
}

# ==============================================================================
# 5. Validacion final
# ==============================================================================

Write-Host "`n[5/5] Validacion post-migracion..." -ForegroundColor Yellow
$ok = $true
foreach ($w in $work) {
    $type = Get-AttributeTypeCode -Entity $w.Entity -Attribute $w.Attr
    if ($type -eq 'MultiSelectPicklist') {
        Write-Host "  [OK] $($w.Entity).$($w.Attr) es MultiSelectPicklist" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($w.Entity).$($w.Attr) tipo actual: $type (esperado MultiSelectPicklist)" -ForegroundColor Red
        $ok = $false
    }
}
$final = Get-ChoiceCurrentOptions -Name 'pas_iniciativa_clasificacion'
Write-Host "  Choice final ($($final.Count) opciones):" -ForegroundColor DarkGray
foreach ($k in ($final.Keys | Sort-Object)) {
    Write-Host "    [$k] $($final[$k])" -ForegroundColor DarkGray
}
if ($final.Count -ne 4) {
    Write-Host "  [WARN] cardinal esperado=4, real=$($final.Count)" -ForegroundColor DarkYellow
    $ok = $false
}

if (-not $ok) {
    Write-Host "`n=== HUBO FALLAS - revisar arriba ===" -ForegroundColor Red
    exit 1
}
Write-Host "`n=== OK migracion completa ===" -ForegroundColor Green
