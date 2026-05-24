<#
.SYNOPSIS
    Crea las relaciones N:1 (lookups) entre las tablas de INNOVA.

.DESCRIPTION
    Implementa el cierre de S0-4 (issue #15). Crea OneToManyRelationshipMetadata via
    Web API. Cada relacion crea automaticamente un Lookup attribute en el lado N.

    Idempotente: skip si la relacion ya existe.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER OnlyRelationship
    Filtra a una sola relacion por SchemaName (debug iterativo).

.PARAMETER WhatIf
    Dry-run.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',
    [string]$OnlyRelationship
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\dataverse.ps1"

$Solution = 'innova_core'

Write-Host "`n=== INNOVA S0-4 (paso 3/3): Crear Relaciones N:1 en $($Environment.ToUpper()) ===" -ForegroundColor Cyan
Initialize-DataverseSession | Out-Null

# ==============================================================================
# Helpers
# ==============================================================================

function Get-DataverseRelationship {
    param(
        [Parameter(Mandatory)] [ValidateSet('dev','qa')] [string]$Environment,
        [Parameter(Mandatory)] [string]$SchemaName
    )
    try {
        return Invoke-DataverseApi -Environment $Environment -Method GET -Path "RelationshipDefinitions(SchemaName='$SchemaName')"
    } catch {
        $msg = $_.Exception.Message
        if ($msg -match '404' -or $msg -match 'does not exist' -or $msg -match 'Could not find') {
            return $null
        }
        throw
    }
}

function Build-OneToManyRelationship {
    param(
        [string]$SchemaName,
        [string]$ReferencingEntity,      # lado N (child, donde queda el lookup)
        [string]$ReferencedEntity,       # lado 1 (parent)
        [string]$LookupSchemaName,       # nombre del Lookup attribute (PascalCase con underscores)
        [string]$LookupLogicalName,      # nombre logical del Lookup (snake_case)
        [string]$LookupDisplay,          # display
        [string]$LookupDescription = '',
        [ValidateSet('None','Cascade','Active','UserOwned','Remove','Restrict','RemoveLink')]
        [string]$DeleteBehavior = 'RemoveLink'  # default seguro: solo limpia el lookup
    )
    $cascade = switch ($DeleteBehavior) {
        'Cascade'   { 'Cascade' }
        'Restrict'  { 'Restrict' }
        'RemoveLink' { 'RemoveLink' }
        default     { 'NoCascade' }
    }
    return @{
        '@odata.type'           = 'Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata'
        SchemaName              = $SchemaName
        ReferencedEntity        = $ReferencedEntity
        ReferencingEntity       = $ReferencingEntity
        AssociatedMenuConfiguration = @{
            Behavior = 'UseCollectionName'
            Group    = 'Details'
            Order    = 10000
            Label    = (New-LocalizedLabel -Text $LookupDisplay)
        }
        CascadeConfiguration   = @{
            Assign   = 'NoCascade'
            Delete   = $cascade
            Merge    = 'NoCascade'
            Reparent = 'NoCascade'
            Share    = 'NoCascade'
            Unshare  = 'NoCascade'
        }
        Lookup                  = @{
            '@odata.type'  = 'Microsoft.Dynamics.CRM.LookupAttributeMetadata'
            SchemaName     = $LookupSchemaName
            LogicalName    = $LookupLogicalName
            DisplayName    = (New-LocalizedLabel -Text $LookupDisplay)
            Description    = (New-LocalizedLabel -Text ($LookupDescription ? $LookupDescription : $LookupDisplay))
            RequiredLevel  = @{ Value = 'None'; CanBeChanged = $true; ManagedPropertyLogicalName = 'canmodifyrequirementlevelsettings' }
        }
    }
}

# ==============================================================================
# Definiciones de relaciones
# ==============================================================================

$relationships = @(
    # pas_iniciativa -> empresa, centrocosto, solicitante, patrocinador
    @{ SchemaName = 'pas_iniciativa_empresa';        ReferencingEntity = 'pas_iniciativa';     ReferencedEntity = 'pas_empresa';      LookupSchemaName = 'pas_Empresa';      LookupLogicalName = 'pas_empresa';      LookupDisplay = 'Empresa';                     DeleteBehavior = 'Restrict' }
    @{ SchemaName = 'pas_iniciativa_centrocosto';    ReferencingEntity = 'pas_iniciativa';     ReferencedEntity = 'pas_centrocosto';  LookupSchemaName = 'pas_CentroCosto';  LookupLogicalName = 'pas_centrocosto';  LookupDisplay = 'Centro de Costo';             DeleteBehavior = 'Restrict' }
    @{ SchemaName = 'pas_iniciativa_solicitante';    ReferencingEntity = 'pas_iniciativa';     ReferencedEntity = 'systemuser';       LookupSchemaName = 'pas_Solicitante';  LookupLogicalName = 'pas_solicitante';  LookupDisplay = 'Solicitante';                 DeleteBehavior = 'Restrict' }
    @{ SchemaName = 'pas_iniciativa_patrocinador';   ReferencingEntity = 'pas_iniciativa';     ReferencedEntity = 'systemuser';       LookupSchemaName = 'pas_Patrocinador'; LookupLogicalName = 'pas_patrocinador'; LookupDisplay = 'Patrocinador';                DeleteBehavior = 'RemoveLink' }
    # pas_evaluacionpmo
    @{ SchemaName = 'pas_evaluacionpmo_iniciativa';  ReferencingEntity = 'pas_evaluacionpmo';  ReferencedEntity = 'pas_iniciativa';   LookupSchemaName = 'pas_Iniciativa';   LookupLogicalName = 'pas_iniciativa';   LookupDisplay = 'Iniciativa';                  DeleteBehavior = 'Cascade' }
    @{ SchemaName = 'pas_evaluacionpmo_evaluador';   ReferencingEntity = 'pas_evaluacionpmo';  ReferencedEntity = 'systemuser';       LookupSchemaName = 'pas_Evaluador';    LookupLogicalName = 'pas_evaluador';    LookupDisplay = 'Evaluador PMO';               DeleteBehavior = 'Restrict' }
    # pas_evaluacionti
    @{ SchemaName = 'pas_evaluacionti_iniciativa';   ReferencingEntity = 'pas_evaluacionti';   ReferencedEntity = 'pas_iniciativa';   LookupSchemaName = 'pas_Iniciativa';   LookupLogicalName = 'pas_iniciativa';   LookupDisplay = 'Iniciativa';                  DeleteBehavior = 'Cascade' }
    @{ SchemaName = 'pas_evaluacionti_evaluador';    ReferencingEntity = 'pas_evaluacionti';   ReferencedEntity = 'systemuser';       LookupSchemaName = 'pas_Evaluador_TI'; LookupLogicalName = 'pas_evaluador_ti'; LookupDisplay = 'Evaluador TI';                DeleteBehavior = 'Restrict' }
    # pas_cotizacion
    @{ SchemaName = 'pas_cotizacion_iniciativa';     ReferencingEntity = 'pas_cotizacion';     ReferencedEntity = 'pas_iniciativa';   LookupSchemaName = 'pas_Iniciativa';   LookupLogicalName = 'pas_iniciativa';   LookupDisplay = 'Iniciativa';                  DeleteBehavior = 'Cascade' }
    # pas_horatrabajo
    @{ SchemaName = 'pas_horatrabajo_iniciativa';    ReferencingEntity = 'pas_horatrabajo';    ReferencedEntity = 'pas_iniciativa';   LookupSchemaName = 'pas_Iniciativa';   LookupLogicalName = 'pas_iniciativa';   LookupDisplay = 'Iniciativa';                  DeleteBehavior = 'Cascade' }
    @{ SchemaName = 'pas_horatrabajo_centrocosto';   ReferencingEntity = 'pas_horatrabajo';    ReferencedEntity = 'pas_centrocosto';  LookupSchemaName = 'pas_CentroCosto';  LookupLogicalName = 'pas_centrocosto';  LookupDisplay = 'Centro de Costo';             DeleteBehavior = 'Restrict' }
    @{ SchemaName = 'pas_horatrabajo_colaborador';   ReferencingEntity = 'pas_horatrabajo';    ReferencedEntity = 'systemuser';       LookupSchemaName = 'pas_Colaborador';  LookupLogicalName = 'pas_colaborador';  LookupDisplay = 'Colaborador';                 DeleteBehavior = 'Restrict' }
    # pas_votocomite
    @{ SchemaName = 'pas_votocomite_iniciativa';     ReferencingEntity = 'pas_votocomite';     ReferencedEntity = 'pas_iniciativa';   LookupSchemaName = 'pas_Iniciativa';   LookupLogicalName = 'pas_iniciativa';   LookupDisplay = 'Iniciativa';                  DeleteBehavior = 'Cascade' }
    @{ SchemaName = 'pas_votocomite_miembro';        ReferencingEntity = 'pas_votocomite';     ReferencedEntity = 'pas_miembrocomite'; LookupSchemaName = 'pas_Miembro';     LookupLogicalName = 'pas_miembro';      LookupDisplay = 'Miembro del Comite';          DeleteBehavior = 'Restrict' }
    # pas_documentoadj
    @{ SchemaName = 'pas_documentoadj_iniciativa';   ReferencingEntity = 'pas_documentoadj';   ReferencedEntity = 'pas_iniciativa';   LookupSchemaName = 'pas_Iniciativa';   LookupLogicalName = 'pas_iniciativa';   LookupDisplay = 'Iniciativa';                  DeleteBehavior = 'Cascade' }
    @{ SchemaName = 'pas_documentoadj_subidopor';    ReferencingEntity = 'pas_documentoadj';   ReferencedEntity = 'systemuser';       LookupSchemaName = 'pas_Subido_Por';   LookupLogicalName = 'pas_subido_por';   LookupDisplay = 'Subido por';                  DeleteBehavior = 'Restrict' }
    # pas_centrocosto -> empresa
    @{ SchemaName = 'pas_centrocosto_empresa';       ReferencingEntity = 'pas_centrocosto';    ReferencedEntity = 'pas_empresa';      LookupSchemaName = 'pas_Empresa';      LookupLogicalName = 'pas_empresa';      LookupDisplay = 'Empresa';                     DeleteBehavior = 'Restrict' }
    # pas_miembrocomite -> systemuser titular y suplente
    @{ SchemaName = 'pas_miembrocomite_titular';     ReferencingEntity = 'pas_miembrocomite';  ReferencedEntity = 'systemuser';       LookupSchemaName = 'pas_Titular';      LookupLogicalName = 'pas_titular';      LookupDisplay = 'Titular';                     DeleteBehavior = 'Restrict' }
    @{ SchemaName = 'pas_miembrocomite_suplente';    ReferencingEntity = 'pas_miembrocomite';  ReferencedEntity = 'systemuser';       LookupSchemaName = 'pas_Suplente';     LookupLogicalName = 'pas_suplente';     LookupDisplay = 'Suplente';                    DeleteBehavior = 'Restrict' }
)

if ($OnlyRelationship) {
    $relationships = $relationships | Where-Object { $_.SchemaName -eq $OnlyRelationship }
    if (-not $relationships) { throw "Relacion '$OnlyRelationship' no esta definida" }
}

# ==============================================================================
# Ejecucion
# ==============================================================================

$stats = @{ Created = 0; Skipped = 0; Failed = 0 }

foreach ($r in $relationships) {
    # 1. Skip si la relacion ya existe via API
    $existing = Get-DataverseRelationship -Environment $Environment -SchemaName $r.SchemaName
    if ($existing) {
        Write-Host "  [SKIP] $($r.SchemaName) (relacion ya existe)" -ForegroundColor DarkYellow
        $stats.Skipped++
        continue
    }

    # 2. Skip si el lookup attribute ya existe en el referencing entity (manual o desde otra fuente)
    $existingLookup = Get-DataverseAttribute -Environment $Environment -EntityLogicalName $r.ReferencingEntity -AttributeLogicalName $r.LookupLogicalName
    if ($existingLookup) {
        Write-Host "  [SKIP] $($r.SchemaName) (lookup '$($r.LookupLogicalName)' ya existe en $($r.ReferencingEntity), creado manualmente o por otro proceso)" -ForegroundColor DarkYellow
        $stats.Skipped++
        continue
    }

    $body = Build-OneToManyRelationship `
        -SchemaName $r.SchemaName `
        -ReferencingEntity $r.ReferencingEntity `
        -ReferencedEntity $r.ReferencedEntity `
        -LookupSchemaName $r.LookupSchemaName `
        -LookupLogicalName $r.LookupLogicalName `
        -LookupDisplay $r.LookupDisplay `
        -DeleteBehavior $r.DeleteBehavior

    if ($PSCmdlet.ShouldProcess($r.SchemaName, "Create OneToMany relationship $($r.ReferencingEntity) -> $($r.ReferencedEntity)")) {
        try {
            Invoke-DataverseApi -Environment $Environment -Method POST -Path 'RelationshipDefinitions' -Body $body -SolutionUniqueName $Solution | Out-Null
            Write-Host "  [OK]   $($r.SchemaName) ($($r.ReferencingEntity) -> $($r.ReferencedEntity))" -ForegroundColor Green
            $stats.Created++
        } catch {
            Write-Host "  [FAIL] $($r.SchemaName): $($_.Exception.Message)" -ForegroundColor Red
            $stats.Failed++
        }
    } else {
        Write-Host "  [WHATIF] $($r.SchemaName)" -ForegroundColor Magenta
    }
}

Write-Host "`nResumen: Created=$($stats.Created) Skipped=$($stats.Skipped) Failed=$($stats.Failed)" -ForegroundColor $(if ($stats.Failed -gt 0) { 'Red' } else { 'Cyan' })
if ($stats.Failed -gt 0) { exit 1 }
Write-Host "=== OK ===`n" -ForegroundColor Green
