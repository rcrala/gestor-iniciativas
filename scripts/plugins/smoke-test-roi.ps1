#Requires -Version 7.0
<#
.SYNOPSIS
    Smoke E2E del plug-in IniciativaRoiPlugin: valida Create + 2 Updates
    (solo monto, solo ahorro) usando PreImage.
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

Write-Host "`n=== Smoke test: IniciativaRoiPlugin en $($Environment.ToUpper()) ===" -ForegroundColor Cyan

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
$hReturn = $hWrite.Clone()
$hReturn['Prefer'] = 'return=representation'

function Get-RoiFields([string]$id) {
    return Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($id)?`$select=pas_monto_estimado,pas_ahorro_anual_estimado,pas_roi_porcentaje" -Headers $h
}

# 1. Buscar empresa con codigo
$empresas = Invoke-RestMethod -Uri "$apiBase/pas_empresas?`$filter=pas_codigo_corto ne null&`$top=1&`$select=pas_empresaid,pas_codigo_corto" -Headers $h
$empresaId = $empresas.value[0].pas_empresaid

$fails = @()
$iniciativaId = $null

try {
    # 2. CREATE con monto + ahorro
    Write-Host "`n[1/3] CREATE con monto=1000, ahorro=1500 (esperado ROI=50)..." -ForegroundColor Yellow
    $createBody = @{
        pas_titulo = "ROI smoke $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        'pas_Empresa@odata.bind' = "/pas_empresas($empresaId)"
        'pas_monto_estimado@odata.type' = 'Microsoft.Dynamics.CRM.MoneyType'
        pas_monto_estimado = @{ Value = 1000 }
        pas_ahorro_anual_estimado = @{ Value = 1500 }
    } | ConvertTo-Json
    # Adjust JSON manually for OData Money serialization
    $createBody = @{
        pas_titulo = "ROI smoke $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        'pas_Empresa@odata.bind' = "/pas_empresas($empresaId)"
        pas_monto_estimado = 1000
        pas_ahorro_anual_estimado = 1500
    } | ConvertTo-Json

    $resp = Invoke-WebRequest -Uri "$apiBase/pas_iniciativas?`$select=pas_iniciativaid,pas_consecutivo,pas_monto_estimado,pas_ahorro_anual_estimado,pas_roi_porcentaje" -Method POST -Headers $hReturn -Body $createBody
    $created = $resp.Content | ConvertFrom-Json
    $iniciativaId = $created.pas_iniciativaid
    Write-Host "  Iniciativa: $iniciativaId ($($created.pas_consecutivo))" -ForegroundColor DarkGray
    Write-Host "  monto=$($created.pas_monto_estimado)  ahorro=$($created.pas_ahorro_anual_estimado)  ROI=$($created.pas_roi_porcentaje)" -ForegroundColor White
    if ($created.pas_roi_porcentaje -ne 50) {
        $fails += "CREATE: ROI esperado 50, obtenido $($created.pas_roi_porcentaje)"
    } else {
        Write-Host "  OK: ROI=50 (correcto)" -ForegroundColor Green
    }

    # 3. UPDATE solo monto -> verifica PreImage de ahorro
    Write-Host "`n[2/3] UPDATE solo monto=500 (esperado ROI = (1500-500)/500*100 = 200)..." -ForegroundColor Yellow
    $updateBody1 = @{ pas_monto_estimado = 500 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($iniciativaId)" -Method PATCH -Headers $hWrite -Body $updateBody1 | Out-Null
    Start-Sleep -Milliseconds 200
    $afterUpdate1 = Get-RoiFields $iniciativaId
    Write-Host "  monto=$($afterUpdate1.pas_monto_estimado)  ahorro=$($afterUpdate1.pas_ahorro_anual_estimado)  ROI=$($afterUpdate1.pas_roi_porcentaje)" -ForegroundColor White
    if ($afterUpdate1.pas_roi_porcentaje -ne 200) {
        $fails += "UPDATE solo monto: ROI esperado 200, obtenido $($afterUpdate1.pas_roi_porcentaje)"
    } else {
        Write-Host "  OK: ROI=200 (PreImage funciono: ahorro=1500 desde preImage + monto=500 del target)" -ForegroundColor Green
    }

    # 4. UPDATE solo ahorro -> verifica PreImage de monto
    Write-Host "`n[3/3] UPDATE solo ahorro=2500 (esperado ROI = (2500-500)/500*100 = 400)..." -ForegroundColor Yellow
    $updateBody2 = @{ pas_ahorro_anual_estimado = 2500 } | ConvertTo-Json
    Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($iniciativaId)" -Method PATCH -Headers $hWrite -Body $updateBody2 | Out-Null
    Start-Sleep -Milliseconds 200
    $afterUpdate2 = Get-RoiFields $iniciativaId
    Write-Host "  monto=$($afterUpdate2.pas_monto_estimado)  ahorro=$($afterUpdate2.pas_ahorro_anual_estimado)  ROI=$($afterUpdate2.pas_roi_porcentaje)" -ForegroundColor White
    if ($afterUpdate2.pas_roi_porcentaje -ne 400) {
        $fails += "UPDATE solo ahorro: ROI esperado 400, obtenido $($afterUpdate2.pas_roi_porcentaje)"
    } else {
        Write-Host "  OK: ROI=400 (PreImage funciono: monto=500 desde preImage + ahorro=2500 del target)" -ForegroundColor Green
    }
}
finally {
    if ($iniciativaId -and -not $KeepRecord) {
        Write-Host "`n  Eliminando iniciativa de prueba..." -ForegroundColor DarkGray
        try {
            Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($iniciativaId)" -Method DELETE -Headers $h | Out-Null
        } catch {
            Write-Host "  WARN: no se pudo borrar ($_)" -ForegroundColor Yellow
        }
    }
}

if ($fails.Count -gt 0) {
    Write-Host "`n=== FAIL ===" -ForegroundColor Red
    $fails | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "`n=== Smoke ROI PASSED ===" -ForegroundColor Green
