<#
.SYNOPSIS
    Sembrar los parametros operacionales en pas_parametro (G8 / issue #35).

.DESCRIPTION
    Crea los parametros configurables que el cliente menciono como necesarios
    (umbrales, tarifas, horas por complejidad, branding). Idempotente: si la
    clave ya existe, salta (no sobreescribe los valores que el admin haya
    cambiado via M11).

    Categorias sembradas:
      - Tarifas (CRC):       TarifaHoraPMO, TarifaHoraDesarrollador
      - Umbrales (USD):      UmbralEscalamientoComite_USD
      - Reglas:              MultiEmpresaEscalaComite
      - Horas/complejidad:   HorasComplejidadBaja/Media/Alta/MuyAlta
      - Recordatorios:       DiasRecordatorio
      - Branding (cliente):  BrandingLogoUrl, BrandingPrimaryColor, BrandingSecondaryColor

    Documentado en docs/architecture/parametros.md.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER ForceUpdate
    Si se especifica, sobreescribe los valores existentes (cuidado: pisa los
    cambios del admin). Default: skip si existe.

.PARAMETER WhatIf
    Dry-run.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',
    [switch]$ForceUpdate
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\dataverse.ps1"

$Solution = 'innova_core'

Write-Host "`n=== INNOVA G8: Seed Parametros en $($Environment.ToUpper()) ===" -ForegroundColor Cyan
Initialize-DataverseSession | Out-Null

# Tipos en pas_parametro_tipo (definidos en 02-create-choice-sets.ps1)
$TipoTexto    = 1
$TipoNumero   = 2
$TipoFecha    = 3
$TipoBooleano = 4

# ==============================================================================
# Definiciones de parametros
# ==============================================================================

$parametros = @(
    # --- Tarifas (CRC) ---
    @{
        Clave        = 'TarifaHoraPMO'
        Display      = 'Tarifa hora PMO (CRC)'
        Tipo         = $TipoNumero
        ValorNumero  = 25000
        Unidad       = 'CRC/hora'
        Descripcion  = 'Costo por hora de un PMO en colones. Snapshot tomado al crear pas_horatrabajo para preservar precio historico. Placeholder; ajustar segun politica de RRHH del cliente.'
    }
    @{
        Clave        = 'TarifaHoraDesarrollador'
        Display      = 'Tarifa hora Desarrollador TI (CRC)'
        Tipo         = $TipoNumero
        ValorNumero  = 35000
        Unidad       = 'CRC/hora'
        Descripcion  = 'Costo por hora de un desarrollador TI en colones. Placeholder; ajustar segun rate-card vigente.'
    }
    # --- Umbral de escalamiento al Comite ---
    @{
        Clave        = 'UmbralEscalamientoComite_USD'
        Display      = 'Umbral escalamiento Comite (USD)'
        Tipo         = $TipoNumero
        ValorNumero  = 10000
        Unidad       = 'USD'
        Descripcion  = 'Si pas_iniciativa.pas_monto_estimado convertido a USD supera este umbral, la iniciativa escala al Comite (BR-14). Configurable via M11.'
    }
    @{
        Clave        = 'MultiEmpresaEscalaComite'
        Display      = 'Multi-empresa escala a Comite'
        Tipo         = $TipoBooleano
        ValorBool    = $true
        Descripcion  = 'Si true, cualquier iniciativa con pas_es_multi_empresa=true va automaticamente al Comite, sin importar el monto (BR-13). C4 del cliente: configurable.'
    }
    # --- Horas por complejidad (segun PMO) ---
    @{
        Clave        = 'HorasComplejidadBaja'
        Display      = 'Horas por complejidad: Baja'
        Tipo         = $TipoNumero
        ValorNumero  = 16
        Unidad       = 'horas'
        Descripcion  = 'Horas de levantamiento esperadas cuando PMO marca complejidad=Baja. Usado para sugerir horas en pas_evaluacionpmo.pas_horas_levantamiento.'
    }
    @{
        Clave        = 'HorasComplejidadMedia'
        Display      = 'Horas por complejidad: Media'
        Tipo         = $TipoNumero
        ValorNumero  = 48
        Unidad       = 'horas'
        Descripcion  = 'Idem para complejidad=Media.'
    }
    @{
        Clave        = 'HorasComplejidadAlta'
        Display      = 'Horas por complejidad: Alta'
        Tipo         = $TipoNumero
        ValorNumero  = 56
        Unidad       = 'horas'
        Descripcion  = 'Idem para complejidad=Alta.'
    }
    @{
        Clave        = 'HorasComplejidadMuyAlta'
        Display      = 'Horas por complejidad: Muy Alta'
        Tipo         = $TipoNumero
        ValorNumero  = 96
        Unidad       = 'horas'
        Descripcion  = 'Idem para complejidad=Muy Alta.'
    }
    # --- Recordatorios ---
    @{
        Clave        = 'DiasRecordatorio'
        Display      = 'Dias para recordatorio de inactividad'
        Tipo         = $TipoNumero
        ValorNumero  = 3
        Unidad       = 'dias'
        Descripcion  = 'Si una iniciativa permanece sin cambio de estado por N dias, se dispara un correo recordatorio al duenio actual (BR-16). Cliente especifico 3 dias.'
    }
    # --- Branding (configurable por cliente C6) ---
    @{
        Clave        = 'BrandingLogoUrl'
        Display      = 'URL del logo del cliente'
        Tipo         = $TipoTexto
        ValorTexto   = 'https://placeholder.cdn/innova-logo.png'
        Descripcion  = 'URL absoluta del logo del cliente. Mostrado en header de Canvas Apps y en correos. Configurable via M11 sin redeploy.'
    }
    @{
        Clave        = 'BrandingPrimaryColor'
        Display      = 'Color primario corporativo (hex)'
        Tipo         = $TipoTexto
        ValorTexto   = '#0078D4'
        Descripcion  = 'Color primario en formato hex (#RRGGBB). Usado en Canvas Apps y plantillas de correo. Default del mockup del cliente.'
    }
    @{
        Clave        = 'BrandingSecondaryColor'
        Display      = 'Color secundario corporativo (hex)'
        Tipo         = $TipoTexto
        ValorTexto   = '#FF8C00'
        Descripcion  = 'Color secundario / accent en formato hex (#RRGGBB).'
    }
)

# ==============================================================================
# Helpers
# ==============================================================================

function Get-Parametro {
    param(
        [Parameter(Mandatory)] [string]$Environment,
        [Parameter(Mandatory)] [string]$Clave
    )
    # Filtra por pas_clave (Primary name)
    $escaped = $Clave.Replace("'", "''")
    $result = Invoke-DataverseApi -Environment $Environment -Method GET `
        -Path "pas_parametros?`$filter=pas_clave eq '$escaped'&`$top=1"
    if ($result.value -and $result.value.Count -gt 0) {
        return $result.value[0]
    }
    return $null
}

function Build-ParametroBody {
    param($P)
    $body = @{
        pas_clave         = $P.Clave
        pas_nombre_display = $P.Display
        pas_tipo          = $P.Tipo
        pas_descripcion   = $P.Descripcion
    }
    if ($P.ContainsKey('Unidad') -and $P.Unidad) { $body.pas_unidad = $P.Unidad }

    # Solo poblar la columna de valor correspondiente al tipo
    switch ($P.Tipo) {
        1 { if ($P.ContainsKey('ValorTexto')) { $body.pas_valor_texto = $P.ValorTexto } }
        2 { if ($P.ContainsKey('ValorNumero')) { $body.pas_valor_numero = [decimal]$P.ValorNumero } }
        3 { if ($P.ContainsKey('ValorFecha')) { $body.pas_valor_fecha = $P.ValorFecha } }
        4 { if ($P.ContainsKey('ValorBool')) { $body.pas_valor_booleano = [bool]$P.ValorBool } }
    }
    return $body
}

# ==============================================================================
# Ejecucion
# ==============================================================================

$stats = @{ Created = 0; Skipped = 0; Updated = 0; Failed = 0 }

foreach ($p in $parametros) {
    Write-Host "`n--- $($p.Clave) ---" -ForegroundColor Cyan
    try {
        $existing = Get-Parametro -Environment $Environment -Clave $p.Clave

        if ($existing) {
            if ($ForceUpdate) {
                $body = Build-ParametroBody -P $p
                if ($PSCmdlet.ShouldProcess($p.Clave, "Force-update parametro")) {
                    Invoke-DataverseApi -Environment $Environment -Method PATCH `
                        -Path "pas_parametros($($existing.pas_parametroid))" `
                        -Body $body -SolutionUniqueName $Solution | Out-Null
                    Write-Host "  [UPDATE] $($p.Clave) sobreescrito (id: $($existing.pas_parametroid))" -ForegroundColor Yellow
                    $stats.Updated++
                }
            } else {
                Write-Host "  [SKIP]  $($p.Clave) ya existe (id: $($existing.pas_parametroid))" -ForegroundColor DarkYellow
                $stats.Skipped++
            }
            continue
        }

        $body = Build-ParametroBody -P $p
        if ($PSCmdlet.ShouldProcess($p.Clave, "Create parametro")) {
            $new = Invoke-DataverseApi -Environment $Environment -Method POST `
                -Path 'pas_parametros' -Body $body -PreferReturn -SolutionUniqueName $Solution
            Write-Host "  [OK]    $($p.Clave) creado (id: $($new.pas_parametroid))" -ForegroundColor Green
            $stats.Created++
        } else {
            Write-Host "  [WHATIF] crearia $($p.Clave)" -ForegroundColor Magenta
            $stats.Created++
        }
    } catch {
        Write-Host "  [FAIL]  $($p.Clave): $($_.Exception.Message)" -ForegroundColor Red
        $stats.Failed++
    }
}

Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
Write-Host "Created=$($stats.Created) Updated=$($stats.Updated) Skipped=$($stats.Skipped) Failed=$($stats.Failed)"
if ($stats.Failed -gt 0) {
    Write-Host "=== HUBO FALLAS - revisar arriba ===" -ForegroundColor Red
    exit 1
}
Write-Host "=== OK ===`n" -ForegroundColor Green
