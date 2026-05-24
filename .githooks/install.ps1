<#
.SYNOPSIS
    Configura git para usar .githooks/ como ruta de hooks de este repo.

.DESCRIPTION
    Setup one-time. Despues de clonar el repo, ejecutar:
        pwsh -File .githooks/install.ps1

    Esto hace `git config core.hooksPath .githooks` (scope local del repo,
    no afecta otros repos).

    Tambien marca pre-commit como ejecutable cuando aplique (Linux/Mac).
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) {
    Write-Host "ERROR: no estas dentro de un repo git." -ForegroundColor Red
    exit 1
}
Set-Location $repoRoot

Write-Host "Configurando core.hooksPath = .githooks..." -ForegroundColor Cyan
& git config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
    Write-Host "FALLO al configurar git config" -ForegroundColor Red
    exit 1
}

# En Linux/Mac asegurar el bit ejecutable. En Windows no aplica (Git Bash lo invoca igual).
if ($IsLinux -or $IsMacOS) {
    chmod +x .githooks/pre-commit
    Write-Host "  Permisos de ejecucion aplicados a .githooks/pre-commit" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "OK. Hooks instalados." -ForegroundColor Green
Write-Host "Verificar con: git config core.hooksPath" -ForegroundColor DarkGray
Write-Host "Probar con:    pwsh -File scripts/validate/run-validators.ps1 -AllFiles" -ForegroundColor DarkGray
