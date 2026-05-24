<#
.SYNOPSIS
    Crea los 7 Security Roles de INNOVA con su matriz de privilegios.

.DESCRIPTION
    Implementa S0-3 (issue #14). Crea roles en innova_core con privilegios por
    tabla y por scope segun docs/architecture/security-roles.md.

    Idempotencia: si el rol existe, salta su creacion. La asignacion de privilegios
    es siempre aplicable (AddPrivilegesRole sobreescribe el depth si ya existe).

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER OnlyRole
    Opcional. Solo procesa el rol con ese nombre.

.PARAMETER SkipPrivileges
    Opcional. Solo crea los roles vacios, no asigna privilegios (debug).

.PARAMETER WhatIf
    Dry-run.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',
    [string]$OnlyRole,
    [switch]$SkipPrivileges
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\dataverse.ps1"

$Solution = 'innova_core'

Write-Host "`n=== INNOVA S0-3: Crear Security Roles en $($Environment.ToUpper()) ===" -ForegroundColor Cyan
Initialize-DataverseSession | Out-Null

# ==============================================================================
# Helpers de definicion compacta
# ==============================================================================

# Codifica un set de privilegios para una tabla en formato corto:
#   "CRWD:L Ap:L AT:L" = Create/Read/Write/Delete en Local, Append/AppendTo en Local
#   "R:G"              = Solo Read en Global
#   ""                 = Sin privilegios
function Parse-PrivilegeSpec {
    param(
        [Parameter(Mandatory)] [string]$EntityLogicalName,
        [Parameter(Mandatory)] [string]$Spec
    )
    $verbMap = @{ 'C' = 'Create'; 'R' = 'Read'; 'W' = 'Write'; 'D' = 'Delete'; 'Ap' = 'Append'; 'AT' = 'AppendTo'; 'As' = 'Assign'; 'S' = 'Share' }
    $depthMap = @{ 'B' = 'Basic'; 'L' = 'Local'; 'D' = 'Deep'; 'G' = 'Global' }

    $results = @()
    if ([string]::IsNullOrWhiteSpace($Spec)) { return $results }

    # Cada grupo: "<verbs>:<depth>"
    $groups = $Spec -split '\s+'
    foreach ($g in $groups) {
        if ([string]::IsNullOrWhiteSpace($g)) { continue }
        $parts = $g -split ':'
        if ($parts.Count -ne 2) { throw "Spec invalido '$g' (formato: verbs:depth)" }
        $verbsStr = $parts[0]
        $depthShort = $parts[1]
        if (-not $depthMap.ContainsKey($depthShort)) { throw "Depth desconocido '$depthShort' en '$g'" }
        $depth = $depthMap[$depthShort]

        # Parsear verbs: pueden ser combinaciones como "CRWD" o multi-letra "Ap", "AT", "As"
        $i = 0
        while ($i -lt $verbsStr.Length) {
            $two = $null; $one = $verbsStr.Substring($i,1)
            if ($i + 1 -lt $verbsStr.Length) { $two = $verbsStr.Substring($i,2) }
            $matched = $false
            if ($two -and $verbMap.ContainsKey($two)) {
                $verb = $verbMap[$two]
                $i += 2; $matched = $true
            } elseif ($verbMap.ContainsKey($one)) {
                $verb = $verbMap[$one]
                $i += 1; $matched = $true
            }
            if (-not $matched) { throw "Verb desconocido en posicion $i de '$verbsStr'" }
            $results += @{ Name = "prv${verb}${EntityLogicalName}"; Depth = $depth }
        }
    }
    return $results
}

# Convierte la matriz definida abajo en un array plano de privilegios para un rol
function Get-RolePrivileges {
    param($RoleMatrix)
    $all = @()
    foreach ($entity in $RoleMatrix.Keys) {
        $spec = $RoleMatrix[$entity]
        $all += Parse-PrivilegeSpec -EntityLogicalName $entity -Spec $spec
    }
    return $all
}

# ==============================================================================
# Definiciones (matriz consolidada de security-roles.md)
# ==============================================================================

$roles = @(
    @{
        Name = 'INNOVA Solicitante'
        Description = 'Crea iniciativas, sube documentos, hace tracking de sus solicitudes (M12)'
        Matrix = [ordered]@{
            'pas_iniciativa'      = 'CRW:B Ap:B AT:B As:B S:B'
            'pas_evaluacionpmo'   = 'R:L'
            'pas_evaluacionti'    = 'R:L'
            'pas_cotizacion'      = 'R:L'
            'pas_horatrabajo'     = 'R:L'
            'pas_votocomite'      = 'R:L'
            'pas_documentoadj'    = 'CRW:B Ap:B'
            'pas_empresa'         = 'R:G'
            'pas_centrocosto'     = 'R:G'
            'pas_parametro'       = 'R:G'
        }
    }
    @{
        Name = 'INNOVA PMO'
        Description = 'Recibe iniciativas, hace levantamiento, ejecucion y cotizaciones (BU-scoped)'
        Matrix = [ordered]@{
            'pas_iniciativa'      = 'RW:L Ap:L AT:L'
            'pas_evaluacionpmo'   = 'CRWD:L Ap:L AT:L'
            'pas_evaluacionti'    = 'R:L'
            'pas_cotizacion'      = 'CRWD:L Ap:L AT:L'
            'pas_horatrabajo'     = 'CRW:L Ap:L'
            'pas_votocomite'      = 'R:L'
            'pas_documentoadj'    = 'CRW:L Ap:L'
            'pas_empresa'         = 'R:G'
            'pas_centrocosto'     = 'R:G'
            'pas_plantillacorreo' = 'R:G'
            'pas_parametro'       = 'R:G'
            'pas_miembrocomite'   = 'R:G'
        }
    }
    @{
        Name = 'INNOVA TI'
        Description = 'Estima desarrollo cuando aplica (Organization-scoped, cross-BU)'
        Matrix = [ordered]@{
            'pas_iniciativa'      = 'RW:G Ap:G AT:G'
            'pas_evaluacionpmo'   = 'R:G'
            'pas_evaluacionti'    = 'CRWD:G Ap:G AT:G'
            'pas_cotizacion'      = 'R:G'
            'pas_horatrabajo'     = 'CRW:G Ap:G'
            'pas_votocomite'      = 'R:G'
            'pas_documentoadj'    = 'R:G'
            'pas_empresa'         = 'R:G'
            'pas_centrocosto'     = 'R:G'
            'pas_parametro'       = 'R:G'
        }
    }
    @{
        Name = 'INNOVA Jefatura'
        Description = 'Aprueba estimaciones y valida ejecucion en su BU (M5, M7)'
        Matrix = [ordered]@{
            'pas_iniciativa'      = 'RW:L Ap:L AT:L'
            'pas_evaluacionpmo'   = 'R:L'
            'pas_evaluacionti'    = 'R:L'
            'pas_cotizacion'      = 'R:L'
            'pas_horatrabajo'     = 'R:L'
            'pas_votocomite'      = 'R:L'
            'pas_documentoadj'    = 'R:L'
            'pas_empresa'         = 'R:G'
            'pas_centrocosto'     = 'R:G'
            'pas_parametro'       = 'R:G'
        }
    }
    @{
        Name = 'INNOVA Gerencia'
        Description = 'Aprueba iniciativas bajo el umbral de escalamiento en su BU (M9)'
        Matrix = [ordered]@{
            'pas_iniciativa'      = 'RW:L Ap:L AT:L'
            'pas_evaluacionpmo'   = 'R:L'
            'pas_evaluacionti'    = 'R:L'
            'pas_cotizacion'      = 'R:L'
            'pas_horatrabajo'     = 'R:L'
            'pas_votocomite'      = 'R:L'
            'pas_documentoadj'    = 'R:L'
            'pas_empresa'         = 'R:G'
            'pas_centrocosto'     = 'R:G'
            'pas_parametro'       = 'R:G'
        }
    }
    @{
        Name = 'INNOVA Comite'
        Description = 'Vota en iniciativas escaladas (M10, cross-BU)'
        Matrix = [ordered]@{
            'pas_iniciativa'      = 'R:G'
            'pas_evaluacionpmo'   = 'R:G'
            'pas_evaluacionti'    = 'R:G'
            'pas_cotizacion'      = 'R:G'
            'pas_horatrabajo'     = 'R:G'
            'pas_votocomite'      = 'CRW:G Ap:G'
            'pas_documentoadj'    = 'R:G'
            'pas_empresa'         = 'R:G'
            'pas_centrocosto'     = 'R:G'
            'pas_parametro'       = 'R:G'
            'pas_miembrocomite'   = 'R:G'
        }
    }
    @{
        Name = 'INNOVA Administrador'
        Description = 'Gestiona catalogos (M11), monitorea sistema, soporte L1. NO reemplaza System Administrator'
        Matrix = [ordered]@{
            'pas_iniciativa'      = 'R:G'
            'pas_evaluacionpmo'   = 'R:G'
            'pas_evaluacionti'    = 'R:G'
            'pas_cotizacion'      = 'R:G'
            'pas_horatrabajo'     = 'R:G'
            'pas_votocomite'      = 'R:G'
            'pas_documentoadj'    = 'R:G'
            'pas_empresa'         = 'CRWD:G Ap:G AT:G'
            'pas_centrocosto'     = 'CRWD:G Ap:G AT:G'
            'pas_plantillacorreo' = 'CRWD:G Ap:G AT:G'
            'pas_parametro'       = 'CRWD:G Ap:G AT:G'
            'pas_miembrocomite'   = 'CRWD:G Ap:G AT:G'
        }
    }
)

if ($OnlyRole) {
    $roles = $roles | Where-Object { $_.Name -eq $OnlyRole }
    if (-not $roles) { throw "Rol '$OnlyRole' no esta definido" }
}

# ==============================================================================
# Ejecucion
# ==============================================================================

$rootBU = Get-DataverseRootBusinessUnit -Environment $Environment
Write-Host "Root BU: $($rootBU.name) ($($rootBU.businessunitid))" -ForegroundColor DarkGray

$roleStats = @{ Created = 0; Skipped = 0; Failed = 0 }
$privStats = @{ Applied = 0; Failed = 0 }

foreach ($r in $roles) {
    Write-Host "`n--- $($r.Name) ---" -ForegroundColor Cyan

    # 1) Crear o recuperar rol
    $existing = Get-DataverseRole -Environment $Environment -Name $r.Name
    if ($existing) {
        Write-Host "  Rol ya existe (id: $($existing.roleid))" -ForegroundColor DarkYellow
        $roleStats.Skipped++
        $roleId = $existing.roleid
    } else {
        $body = @{
            name = $r.Name
            description = $r.Description
            'businessunitid@odata.bind' = "/businessunits($($rootBU.businessunitid))"
        }
        if ($PSCmdlet.ShouldProcess($r.Name, "Create Security Role")) {
            try {
                $new = Invoke-DataverseApi -Environment $Environment -Method POST -Path 'roles' -Body $body -PreferReturn -SolutionUniqueName $Solution
                Write-Host "  [OK] Rol creado (id: $($new.roleid))" -ForegroundColor Green
                $roleStats.Created++
                $roleId = $new.roleid
            } catch {
                Write-Host "  [FAIL] Crear rol: $($_.Exception.Message)" -ForegroundColor Red
                $roleStats.Failed++
                continue
            }
        } else {
            Write-Host "  [WHATIF] crearia rol $($r.Name)" -ForegroundColor Magenta
            $roleStats.Created++
            continue
        }
    }

    # 2) Aplicar privilegios
    if ($SkipPrivileges) {
        Write-Host "  (skip privileges por -SkipPrivileges)" -ForegroundColor DarkGray
        continue
    }

    $privileges = Get-RolePrivileges -RoleMatrix $r.Matrix
    Write-Host "  Aplicando $($privileges.Count) privilegios..." -ForegroundColor DarkGray
    if ($PSCmdlet.ShouldProcess($r.Name, "Apply $($privileges.Count) privileges")) {
        try {
            Add-DataverseRolePrivileges -Environment $Environment -RoleId $roleId -Privileges $privileges
            Write-Host "  [OK] $($privileges.Count) privilegios aplicados" -ForegroundColor Green
            $privStats.Applied += $privileges.Count
        } catch {
            Write-Host "  [FAIL] Privilegios: $($_.Exception.Message)" -ForegroundColor Red
            $privStats.Failed++
        }
    } else {
        Write-Host "  [WHATIF] aplicaria $($privileges.Count) privilegios" -ForegroundColor Magenta
    }
}

Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
Write-Host "Roles:       Created=$($roleStats.Created) Skipped=$($roleStats.Skipped) Failed=$($roleStats.Failed)"
Write-Host "Privilegios: Applied=$($privStats.Applied) Failed=$($privStats.Failed)"
if ($roleStats.Failed -gt 0 -or $privStats.Failed -gt 0) {
    Write-Host "=== HUBO FALLAS ===" -ForegroundColor Red
    exit 1
}
Write-Host "=== OK ===`n" -ForegroundColor Green
