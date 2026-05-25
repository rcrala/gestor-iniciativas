#Requires -Version 7.0
<#
.SYNOPSIS
    Smoke test: crea pas_iniciativa via API y valida que el plug-in IniciativaPreCreatePlugin
    asigne automaticamente pas_consecutivo + pas_consecutivo_secuencia + pas_anio.

.EXAMPLE
    pwsh ./scripts/plugins/smoke-test-consecutivo.ps1
#>
[CmdletBinding()]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',

    [switch]$KeepRecord
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envFile = Join-Path $repoRoot ".env.$Environment"
$envVars = @{}
Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

Write-Host "`n=== Smoke test: IniciativaPreCreatePlugin en $($Environment.ToUpper()) ===" -ForegroundColor Cyan

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

# 1. Buscar una empresa con codigo_corto
Write-Host "`n[1/3] Buscando empresa con pas_codigo_corto configurado..." -ForegroundColor Yellow
$empresas = Invoke-RestMethod -Uri "$apiBase/pas_empresas?`$filter=pas_codigo_corto ne null&`$top=5" -Headers $h
if ($empresas.value.Count -eq 0) {
    throw "No hay empresas con pas_codigo_corto configurado en DEV. Correr scripts/setup/07-seed-catalogos.ps1 primero."
}
$empresa = $empresas.value[0]
$empresaDisplayName = if ($empresa.PSObject.Properties.Name -contains 'pas_nombre') { $empresa.pas_nombre } else { '<sin name>' }
Write-Host "  Empresa elegida: $empresaDisplayName (codigo=$($empresa.pas_codigo_corto), id=$($empresa.pas_empresaid))" -ForegroundColor DarkGray

# 2. Crear iniciativa via API (SIN setear consecutivo - el plug-in deberia setearlo)
Write-Host "`n[2/3] Creando pas_iniciativa de prueba (sin consecutivo)..." -ForegroundColor Yellow
$titulo = "SMOKE TEST consecutivo $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$createBody = @{
    pas_titulo = $titulo
    'pas_Empresa@odata.bind' = "/pas_empresas($($empresa.pas_empresaid))"
} | ConvertTo-Json

$resp = Invoke-WebRequest -Uri "$apiBase/pas_iniciativas?`$select=pas_iniciativaid,pas_consecutivo,pas_consecutivo_secuencia,pas_anio,pas_titulo" -Method POST -Headers ($hWrite + @{ Prefer = 'return=representation' }) -Body $createBody
$created = $resp.Content | ConvertFrom-Json
$iniciativaId = $created.pas_iniciativaid

Write-Host "  Iniciativa creada: $iniciativaId" -ForegroundColor DarkGray
Write-Host "  pas_titulo:                 $($created.pas_titulo)" -ForegroundColor DarkGray
Write-Host "  pas_consecutivo:            $($created.pas_consecutivo)" -ForegroundColor White
Write-Host "  pas_consecutivo_secuencia:  $($created.pas_consecutivo_secuencia)" -ForegroundColor White
Write-Host "  pas_anio:                   $($created.pas_anio)" -ForegroundColor White

# 3. Asserts
Write-Host "`n[3/3] Validaciones..." -ForegroundColor Yellow
$expectedAnio = (Get-Date -AsUTC).Year
$expectedPrefix = "$($empresa.pas_codigo_corto)-$expectedAnio-"

$fails = @()
if ([string]::IsNullOrWhiteSpace($created.pas_consecutivo)) {
    $fails += "pas_consecutivo es null/vacio (el plug-in NO se ejecuto correctamente)"
}
elseif (-not $created.pas_consecutivo.StartsWith($expectedPrefix)) {
    $fails += "pas_consecutivo '$($created.pas_consecutivo)' no empieza con '$expectedPrefix'"
}
if ($created.pas_consecutivo_secuencia -lt 1 -or $created.pas_consecutivo_secuencia -gt 999) {
    $fails += "pas_consecutivo_secuencia '$($created.pas_consecutivo_secuencia)' fuera de rango [1,999]"
}
if ($created.pas_anio -ne $expectedAnio) {
    $fails += "pas_anio '$($created.pas_anio)' no coincide con UTC year actual '$expectedAnio'"
}
# Regex completo
$regex = "^[A-Z]{3}-\d{4}-\d{3}$"
if ($created.pas_consecutivo -notmatch $regex) {
    $fails += "pas_consecutivo '$($created.pas_consecutivo)' no matchea regex '$regex'"
}

if ($fails.Count -gt 0) {
    Write-Host "`n  FAIL:" -ForegroundColor Red
    $fails | ForEach-Object { Write-Host "    - $_" -ForegroundColor Red }
    if (-not $KeepRecord) {
        Write-Host "`n  Eliminando registro de prueba..." -ForegroundColor DarkGray
        Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($iniciativaId)" -Method DELETE -Headers $h | Out-Null
    }
    exit 1
}

Write-Host "  OK: consecutivo asignado correctamente y matchea el formato esperado." -ForegroundColor Green

if (-not $KeepRecord) {
    Write-Host "`n  Eliminando registro de prueba (usar -KeepRecord para conservar)..." -ForegroundColor DarkGray
    Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($iniciativaId)" -Method DELETE -Headers $h | Out-Null
} else {
    Write-Host "`n  -KeepRecord activo: iniciativa $iniciativaId queda en DEV para inspeccion." -ForegroundColor Yellow
}

Write-Host "`n=== Smoke test PASSED ===" -ForegroundColor Green
