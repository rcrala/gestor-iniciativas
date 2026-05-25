#Requires -Version 7.0
<#
.SYNOPSIS
    Migra pas_iniciativa.pas_estado del optionset viejo (pas_estados, 3 valores)
    al nuevo pas_iniciativa_estado (17 valores, segun CHANGELOG v1.4 / issue #33).

.DESCRIPTION
    Pre-condicion: 0 records en pas_iniciativa (data loss-safe).
    Estrategia: DELETE attribute + RECREATE con OptionSet global pas_iniciativa_estado.
#>
[CmdletBinding()]
param([ValidateSet('dev','qa')][string]$Environment = 'dev')

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envVars = @{}
Get-Content (Join-Path $repoRoot ".env.$Environment") | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

$tokenRes = Invoke-RestMethod -Method POST `
    -Uri "https://login.microsoftonline.com/$($envVars['INNOVA_TENANT_ID'])/oauth2/v2.0/token" `
    -Body @{
        client_id = $envVars['INNOVA_SP_CLIENT_ID']
        client_secret = $envVars['INNOVA_SP_CLIENT_SECRET']
        scope = "$envUrl/.default"
        grant_type = 'client_credentials'
    }
$apiBase = "$envUrl/api/data/v9.2"
$h = @{ Authorization = "Bearer $($tokenRes.access_token)"; Accept='application/json' }
$hWrite = $h.Clone(); $hWrite['Content-Type'] = 'application/json; charset=utf-8'
$hWrite['MSCRM.SolutionUniqueName'] = 'innova_core'

Write-Host "`n=== Migrar pas_iniciativa.pas_estado a optionset pas_iniciativa_estado ===" -ForegroundColor Cyan

# 1. Verificar 0 data
Write-Host "`n[1/5] Verificando que no hay data..." -ForegroundColor Yellow
$count = (Invoke-RestMethod -Uri "$apiBase/pas_iniciativas?`$select=pas_iniciativaid&`$top=1" -Headers $h).value.Count
if ($count -gt 0) {
    throw "Hay $count registros en pas_iniciativa. Migracion abortada para evitar data loss."
}
Write-Host "  OK: 0 records" -ForegroundColor Green

# 2. Verificar que el optionset destino existe
Write-Host "`n[2/5] Verificando optionset destino pas_iniciativa_estado..." -ForegroundColor Yellow
$dest = Invoke-RestMethod -Uri "$apiBase/GlobalOptionSetDefinitions(Name='pas_iniciativa_estado')/Microsoft.Dynamics.CRM.OptionSetMetadata?`$select=Options" -Headers $h
Write-Host "  OK: $($dest.Options.Count) values" -ForegroundColor Green

# 3. Verificar attribute actual
Write-Host "`n[3/5] Verificando attribute pas_estado actual..." -ForegroundColor Yellow
$attr = Invoke-RestMethod -Uri "$apiBase/EntityDefinitions(LogicalName='pas_iniciativa')/Attributes(LogicalName='pas_estado')/Microsoft.Dynamics.CRM.PicklistAttributeMetadata?`$expand=GlobalOptionSet" -Headers $h
$currentOptionSet = if ($attr.GlobalOptionSet) { $attr.GlobalOptionSet.Name } else { '<local>' }
Write-Host "  Actual: $currentOptionSet" -ForegroundColor DarkGray
if ($currentOptionSet -eq 'pas_iniciativa_estado') {
    Write-Host "  Ya esta migrado. Nada que hacer." -ForegroundColor Green
    exit 0
}

# 4. DELETE attribute
Write-Host "`n[4/5] Eliminando attribute pas_estado actual..." -ForegroundColor Yellow
Invoke-RestMethod -Uri "$apiBase/EntityDefinitions(LogicalName='pas_iniciativa')/Attributes(LogicalName='pas_estado')" -Method DELETE -Headers $h | Out-Null
Write-Host "  Eliminado" -ForegroundColor Green
Start-Sleep -Seconds 3  # esperar invalidacion de metadata cache

# 5. CREATE nuevo attribute con OptionSet global pas_iniciativa_estado
Write-Host "`n[5/5] Creando nuevo attribute con OptionSet pas_iniciativa_estado..." -ForegroundColor Yellow
$body = @{
    '@odata.type' = 'Microsoft.Dynamics.CRM.PicklistAttributeMetadata'
    SchemaName = 'pas_Estado'
    LogicalName = 'pas_estado'
    DisplayName = @{
        LocalizedLabels = @(
            @{ Label = 'Estado'; LanguageCode = 1033 }
        )
    }
    Description = @{
        LocalizedLabels = @(
            @{ Label = 'Estado actual de la iniciativa (workflow PMO)'; LanguageCode = 1033 }
        )
    }
    RequiredLevel = @{ Value = 'ApplicationRequired' }
    DefaultFormValue = 100000000  # Borrador
    GlobalOptionSet = @{
        '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
        Name = 'pas_iniciativa_estado'
    }
} | ConvertTo-Json -Depth 6

Invoke-RestMethod -Uri "$apiBase/EntityDefinitions(LogicalName='pas_iniciativa')/Attributes" -Method POST -Headers $hWrite -Body $body | Out-Null
Write-Host "  Creado" -ForegroundColor Green

Write-Host "`n=== Migracion completa ===" -ForegroundColor Green
