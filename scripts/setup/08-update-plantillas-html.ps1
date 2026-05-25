#Requires -Version 7.0
<#
.SYNOPSIS
    Sincroniza el campo pas_cuerpo_html de las plantillas en pas_plantillacorreo
    desde los archivos .html versionados en scripts/seed-data/plantillas-correo/.

.DESCRIPTION
    Idempotente: si el cuerpo en DEV es identico al del archivo, salta.
    Si el archivo no existe en disco para una clave seedeada, skip con WARN.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER WhatIf
    Modo dry-run: imprime que plantillas se actualizarian sin tocar nada.

.EXAMPLE
    pwsh ./scripts/setup/08-update-plantillas-html.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$plantillasDir = Join-Path $repoRoot 'scripts/seed-data/plantillas-correo'
if (-not (Test-Path $plantillasDir)) {
    throw "Directorio de plantillas no existe: $plantillasDir"
}

$envFile = Join-Path $repoRoot ".env.$Environment"
$envVars = @{}
Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

Write-Host "`n=== INNOVA: Sync plantillas HTML -> pas_plantillacorreo ($($Environment.ToUpper())) ===" -ForegroundColor Cyan
Write-Host "  Fuente: $plantillasDir" -ForegroundColor DarkGray

# Token
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

# Plantillas existentes
$existing = Invoke-RestMethod -Uri "$apiBase/pas_plantillacorreos?`$select=pas_plantillacorreoid,pas_nombre_clave,pas_cuerpo_html" -Headers $h
$existingByKey = @{}
foreach ($r in $existing.value) { $existingByKey[$r.pas_nombre_clave] = $r }

Write-Host "  Plantillas en DEV: $($existing.value.Count)" -ForegroundColor DarkGray

# Archivos HTML
$htmlFiles = Get-ChildItem -Path $plantillasDir -Filter '*.html' -File
Write-Host "  Archivos .html en repo: $($htmlFiles.Count)" -ForegroundColor DarkGray

$stats = @{ Updated=0; Skipped=0; Missing=0 }

foreach ($file in $htmlFiles) {
    $clave = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $content = Get-Content $file.FullName -Raw

    if (-not $existingByKey.ContainsKey($clave)) {
        Write-Host "`n  [MISSING] $clave : no existe en pas_plantillacorreo. Saltado." -ForegroundColor Yellow
        $stats.Missing++
        continue
    }

    $record = $existingByKey[$clave]
    if ($record.pas_cuerpo_html -eq $content) {
        Write-Host "`n  [SKIP] $clave : cuerpo identico ($($content.Length) chars)" -ForegroundColor DarkGray
        $stats.Skipped++
        continue
    }

    Write-Host "`n  [UPDATE] $clave : $($record.pas_cuerpo_html.Length) -> $($content.Length) chars"
    if ($PSCmdlet.ShouldProcess($clave, 'PATCH pas_cuerpo_html')) {
        $body = @{ pas_cuerpo_html = $content } | ConvertTo-Json
        Invoke-RestMethod -Uri "$apiBase/pas_plantillacorreos($($record.pas_plantillacorreoid))" -Method PATCH -Headers $hWrite -Body $body | Out-Null
    }
    $stats.Updated++
}

Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
Write-Host ("  Updated:  {0}" -f $stats.Updated) -ForegroundColor Green
Write-Host ("  Skipped:  {0} (cuerpo identico)" -f $stats.Skipped) -ForegroundColor DarkGray
if ($stats.Missing -gt 0) {
    Write-Host ("  Missing:  {0} (clave en repo pero no en DEV - revisar seed)" -f $stats.Missing) -ForegroundColor Yellow
}
