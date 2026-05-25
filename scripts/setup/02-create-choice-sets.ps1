<#
.SYNOPSIS
    Crea los 11 global option sets (choices) de INNOVA en innova-core.

.DESCRIPTION
    Implementa parte de S0-4 (issue #15): los choices van primero porque las tablas
    los referencian. Crea en el solution 'innova_core' usando el publisher 'Pasqui'
    (prefix 'pas').

    Choices creados:
      pas_iniciativa_estado (17 valores)
      pas_iniciativa_prioridad
      pas_iniciativa_complejidad
      pas_iniciativa_clasificacion
      pas_cotizacion_tipo
      pas_decision
      pas_voto
      pas_hora_tipo
      pas_documento_tipo
      pas_parametro_tipo
      pas_evaluacion_estado

    Definiciones canonicas en docs/architecture/data-model.md#choice-sets-globales.

    Idempotente: skip si el choice ya existe.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER WhatIf
    Dry-run.

.EXAMPLE
    pwsh ./scripts/setup/02-create-choice-sets.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev'
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\dataverse.ps1"

$Solution = 'innova_core'

Write-Host "`n=== INNOVA S0-4 (paso 1/3): Crear Choice Sets en $($Environment.ToUpper()) ===" -ForegroundColor Cyan

Initialize-DataverseSession | Out-Null

# ==============================================================================
# Definiciones (alineadas con docs/architecture/data-model.md)
# ==============================================================================

$choices = @(
    @{
        Name = 'pas_iniciativa_estado'
        DisplayName = 'Estado de iniciativa'
        Description = 'Estado del workflow de una iniciativa INNOVA. Labels alineados con el cuadro resumen del cliente (issue #33).'
        Options = @(
            # Values 100000000-100000016 son los originales del Sprint 0; labels reasignados a los nombres exactos del cliente.
            # Como no hay datos en DEV/QA todavia, podemos resignificar libremente sin migracion.
            @{ Value = 100000000; Label = 'Borrador' }
            @{ Value = 100000001; Label = 'Revision inicial PMO' }
            @{ Value = 100000002; Label = 'Estimacion Desarrollo' }
            @{ Value = 100000003; Label = 'Revision Estimacion de la Jefatura' }
            @{ Value = 100000004; Label = 'Estimacion Aprobada por Jefatura' }
            @{ Value = 100000005; Label = 'Estimacion Devuelta por Jefatura' }
            @{ Value = 100000006; Label = 'Estimacion Rechazada por Jefatura' }
            @{ Value = 100000007; Label = 'Revision Iniciativa Jefatura' }
            @{ Value = 100000008; Label = 'Iniciativa Devuelta por Jefatura' }
            @{ Value = 100000009; Label = 'En Cotizacion' }
            @{ Value = 100000010; Label = 'Revision Gerencia de Negocio' }
            @{ Value = 100000011; Label = 'Aprobada por Gerencia General de Negocio' }
            @{ Value = 100000012; Label = 'Rechazada por Gerencia General de Negocio' }
            @{ Value = 100000013; Label = 'Revision Comite de Proyectos' }
            @{ Value = 100000014; Label = 'Aprobada' }
            @{ Value = 100000015; Label = 'Rechazo del Comite' }
            @{ Value = 100000016; Label = 'Cancelada' }
        )
    }
    @{
        Name = 'pas_iniciativa_prioridad'
        DisplayName = 'Prioridad de iniciativa'
        Description = 'Asignada por Jefatura al aprobar'
        Options = @(
            @{ Value = 1; Label = 'P1 - Critica' }
            @{ Value = 2; Label = 'P2 - Alta' }
            @{ Value = 3; Label = 'P3 - Media' }
        )
    }
    @{
        Name = 'pas_iniciativa_complejidad'
        DisplayName = 'Complejidad de iniciativa'
        Description = 'Asignada por PMO en evaluacion'
        Options = @(
            @{ Value = 1; Label = 'Baja' }
            @{ Value = 2; Label = 'Media' }
            @{ Value = 3; Label = 'Alta' }
            @{ Value = 4; Label = 'Muy Alta' }
        )
    }
    @{
        Name = 'pas_iniciativa_clasificacion'
        DisplayName = 'Clasificacion de iniciativa'
        Description = 'Categoria funcional de la iniciativa. G5 (issue #32): reducido a las 4 opciones del cliente y consumido como MultiSelect (pas_clasificacion y pas_clasificacion_pmo)'
        Options = @(
            # G5 - issue #32: cliente pidio exactamente estas 4 (Regulatoria, Operativa, Estrategica, Tecnologia)
            # Conservamos valores 3 y 4 del Sprint 0 (relabel a Regulatoria/Tecnologia) y agregamos 7 (Operativa) y 8 (Estrategica)
            # Los valores 1,2,5,6 obsoletos los borra el script de migracion migrate-pas-clasificacion-to-multiselect.ps1
            @{ Value = 3; Label = 'Regulatoria' }
            @{ Value = 4; Label = 'Tecnologia' }
            @{ Value = 7; Label = 'Operativa' }
            @{ Value = 8; Label = 'Estrategica' }
        )
    }
    @{
        Name = 'pas_cotizacion_tipo'
        DisplayName = 'Tipo de cotizacion'
        Description = 'Origen de la cotizacion'
        Options = @(
            @{ Value = 1; Label = 'Interna' }
            @{ Value = 2; Label = 'Externa' }
        )
    }
    @{
        Name = 'pas_decision'
        DisplayName = 'Decision de aprobacion'
        Description = 'Usado por Jefatura y Gerencia'
        Options = @(
            @{ Value = 1; Label = 'Aprobar' }
            @{ Value = 2; Label = 'Devolver' }
            @{ Value = 3; Label = 'Rechazar' }
        )
    }
    @{
        Name = 'pas_voto'
        DisplayName = 'Voto del Comite'
        Description = 'Binario - usado solo en Comite'
        Options = @(
            @{ Value = 1; Label = 'Aprobar' }
            @{ Value = 2; Label = 'Rechazar' }
        )
    }
    @{
        Name = 'pas_hora_tipo'
        DisplayName = 'Tipo de hora trabajada'
        Description = 'Origen funcional de la hora'
        Options = @(
            @{ Value = 1; Label = 'Levantamiento PMO' }
            @{ Value = 2; Label = 'Estimacion TI' }
            @{ Value = 3; Label = 'Ejecucion' }
            @{ Value = 4; Label = 'Otros' }
        )
    }
    @{
        Name = 'pas_documento_tipo'
        DisplayName = 'Tipo de documento adjunto'
        Description = 'Clasificacion de documentos en SharePoint'
        Options = @(
            @{ Value = 1; Label = 'Cotizacion' }
            @{ Value = 2; Label = 'Entregable' }
            @{ Value = 3; Label = 'Soporte / Analisis' }
            @{ Value = 4; Label = 'Otro' }
        )
    }
    @{
        Name = 'pas_parametro_tipo'
        DisplayName = 'Tipo de parametro del sistema'
        Description = 'Determina cual columna de valor se usa en pas_parametro'
        Options = @(
            @{ Value = 1; Label = 'Texto' }
            @{ Value = 2; Label = 'Numero' }
            @{ Value = 3; Label = 'Fecha' }
            @{ Value = 4; Label = 'Booleano' }
        )
    }
    @{
        Name = 'pas_evaluacion_estado'
        DisplayName = 'Estado de evaluacion'
        Description = 'Usado por evaluacion PMO y TI'
        Options = @(
            @{ Value = 1; Label = 'En Proceso' }
            @{ Value = 2; Label = 'Completa' }
        )
    }
)

# ==============================================================================
# Crear o saltar
# ==============================================================================

$created = 0
$skipped = 0
$failed = 0

$updated = 0

foreach ($choice in $choices) {
    $existing = Get-DataverseGlobalOptionSet -Environment $Environment -Name $choice.Name
    if ($existing) {
        # Sincronizar labels: para cada opcion definida, si el label actual difiere, llamar UpdateOptionValue.
        # No agrega ni elimina opciones (eso requiere otras actions; manejar manualmente si cambia el cardinal).
        $currentByValue = @{}
        foreach ($existingOpt in $existing.Options) {
            $currentByValue[[int]$existingOpt.Value] = $existingOpt.Label.UserLocalizedLabel.Label
        }

        $localUpdated = 0; $localSkipped = 0
        foreach ($opt in $choice.Options) {
            $v = [int]$opt.Value
            $newLbl = $opt.Label
            $curLbl = $currentByValue[$v]
            if ($null -eq $curLbl) {
                Write-Host "  [WARN] $($choice.Name): Value=$v no existe en el option set actual; skip (necesita InsertOptionValue manual)" -ForegroundColor DarkYellow
                continue
            }
            if ($curLbl -eq $newLbl) {
                $localSkipped++
                continue
            }
            if ($PSCmdlet.ShouldProcess("$($choice.Name) Value=$v", "Update label '$curLbl' -> '$newLbl'")) {
                try {
                    Update-DataverseGlobalOptionSetLabel -Environment $Environment -OptionSetName $choice.Name -Value $v -NewLabel $newLbl
                    Write-Host "    [UPDATE] $($choice.Name) [$v]: '$curLbl' -> '$newLbl'" -ForegroundColor Green
                    $localUpdated++
                } catch {
                    Write-Host "    [FAIL] $($choice.Name) [$v]: $($_.Exception.Message)" -ForegroundColor Red
                    $failed++
                }
            }
        }
        if ($localUpdated -gt 0) {
            Write-Host "  [SYNCED] $($choice.Name): $localUpdated labels actualizados, $localSkipped sin cambios" -ForegroundColor Cyan
            $updated += $localUpdated
        } else {
            Write-Host "  [SKIP]   $($choice.Name) ya esta sincronizado (id: $($existing.MetadataId))" -ForegroundColor DarkYellow
        }
        $skipped++
        continue
    }

    # Construir body OptionSetMetadata
    $options = @()
    foreach ($opt in $choice.Options) {
        $options += @{
            '@odata.type' = 'Microsoft.Dynamics.CRM.OptionMetadata'
            Value = $opt.Value
            Label = (New-LocalizedLabel -Text $opt.Label)
        }
    }

    $body = @{
        '@odata.type' = 'Microsoft.Dynamics.CRM.OptionSetMetadata'
        Name = $choice.Name
        DisplayName = (New-LocalizedLabel -Text $choice.DisplayName)
        Description = (New-LocalizedLabel -Text $choice.Description)
        IsGlobal = $true
        OptionSetType = 'Picklist'
        Options = $options
    }

    if ($PSCmdlet.ShouldProcess($choice.Name, "Create Global Option Set with $($options.Count) options")) {
        try {
            Invoke-DataverseApi -Environment $Environment -Method POST -Path 'GlobalOptionSetDefinitions' -Body $body -SolutionUniqueName $Solution | Out-Null
            Write-Host "  [OK]   $($choice.Name) creada con $($options.Count) opciones" -ForegroundColor Green
            $created++
        } catch {
            Write-Host "  [FAIL] $($choice.Name): $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    } else {
        Write-Host "  [WHATIF] Crearia $($choice.Name) con $($options.Count) opciones" -ForegroundColor Magenta
    }
}

Write-Host "`nResumen: Creadas=$created Sincronizadas(labels)=$updated Skip=$skipped Failed=$failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Cyan' })

if ($failed -gt 0) { exit 1 }
Write-Host "=== OK ===`n" -ForegroundColor Green
