<#
.SYNOPSIS
    Orquestador de validaciones para INNOVA. Llamado por el pre-commit hook y por CI.

.DESCRIPTION
    Ejecuta 4 validadores sobre los archivos indicados:
      1. PowerShell syntax (parser sin ejecutar)
      2. JSON validity
      3. Secret detection (regex)
      4. Naming conventions (pas_ prefix, no TODOs sin issue)

    Modo de uso:
      - Pre-commit hook: pasa lista de archivos staged via -StagedFiles
      - CI: sin -StagedFiles, valida TODOS los archivos relevantes del repo
      - Local debug: --AllFiles para escanear todo

.PARAMETER StagedFiles
    Lista de paths separados por newline (output de `git diff --cached --name-only`).
    Si no se especifica, valida todos los archivos relevantes.

.PARAMETER AllFiles
    Forzar validacion de todos los archivos, ignorando StagedFiles.

.PARAMETER Verbose
    Output detallado por archivo.

.EXAMPLE
    pwsh -File scripts/validate/run-validators.ps1
    # Valida TODO el repo (uso CI)

.EXAMPLE
    pwsh -File scripts/validate/run-validators.ps1 -StagedFiles "scripts/setup/03-create-tables.ps1`ndocs/glossary.md"
    # Valida solo los 2 archivos indicados (uso pre-commit)
#>
[CmdletBinding()]
param(
    [string]$StagedFiles = '',
    [switch]$AllFiles
)

$ErrorActionPreference = 'Stop'
$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) {
    Write-Host "ERROR: no se detecto un repo git. Ejecutar dentro de la copia local." -ForegroundColor Red
    exit 1
}
Set-Location $repoRoot

# ==============================================================================
# Determinar conjunto de archivos a validar
# ==============================================================================

$filesToValidate = @()
if ($AllFiles -or [string]::IsNullOrWhiteSpace($StagedFiles)) {
    # Modo CI / debug: todos los archivos versionados relevantes
    $filesToValidate = & git ls-files -- '*.ps1' '*.psm1' '*.json' '*.md' '*.yml' '*.yaml'
    Write-Host "Modo: full scan ($($filesToValidate.Count) archivos)" -ForegroundColor DarkGray
} else {
    # Modo pre-commit: solo los staged que sean relevantes
    $filesToValidate = $StagedFiles -split "`n" |
        Where-Object { $_ -match '\.(ps1|psm1|json|md|ya?ml)$' } |
        Where-Object { Test-Path $_ }   # filtra renames/deletes
    Write-Host "Modo: pre-commit ($($filesToValidate.Count) archivos staged relevantes)" -ForegroundColor DarkGray
}

if ($filesToValidate.Count -eq 0) {
    Write-Host "Nada que validar. OK." -ForegroundColor Green
    exit 0
}

$issues = @()
function Add-Issue {
    param([string]$Severity, [string]$File, [string]$Message, [int]$Line = 0)
    $script:issues += [pscustomobject]@{
        Severity = $Severity
        File     = $File
        Line     = $Line
        Message  = $Message
    }
}

# ==============================================================================
# Validador 1: PowerShell syntax
# ==============================================================================

function Test-PowerShellSyntax {
    param([string[]]$Files)
    $psFiles = $Files | Where-Object { $_ -match '\.(ps1|psm1)$' }
    if ($psFiles.Count -eq 0) { return }
    Write-Host "[1/4] PowerShell syntax ($($psFiles.Count) archivos)..." -ForegroundColor Cyan
    foreach ($f in $psFiles) {
        try {
            $content = Get-Content -Raw -Path $f -ErrorAction Stop
            $tokens = $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                foreach ($e in $errors) {
                    Add-Issue -Severity 'ERROR' -File $f -Line $e.Extent.StartLineNumber -Message "Sintaxis PS: $($e.Message)"
                }
            }
        } catch {
            Add-Issue -Severity 'ERROR' -File $f -Message "No se pudo parsear: $($_.Exception.Message)"
        }
    }
}

# ==============================================================================
# Validador 2: JSON validity
# ==============================================================================

