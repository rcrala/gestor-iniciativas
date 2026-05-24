<#
.SYNOPSIS
    Crea las Business Units placeholder de INNOVA en el environment indicado.

.DESCRIPTION
    Implementa S0-2 (issue #13): crea 4 BUs hijas de la BU raiz del environment:
    - Empresa A
    - Empresa B
    - Empresa C
    - Comite

    Los nombres son placeholder. El cliente los renombra/agrega/quita despues via
    Power Platform Admin Center o via M11 cuando exista pas_empresa.

    Idempotente: si la BU ya existe, la salta.

.PARAMETER Environment
    'dev' o 'qa'. Default: 'dev'.

.PARAMETER WhatIf
    Modo dry-run: muestra que haria sin hacerlo.

.EXAMPLE
    pwsh ./scripts/setup/01-create-business-units.ps1
    Crea las 4 BUs en DEV.

.EXAMPLE
    pwsh ./scripts/setup/01-create-business-units.ps1 -Environment dev -WhatIf
    Dry-run en DEV.

.NOTES
    Prerequisitos: Az.Accounts instalado + Connect-AzAccount completo.
    Ver docs/setup-mcp.md para setup inicial.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev'
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\dataverse.ps1"

Write-Host "`n=== INNOVA S0-2: Crear Business Units en $($Environment.ToUpper()) ===" -ForegroundColor Cyan

# 1. Verificar sesion
Initialize-DataverseSession | Out-Null

# 2. Obtener BU raiz
Write-Host "`n[1/3] Buscando BU raiz..." -ForegroundColor Yellow
$rootBU = Get-DataverseRootBusinessUnit -Environment $Environment
Write-Host "  Root BU: '$($rootBU.name)' (id: $($rootBU.businessunitid))" -ForegroundColor DarkGray

# 3. Definir BUs a crear
$busToCreate = @(
    @{ Name = 'Empresa A'; Description = 'Placeholder - renombrar via Admin a la primera empresa real del Grupo' }
    @{ Name = 'Empresa B'; Description = 'Placeholder - renombrar via Admin a la segunda empresa real del Grupo' }
    @{ Name = 'Empresa C'; Description = 'Placeholder - renombrar via Admin a la tercera empresa real del Grupo' }
    @{ Name = 'Comite';    Description = 'BU transversal para miembros del Comite de Proyectos (ver ADR-0003)' }
)

# 4. Crear o saltar (idempotente)
Write-Host "`n[2/3] Procesando $($busToCreate.Count) BUs..." -ForegroundColor Yellow
$created = 0
$skipped = 0
$failed = 0

foreach ($bu in $busToCreate) {
    $existing = Get-DataverseBusinessUnit -Environment $Environment -Name $bu.Name
    if ($existing) {
        Write-Host "  [SKIP] '$($bu.Name)' ya existe (id: $($existing.businessunitid))" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    $body = @{
        name = $bu.Name
        description = $bu.Description
        'parentbusinessunitid@odata.bind' = "/businessunits($($rootBU.businessunitid))"
    }

    if ($PSCmdlet.ShouldProcess($bu.Name, "Create Business Unit")) {
        try {
            $newBU = Invoke-DataverseApi -Environment $Environment -Method POST -Path 'businessunits' -Body $body -PreferReturn
            Write-Host "  [OK]   '$($bu.Name)' creada (id: $($newBU.businessunitid))" -ForegroundColor Green
            $created++
        } catch {
            Write-Host "  [FAIL] '$($bu.Name)': $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host "  [WHATIF] Crearia '$($bu.Name)' bajo root BU" -ForegroundColor Magenta
    }
}

# 5. Resumen
Write-Host "`n[3/3] Resumen" -ForegroundColor Yellow
Write-Host "  Creadas: $created" -ForegroundColor Green
Write-Host "  Existentes (skip): $skipped" -ForegroundColor DarkYellow
Write-Host "  Fallidas: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'DarkGray' })

if ($failed -gt 0) {
    Write-Host "`n=== FALLO ===" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== OK ===`n" -ForegroundColor Green
