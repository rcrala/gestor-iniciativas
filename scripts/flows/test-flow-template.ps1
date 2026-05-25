#Requires -Version 7.0
<#
.SYNOPSIS
    Prueba los 3 escenarios obligatorios del flow plantilla canonica.

.DESCRIPTION
    Issue #19 / Runbook 08 exige cubrir 3 casos:
      1. Camino feliz (los 4 scopes corren, Error Handler queda en Skipped)
      2. Datos invalidos (Validations termina Cancelled, demas Skipped)
      3. Error tecnico (Main Logic Failed, Error Handler corre, Terminate Failed)

    El flow plantilla usa trigger Manual (PowerApps V2). El SP NO puede invocar
    triggers manuales directamente (esa API es user-context). Para invocar el
    flow, esta script genera los 3 payloads JSON exactos que se deben pegar en
    el panel "Test" del maker portal.

    Si se proporciona -TriggerUrl, hace POST directo a esa URL (la URL se obtiene
    desde el maker portal -> Edit -> trigger -> Settings -> URL HTTP del flow,
    o desde Cualquier flow ya activado a traves de su HTTP request URL).

.PARAMETER TriggerUrl
    Opcional. URL HTTP del trigger manual del flow ya activado. Si se omite,
    solo se imprimen los payloads para copiar/pegar manualmente.

.PARAMETER Scenario
    'all', 'happy', 'cancelled', 'error'. Default 'all'.

.EXAMPLE
    pwsh ./scripts/flows/test-flow-template.ps1
    # Imprime los 3 payloads para copiar al panel Test del maker portal.

.EXAMPLE
    pwsh ./scripts/flows/test-flow-template.ps1 -TriggerUrl 'https://prod-XX.westus.logic.azure.com:443/workflows/.../triggers/manual/paths/invoke?api-version=2016-06-01&sp=...&sv=1.0&sig=...'
    # POSTea los 3 payloads a la URL real.
#>
[CmdletBinding()]
param(
    [string]$TriggerUrl,

    [ValidateSet('all','happy','cancelled','error')]
    [string]$Scenario = 'all'
)

$ErrorActionPreference = 'Stop'

# === Payloads de los 3 escenarios ===
$Scenarios = @(
    @{
        Key = 'happy'
        Nombre = 'Camino feliz'
        Descripcion = 'Todos los inputs validos. Esperado: Validations Succeeded, Main Logic Succeeded, Notifications Succeeded, Error Handler Skipped, run final Succeeded.'
        Payload = @{
            Mensaje_de_prueba = 'Test camino feliz - todos los scopes deberian completar OK'
            Forzar_fallo_validacion = $false
            Forzar_fallo_main = $false
        }
        EsperadoStatus = 'Succeeded'
        EsperadoErrorHandler = 'Skipped'
    },
    @{
        Key = 'cancelled'
        Nombre = 'Cancelado por validacion'
        Descripcion = 'Forzar_fallo_validacion=true. Esperado: Validations termina Cancelled (con Terminate dentro del Condition), Main/Notifications/ErrorHandler Skipped, run final Cancelled.'
        Payload = @{
            Mensaje_de_prueba = 'Esto no importa porque Forzar_fallo_validacion=true'
            Forzar_fallo_validacion = $true
            Forzar_fallo_main = $false
        }
        EsperadoStatus = 'Cancelled'
        EsperadoErrorHandler = 'Skipped'
    },
    @{
        Key = 'error'
        Nombre = 'Error tecnico en Main Logic'
        Descripcion = 'Forzar_fallo_main=true. Esperado: Validations Succeeded, Main Logic Failed (Compose int(texto) lanza error), Notifications Skipped, Error Handler Succeeded (con Terminate Failed), run final Failed.'
        Payload = @{
            Mensaje_de_prueba = 'Test error tecnico - Main Logic deberia fallar y Error Handler correr'
            Forzar_fallo_validacion = $false
            Forzar_fallo_main = $true
        }
        EsperadoStatus = 'Failed'
        EsperadoErrorHandler = 'Succeeded'
    }
)

Write-Host "`n=== INNOVA: Test flow plantilla canonica ===" -ForegroundColor Cyan
Write-Host "Issue #19 / Runbook 08 - 3 escenarios obligatorios`n" -ForegroundColor DarkGray

if (-not $TriggerUrl) {
    Write-Host "MODO: Solo imprimir payloads (no se ejecuta nada)." -ForegroundColor Yellow
    Write-Host @"

Para invocar realmente el flow:
  1. Abrir maker portal -> Solutions -> innova_core -> el flow 'INNOVA - Plantilla - Patron Estandar ...'
  2. Test -> Manually -> Test
  3. Pegar el JSON Payload de cada escenario y ejecutar
  4. Verificar el resultado contra 'EsperadoStatus' y 'EsperadoErrorHandler'

Alternativa: relanzar con -TriggerUrl '<HTTP POST URL del trigger manual>'
La URL se ve en el editor del flow -> trigger -> Settings -> 'HTTP POST URL' (despues de Save+Turn on)

"@ -ForegroundColor DarkGray
}

$toRun = if ($Scenario -eq 'all') { $Scenarios } else { $Scenarios | Where-Object Key -eq $Scenario }

foreach ($sc in $toRun) {
    Write-Host "`n--- Escenario: $($sc.Nombre) ($($sc.Key)) ---" -ForegroundColor Cyan
    Write-Host "  $($sc.Descripcion)" -ForegroundColor DarkGray
    $payloadJson = $sc.Payload | ConvertTo-Json -Depth 5
    Write-Host "`n  Payload:" -ForegroundColor White
    Write-Host $payloadJson -ForegroundColor Gray
    Write-Host "`n  Esperado:" -ForegroundColor White
    Write-Host "    Run status        : $($sc.EsperadoStatus)" -ForegroundColor Gray
    Write-Host "    Scope Error Handler: $($sc.EsperadoErrorHandler)" -ForegroundColor Gray

    if ($TriggerUrl) {
        Write-Host "`n  Invocando..." -ForegroundColor Yellow
        try {
            $resp = Invoke-WebRequest `
                -Uri $TriggerUrl `
                -Method POST `
                -ContentType 'application/json' `
                -Body $payloadJson `
                -ErrorAction Stop

            Write-Host "  HTTP $($resp.StatusCode) - aceptado" -ForegroundColor Green

            # El Run ID se devuelve en el header x-ms-workflow-run-id
            $runId = $resp.Headers['x-ms-workflow-run-id']
            if ($runId) {
                Write-Host "  Run ID: $runId" -ForegroundColor DarkGray
                Write-Host "  Verificar resultado en maker portal -> el flow -> Run history" -ForegroundColor DarkGray
            }
        } catch {
            # Para escenario 'cancelled', el HTTP responde 200 igual (el Cancelled es del run, no del trigger)
            # Para 'error', el run falla pero el trigger acepta
            $code = $_.Exception.Response.StatusCode.value__
            Write-Host "  HTTP $code - $($_.Exception.Message)" -ForegroundColor Red
            if ($code -in 200,202) {
                Write-Host "  (Es OK - el run continua async, ver Run history)" -ForegroundColor DarkGray
            }
        }
    }
}

Write-Host "`n=== Done ===" -ForegroundColor Green
Write-Host "Para revisar resultados detallados:" -ForegroundColor White
Write-Host "  Maker portal -> Solutions -> innova_core -> el flow -> Run history" -ForegroundColor DarkGray
Write-Host "  Cada scope debe mostrar el estado esperado (Succeeded / Cancelled / Failed / Skipped)`n" -ForegroundColor DarkGray