function Test-JsonValid {
    param([string[]]$Files)
    $jsonFiles = $Files | Where-Object { $_ -match '\.json$' }
    if ($jsonFiles.Count -eq 0) { return }
    Write-Host "[2/4] JSON validity ($($jsonFiles.Count) archivos)..." -ForegroundColor Cyan
    foreach ($f in $jsonFiles) {
        try {
            # Usar -AsHashtable para tolerar JSONs con property names vacios (validos pero
            # no soportados por el converter default). Ejemplo: package-lock.json de npm.
            $null = Get-Content -Raw -Path $f -ErrorAction Stop | ConvertFrom-Json -AsHashtable -ErrorAction Stop
        } catch {
            Add-Issue -Severity 'ERROR' -File $f -Message "JSON invalido: $($_.Exception.Message)"
        }
    }
}

# ==============================================================================
# Validador 3: Secret detection
# ==============================================================================

function Test-NoSecrets {
    param([string[]]$Files)
    # Excluir el propio validador (los patterns regex de abajo matchean su propio codigo)
    $codeFiles = $Files |
        Where-Object { $_ -match '\.(ps1|psm1|json|md|ya?ml|cs|ts|tsx|js)$' } |
        Where-Object { $_ -notmatch 'scripts[\\/]validate[\\/]run-validators\.ps1$' }
    if ($codeFiles.Count -eq 0) { return }
    Write-Host "[3/4] Secret detection ($($codeFiles.Count) archivos)..." -ForegroundColor Cyan

    # Patrones (cada uno emparejado con una whitelist de placeholders comunes)
    $secretPatterns = @(
        @{ Name = 'AppRegistration secret-like'; Pattern = '(?i)(client[_-]?secret|app[_-]?secret|api[_-]?key)\s*[:=]\s*["'']([^"''\s]{20,})["'']' }
        @{ Name = 'SQL connection string';       Pattern = '(?i)(Server|Data Source)\s*=\s*[^;]+;\s*(Password|Pwd)\s*=\s*[^;]+' }
        @{ Name = 'BEGIN PRIVATE KEY';           Pattern = '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----' }
        @{ Name = 'Azure SAS token';             Pattern = 'sv=\d{4}-\d{2}-\d{2}&[^"''\s]*sig=[A-Za-z0-9+/=]{16,}' }
        @{ Name = 'GitHub PAT';                  Pattern = 'ghp_[A-Za-z0-9]{36}' }
    )
    $placeholderWhitelist = @(
        '\*{3,}',          # *** placeholders
        'REPLACE[_-]?ME',
        'YOUR[_-]?',
        'EXAMPLE[_-]?',
        'PLACEHOLDER',
        '<.+>',            # <secret>, <your-key>
        '\$\{.+\}',        # ${var}
        'x{4,}'            # xxxxx tokens
    ) -join '|'

    foreach ($f in $codeFiles) {
        $lineNum = 0
        Get-Content -Path $f -ErrorAction SilentlyContinue | ForEach-Object {
            $lineNum++
            $line = $_
            if ($line -match $placeholderWhitelist) { return }
            foreach ($p in $secretPatterns) {
                if ($line -match $p.Pattern) {
                    Add-Issue -Severity 'ERROR' -File $f -Line $lineNum -Message "Posible secreto: $($p.Name) -> $($line.Substring(0, [Math]::Min(80, $line.Length)))..."
                }
            }
        }
    }
}

# ==============================================================================
# Validador 4: Naming conventions y misc
# ==============================================================================

