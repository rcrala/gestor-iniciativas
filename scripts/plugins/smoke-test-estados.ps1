#Requires -Version 7.0
<#
.SYNOPSIS
    Smoke E2E del plug-in IniciativaEstadoTransitionPlugin.
    Valida 6 escenarios:
      1. CREATE sin estado -> OK (default Borrador)
      2. CREATE con estado=Aprobada -> BLOCK
      3. UPDATE Borrador -> Revision PMO -> OK
      4. UPDATE Revision PMO -> Aprobada -> BLOCK (salto invalido)
      5. UPDATE Revision PMO -> Cancelada -> OK (escape admin)
      6. UPDATE Cancelada -> Borrador -> BLOCK (terminal)
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

Write-Host "`n=== Smoke test: IniciativaEstadoTransitionPlugin en $($Environment.ToUpper()) ===" -ForegroundColor Cyan

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

# Empresa para crear iniciativas
$emp = Invoke-RestMethod -Uri "$apiBase/pas_empresas?`$filter=pas_codigo_corto ne null&`$top=1&`$select=pas_empresaid" -Headers $h
$empresaId = $emp.value[0].pas_empresaid

$fails = @()
$created = @()

function Try-Action {
    param(
        [string]$Label,
        [scriptblock]$Action,
        [bool]$ExpectFail
    )
    Write-Host ""
    Write-Host "  [$Label]" -ForegroundColor Yellow
    try {
        $r = & $Action
        if ($ExpectFail) {
            Write-Host "    EXPECTED BLOCK but PASSED!" -ForegroundColor Red
            $script:fails += $Label
        } else {
            Write-Host "    OK" -ForegroundColor Green
        }
        return $r
    } catch {
        if ($ExpectFail) {
            $msg = if ($_.ErrorDetails.Message) { ($_.ErrorDetails.Message | ConvertFrom-Json).error.message } else { $_.Exception.Message }
            $short = if ($msg.Length -gt 200) { $msg.Substring(0,200) + '...' } else { $msg }
            Write-Host "    BLOCKED OK -> $short" -ForegroundColor Green
        } else {
            Write-Host "    EXPECTED OK but FAILED: $($_.Exception.Message)" -ForegroundColor Red
            $script:fails += $Label
        }
        return $null
    }
}

try {
    # 1. CREATE sin estado -> OK (default Borrador)
    $r1 = Try-Action -Label "CREATE sin estado (default Borrador)" -ExpectFail $false -Action {
        $body = @{
            pas_titulo = "ESTADO smoke 1 $(Get-Date -Format 'HH:mm:ss')"
            'pas_Empresa@odata.bind' = "/pas_empresas($empresaId)"
        } | ConvertTo-Json
        $resp = Invoke-WebRequest -Uri "$apiBase/pas_iniciativas?`$select=pas_iniciativaid,pas_estado" -Method POST -Headers ($hWrite + @{ Prefer = 'return=representation' }) -Body $body
        $resp.Content | ConvertFrom-Json
    }
    if ($r1) { $created += $r1.pas_iniciativaid; Write-Host "    iniciativa creada con estado=$($r1.pas_estado)" -ForegroundColor DarkGray }

    # 2. CREATE con estado=Aprobada -> BLOCK
    Try-Action -Label "CREATE estado=Aprobada (debe ser BLOCK)" -ExpectFail $true -Action {
        $body = @{
            pas_titulo = "ESTADO smoke 2"
            'pas_Empresa@odata.bind' = "/pas_empresas($empresaId)"
            pas_estado = 100000014  # Aprobada
        } | ConvertTo-Json
        Invoke-RestMethod -Uri "$apiBase/pas_iniciativas" -Method POST -Headers $hWrite -Body $body
    } | Out-Null

    # 3. UPDATE Borrador -> Revision PMO (OK)
    if ($r1) {
        Try-Action -Label "UPDATE Borrador -> Revision PMO (OK)" -ExpectFail $false -Action {
            $body = @{ pas_estado = 100000001 } | ConvertTo-Json  # Revision PMO
            Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($($r1.pas_iniciativaid))" -Method PATCH -Headers $hWrite -Body $body
        } | Out-Null
    }

    # 4. UPDATE Revision PMO -> Aprobada (BLOCK)
    if ($r1) {
        Try-Action -Label "UPDATE Revision PMO -> Aprobada (debe ser BLOCK - salto invalido)" -ExpectFail $true -Action {
            $body = @{ pas_estado = 100000014 } | ConvertTo-Json
            Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($($r1.pas_iniciativaid))" -Method PATCH -Headers $hWrite -Body $body
        } | Out-Null
    }

    # 5. UPDATE Revision PMO -> Cancelada (OK escape)
    if ($r1) {
        Try-Action -Label "UPDATE Revision PMO -> Cancelada (OK escape admin)" -ExpectFail $false -Action {
            $body = @{ pas_estado = 100000016 } | ConvertTo-Json
            Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($($r1.pas_iniciativaid))" -Method PATCH -Headers $hWrite -Body $body
        } | Out-Null
    }

    # 6. UPDATE Cancelada -> Borrador (BLOCK - terminal)
    if ($r1) {
        Try-Action -Label "UPDATE Cancelada -> Borrador (debe ser BLOCK - terminal)" -ExpectFail $true -Action {
            $body = @{ pas_estado = 100000000 } | ConvertTo-Json
            Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($($r1.pas_iniciativaid))" -Method PATCH -Headers $hWrite -Body $body
        } | Out-Null
    }
}
finally {
    foreach ($id in $created) {
        try { Invoke-RestMethod -Uri "$apiBase/pas_iniciativas($id)" -Method DELETE -Headers $h | Out-Null } catch {}
    }
    Write-Host "`n  Limpieza: $($created.Count) iniciativa(s) eliminada(s)" -ForegroundColor DarkGray
}

if ($fails.Count -gt 0) {
    Write-Host "`n=== FAIL ===" -ForegroundColor Red
    $fails | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "`n=== Smoke ESTADOS PASSED (6/6) ===" -ForegroundColor Green
