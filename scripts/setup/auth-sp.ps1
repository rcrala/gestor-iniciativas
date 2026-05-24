#Requires -Version 7.0
<#
.SYNOPSIS
    Configura un perfil 'pac auth' usando el Service Principal de INNOVA.

.DESCRIPTION
    Implementa S0-5 (issue #16): autentica PAC CLI contra el environment indicado
    usando las credenciales del SP almacenadas localmente en .env.dev (o .env.qa).

    NO commitea ni imprime secretos. El client secret se lee del .env local
    (gitignored) y se pasa directamente a 'pac auth create'.

    Idempotente: si el perfil ya existe, lo recrea (--force = pac auth delete + create).

.PARAMETER Environment
    'dev' o 'qa'. Default: 'dev'. Determina que archivo .env<env> se lee y
    que perfil pac se crea ('innova-sp-dev' o 'innova-sp-qa').

.PARAMETER EnvFile
    Override del path al archivo .env. Default: ".env.<environment>" en la raiz del repo.

.PARAMETER WhatIf
    Modo dry-run: valida el .env y muestra que comando se ejecutaria, sin tocar pac auth.

.EXAMPLE
    pwsh ./scripts/setup/auth-sp.ps1
    Crea perfil 'innova-sp-dev' leyendo .env.dev.

.EXAMPLE
    pwsh ./scripts/setup/auth-sp.ps1 -Environment qa
    Crea perfil 'innova-sp-qa' leyendo .env.qa.

.EXAMPLE
    pwsh ./scripts/setup/auth-sp.ps1 -WhatIf
    Valida el .env.dev sin ejecutar pac auth create.

.NOTES
    Prerequisitos:
      - PAC CLI instalado y en PATH (pac --version)
      - Archivo .env.<env> creado a partir de .env.dev.template y rellenado
      - SP 'INNOVA-SP-<ENV>' creado en Entra ID + Application User en Power Platform
        (ver docs/runbooks/05-service-principal.md)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',

    [string]$EnvFile
)

$ErrorActionPreference = 'Stop'

# === 1. Resolver paths ===
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not $EnvFile) { $EnvFile = Join-Path $repoRoot ".env.$Environment" }

Write-Host "`n=== INNOVA S0-5: Configurar pac auth con SP ($($Environment.ToUpper())) ===" -ForegroundColor Cyan

# === 2. Validar pac CLI ===
$pacCmd = Get-Command pac -ErrorAction SilentlyContinue
if (-not $pacCmd) {
    throw "PAC CLI no encontrado en PATH. Instala con: dotnet tool install --global Microsoft.PowerApps.CLI.Tool"
}
Write-Host "  PAC CLI: $($pacCmd.Source)" -ForegroundColor DarkGray

# === 3. Validar y leer .env ===
if (-not (Test-Path $EnvFile)) {
    throw @"
No existe $EnvFile.
  1. Copy-Item $repoRoot\.env.$Environment.template $EnvFile
  2. Rellenar las 4 variables con los valores del SP
  3. Reintentar este script
"@
}

Write-Host "`n[1/3] Leyendo $EnvFile..." -ForegroundColor Yellow

$envVars = @{}
foreach ($line in Get-Content $EnvFile) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
    $idx = $trimmed.IndexOf('=')
    if ($idx -lt 1) { continue }
    $key = $trimmed.Substring(0, $idx).Trim()
    $val = $trimmed.Substring($idx + 1).Trim()
    $envVars[$key] = $val
}

$required = @('INNOVA_TENANT_ID', 'INNOVA_SP_CLIENT_ID', 'INNOVA_SP_CLIENT_SECRET', "INNOVA_$($Environment.ToUpper())_URL")
$missing = @()
foreach ($k in $required) {
    if (-not $envVars.ContainsKey($k) -or [string]::IsNullOrWhiteSpace($envVars[$k]) -or $envVars[$k] -like '<<*>>') {
        $missing += $k
    }
}
if ($missing.Count -gt 0) {
    throw "Variables faltantes o sin rellenar en ${EnvFile}: $($missing -join ', ')"
}

$tenantId = $envVars['INNOVA_TENANT_ID']
$clientId = $envVars['INNOVA_SP_CLIENT_ID']
$clientSecret = $envVars['INNOVA_SP_CLIENT_SECRET']
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"]

# Imprimir solo lo no-secreto
Write-Host "  Tenant:      $tenantId" -ForegroundColor DarkGray
Write-Host "  Client ID:   $clientId" -ForegroundColor DarkGray
Write-Host "  Env URL:     $envUrl" -ForegroundColor DarkGray
Write-Host "  Secret:      *** (longitud $($clientSecret.Length))" -ForegroundColor DarkGray

# === 4. Crear perfil pac ===
$profileName = "innova-sp-$Environment"

Write-Host "`n[2/3] Configurando perfil pac '$profileName'..." -ForegroundColor Yellow

if ($PSCmdlet.ShouldProcess($profileName, "pac auth create con SP")) {
    # Si existe, borrar primero (pac auth create con nombre existente falla)
    $existing = & pac auth list 2>&1 | Select-String -Pattern $profileName
    if ($existing) {
        Write-Host "  Perfil existe, recreando..." -ForegroundColor DarkGray
        & pac auth delete --name $profileName 2>&1 | Out-Null
    }

    & pac auth create `
        --name $profileName `
        --environment $envUrl `
        --tenant $tenantId `
        --applicationId $clientId `
        --clientSecret $clientSecret

    if ($LASTEXITCODE -ne 0) {
        throw "pac auth create fallo (exit code $LASTEXITCODE). Revisa que el SP tenga Application User en Power Platform."
    }

    & pac auth select --name $profileName | Out-Null
} else {
    Write-Host "  [WhatIf] No se ejecuto pac auth create" -ForegroundColor Yellow
}

# === 5. Validar acceso ===
Write-Host "`n[3/3] Validando acceso a $Environment con 'pac org who'..." -ForegroundColor Yellow

if ($PSCmdlet.ShouldProcess($envUrl, "pac org who")) {
    & pac org who
    if ($LASTEXITCODE -ne 0) {
        throw "pac org who fallo. El SP autentica pero no tiene acceso al environment. Verifica Application User + Security Role."
    }
}

Write-Host "`n=== Listo. Perfil '$profileName' activo y validado ===" -ForegroundColor Green
Write-Host "Cambiar entre perfiles: pac auth select --name <nombre>" -ForegroundColor DarkGray
Write-Host "Listar perfiles:        pac auth list" -ForegroundColor DarkGray
