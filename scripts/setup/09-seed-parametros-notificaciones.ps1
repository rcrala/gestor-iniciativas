<#
.SYNOPSIS
    Sembrar los parametros de notificacion usados por los flows productivos.

.DESCRIPTION
    Agrega a pas_parametro las 3 claves necesarias para el flow
    "INNOVA - Iniciativa Creada - Notificar PMO" (issue #55, S1-01) y futuros
    flows de notificacion:

      - PmoDestinatariosCorreo   (Texto)  Lista de correos PMO (comma-separada)
      - AdminCorreo              (Texto)  Correo del admin para alertas de error
      - UrlBaseApp               (Texto)  URL base del Canvas App (sufijo recordId)

    Idempotente: skip si la clave ya existe (preserva ajustes del admin).
    Flag -ForceUpdate para sobreescribir.

    Sigue el patron de 06-seed-parametros.ps1 (G8, issue #35).

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER ForceUpdate
    Sobreescribir valores existentes.

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
$TipoTexto = 1

Write-Host "`n=== INNOVA S1-01: Seed parametros de notificacion en $($Environment.ToUpper()) ===" -ForegroundColor Cyan
Initialize-DataverseSession | Out-Null

$parametros = @(
    @{
        Clave       = 'PmoDestinatariosCorreo'
        Display     = 'Destinatarios PMO (lista correos)'
        Tipo        = $TipoTexto
        ValorTexto  = 'pmo@grupopasqui.com'
        Descripcion = 'Lista comma-separada de correos del equipo PMO. Cada correo recibe la notificacion cuando se crea una pas_iniciativa. Placeholder; ajustar a los correos reales en DEV/QA/PROD.'
    },
    @{
        Clave       = 'AdminCorreo'
        Display     = 'Correo admin para alertas de error'
        Tipo        = $TipoTexto
        ValorTexto  = 'admin@grupopasqui.com'
        Descripcion = 'Correo unico que recibe las alertas cuando un flow productivo falla (Scope Error Handler). Placeholder; ajustar al admin real de la solucion.'
    },
    @{
        Clave       = 'UrlBaseApp'
        Display     = 'URL base del Canvas App de iniciativas'
        Tipo        = $TipoTexto
        ValorTexto  = 'https://apps.powerapps.com/play/PLACEHOLDER-ENV-ID/PLACEHOLDER-APP-ID?recordId='
        Descripcion = 'URL base que los correos usan para construir el link {urlIniciativa}. Se concatena con el pas_iniciativaid. Reemplazar PLACEHOLDER-ENV-ID y PLACEHOLDER-APP-ID con los GUIDs reales cuando se publique el Canvas App (M-02 Solicitante).'
    }
)

# Helpers idem a 06-seed-parametros.ps1
function Get-Parametro {
    param([string]$Environment, [string]$Clave)
    $escaped = $Clave.Replace("'", "''")
    $result = Invoke-DataverseApi -Environment $Environment -Method GET `
        -Path "pas_parametros?`$filter=pas_clave eq '$escaped'&`$top=1"
    if ($result.value -and $result.value.Count -gt 0) { return $result.value[0] }
    return $null
}

function Build-ParametroBody {
    param($P)
    @{
        pas_clave          = $P.Clave
        pas_nombre_display = $P.Display
        pas_tipo           = $P.Tipo
        pas_descripcion    = $P.Descripcion
        pas_valor_texto    = $P.ValorTexto
    }
}

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
                Write-Host "  [SKIP]  $($p.Clave) ya existe (id: $($existing.pas_parametroid)). Valor: '$($existing.pas_valor_texto)'" -ForegroundColor DarkYellow
                $stats.Skipped++
            }
            continue
        }

        $body = Build-ParametroBody -P $p
        if ($PSCmdlet.ShouldProcess($p.Clave, "Create parametro")) {
            $new = Invoke-DataverseApi -Environment $Environment -Method POST `
                -Path 'pas_parametros' -Body $body -PreferReturn -SolutionUniqueName $Solution
            Write-Host "  [OK]    $($p.Clave) creado (id: $($new.pas_parametroid)). Valor: '$($p.ValorTexto)'" -ForegroundColor Green
            $stats.Created++
        } else {
            Write-Host "  [WHATIF] crearia $($p.Clave) con valor '$($p.ValorTexto)'" -ForegroundColor Magenta
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

Write-Host "`nPasos siguientes:" -ForegroundColor Cyan
Write-Host "  1. Ajustar valores con: pwsh ./scripts/setup/09-seed-parametros-notificaciones.ps1 -ForceUpdate" -ForegroundColor White
Write-Host "     o editar directamente en maker portal -> Tables -> pas_parametro" -ForegroundColor White
Write-Host "  2. Registrar el flow: pwsh ./scripts/flows/register-iniciativa-creada-notificar-pmo.ps1" -ForegroundColor White
Write-Host "  3. Activar el flow manualmente en maker portal y crear las connection references" -ForegroundColor White
Write-Host "=== OK ===`n" -ForegroundColor Green
