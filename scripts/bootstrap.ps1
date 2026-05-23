#Requires -Version 7.0
<#
.SYNOPSIS
    Bootstrap del entorno de desarrollo INNOVA.
.DESCRIPTION
    Valida prerrequisitos, autentica contra Entra ID, configura PAC CLI
    contra los ambientes DEV/QA/PROD, e indica los plugins de Claude Code a instalar.
.EXAMPLE
    pwsh ./scripts/bootstrap.ps1
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n=== Bootstrap INNOVA ===" -ForegroundColor Cyan
Write-Host "Plataforma Corporativa de Iniciativas - Grupo Pasqui`n" -ForegroundColor Cyan

# === 1. Verificar prerrequisitos ===
Write-Host "[1/5] Verificando prerrequisitos..." -ForegroundColor Yellow

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

$prereqs = [ordered]@{
    'git'    = 'Git'
    'node'   = 'Node.js 20+'
    'dotnet' = '.NET 8 SDK'
    'pac'    = 'Power Platform CLI'
}

$missing = @()
foreach ($cmd in $prereqs.Keys) {
    if (Test-Command $cmd) {
        Write-Host "  [OK] $($prereqs[$cmd])" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $($prereqs[$cmd])" -ForegroundColor Red
        $missing += $prereqs[$cmd]
    }
}

if ($missing.Count -gt 0) {
    Write-Host "`nFaltan prerrequisitos: $($missing -join ', ')" -ForegroundColor Red
    Write-Host "Instala los faltantes y vuelve a ejecutar." -ForegroundColor Red
    exit 1
}

# === 2. Versión PAC ===
Write-Host "`n[2/5] Verificando version PAC CLI..." -ForegroundColor Yellow
$pacVersion = (& pac help 2>&1 | Select-String -Pattern '^Version:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value
if (-not $pacVersion) { $pacVersion = 'desconocida' }
Write-Host "  PAC CLI: $pacVersion"

# === 3. Autenticación ===
Write-Host "`n[3/5] Configurando autenticacion..." -ForegroundColor Yellow
Write-Host "  Se abrira una ventana del navegador para Entra ID."
Read-Host "  Presiona Enter para continuar"

$envs = @(
    @{ Name = 'innova-dev'; Url = 'https://org93905a7d.crm.dynamics.com/' }
    @{ Name = 'innova-qa';  Url = 'https://org8b65c4d6.crm.dynamics.com/' }
    # PROD aun no aprovisionado. Agregar cuando exista:
    # @{ Name = 'innova-prod'; Url = 'https://<org>.crm.dynamics.com/' }
)

foreach ($env in $envs) {
    Write-Host "  Autenticando contra $($env.Name)..." -ForegroundColor Cyan
    try {
        & pac auth create --name $env.Name --environment $env.Url
    } catch {
        Write-Host "  [WARN] No se pudo autenticar $($env.Name): $_" -ForegroundColor Yellow
    }
}

# === 4. Verificar acceso ===
Write-Host "`n[4/5] Verificando acceso a ambientes..." -ForegroundColor Yellow
& pac auth list

# === 5. Plugins de Claude Code ===
Write-Host "`n[5/5] Plugins de Claude Code recomendados:" -ForegroundColor Yellow
Write-Host "  Instalarlos manualmente:"
Write-Host "    claude plugin install canvas-apps@power-platform-skills"
Write-Host "    claude plugin install model-apps@power-platform-skills"
Write-Host "    claude plugin install code-apps@power-platform-skills"

Write-Host "`n=== Bootstrap completado ===" -ForegroundColor Green
Write-Host "Lee CLAUDE.md y docs/architecture/00-overview.md para comenzar.`n"