function Test-Conventions {
    param([string[]]$Files)
    Write-Host "[4/4] Conventions ($($Files.Count) archivos)..." -ForegroundColor Cyan

    # 4a: archivos en scripts/setup deben requerir lib/dataverse.ps1 (consistencia)
    $setupScripts = $Files | Where-Object {
        $_ -match '^scripts[\\/]setup[\\/]\d+-.*\.ps1$' -and
        $_ -notmatch 'scripts[\\/]setup[\\/]lib[\\/]'
    }
    foreach ($f in $setupScripts) {
        $content = Get-Content -Raw -Path $f -ErrorAction SilentlyContinue
        if ($content -and ($content -notmatch '\. .+lib[\\/]dataverse\.ps1') ) {
            Add-Issue -Severity 'WARN' -File $f -Message "Script de setup no carga lib/dataverse.ps1. Si no usa Web API es ok; si usa, agregar '. `$PSScriptRoot\lib\dataverse.ps1' al inicio"
        }
    }

    # 4b: TODOs en CODIGO (no docs) sin numero de issue. Docs tienen checklists y roadmaps legitimos
    foreach ($f in $Files) {
        if ($f -notmatch '\.(ps1|psm1|cs|ts|tsx|js)$') { continue }
        $lineNum = 0
        Get-Content -Path $f -ErrorAction SilentlyContinue | ForEach-Object {
            $lineNum++
            if ($_ -match '\b(TODO|FIXME|XXX|HACK)\b' -and $_ -notmatch '#\d+') {
                Add-Issue -Severity 'WARN' -File $f -Line $lineNum -Message "TODO/FIXME/HACK sin numero de issue (#nnn). Linkear al backlog o eliminar"
            }
        }
    }

    # 4c: schema names Dataverse en SCRIPTS .ps1 (no docs, que tienen tanto Schema PascalCase como Logical snake_case).
    # En LogicalName se usa lowercase snake_case (pas_nombre_corto). camelCase tras pas_ en assignment es smell.
    # IMPORTANTE: limitar el match al contenido entre comillas para evitar over-match contra el siguiente -Param.
    foreach ($f in $Files) {
        if ($f -notmatch 'scripts[\\/].+\.(ps1|psm1)$') { continue }
        if ($f -match 'scripts[\\/]validate[\\/]') { continue }
        $lineNum = 0
        Get-Content -Path $f -ErrorAction SilentlyContinue | ForEach-Object {
            $lineNum++
            $line = $_
            # Match: -Name '...' o -Name "..." donde el contenido tiene camelCase tras pas_.
            # Importante: -cmatch (case-sensitive) — el default -match es case-INsensitive y arruinaria [A-Z].
            if ($line -cmatch "-Name\s+(['""])(pas_[a-z][a-z0-9_]*[A-Z][a-zA-Z0-9_]*)\1") {
                Add-Issue -Severity 'WARN' -File $f -Line $lineNum -Message "Posible LogicalName camelCase en -Name '$($matches[2])'. Convencion: pas_lower_snake_case"
            }
        }
    }

    # 4d: archivos sensibles que NUNCA deben estar en el repo
    $forbiddenPatterns = @('\.pfx$', '\.pem$', '\.key$', 'appsettings\.local\.json$', '\.env$', '\.env\.local$')
    foreach ($f in $Files) {
        foreach ($pat in $forbiddenPatterns) {
            if ($f -match $pat) {
                Add-Issue -Severity 'ERROR' -File $f -Message "Archivo sensible no debe commitearse. Agregar a .gitignore y revocar si ya esta en historia"
            }
        }
    }
}

# ==============================================================================
# Ejecucion + reporte
# ==============================================================================

Test-PowerShellSyntax -Files $filesToValidate
Test-JsonValid        -Files $filesToValidate
Test-NoSecrets        -Files $filesToValidate
Test-Conventions      -Files $filesToValidate

Write-Host ""
$errors = @($issues | Where-Object { $_.Severity -eq 'ERROR' })
$warns  = @($issues | Where-Object { $_.Severity -eq 'WARN' })

if ($issues.Count -eq 0) {
    Write-Host "=== OK: sin issues ===" -ForegroundColor Green
    exit 0
}

Write-Host "=== Reporte ===" -ForegroundColor Cyan
foreach ($i in $issues) {
    $color = if ($i.Severity -eq 'ERROR') { 'Red' } else { 'Yellow' }
    $loc = if ($i.Line -gt 0) { "$($i.File):$($i.Line)" } else { $i.File }
    Write-Host ("[{0}] {1}" -f $i.Severity, $loc) -ForegroundColor $color
    Write-Host ("    {0}" -f $i.Message) -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "Errors: $($errors.Count)   Warnings: $($warns.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { 'Red' } else { 'Yellow' })

if ($errors.Count -gt 0) {
    Write-Host "=== FAIL ===" -ForegroundColor Red
    exit 1
}
Write-Host "=== OK (con warnings) ===" -ForegroundColor Yellow
exit 0
