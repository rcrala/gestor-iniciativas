# Runbook 09 - Plantilla canonica de Power Automate flow

## Objetivo

Materializar la plantilla canonica que TODO flow nuevo de INNOVA debe copiar.
El patron viene del runbook 08; este runbook lo convierte en un artefacto
reutilizable, versionado en git, y desplegable en DEV via script.

Issue de referencia: **#19 (S0-8)**.

## Alcance

- Plantilla JSON estructural en `solutions/innova-flows/templates/flow-canonico-plantilla.json`.
- Script de registro en Dataverse via Web API (`scripts/flows/register-flow-template.ps1`).
- Script de test de los 3 escenarios obligatorios (`scripts/flows/test-flow-template.ps1`).
- Esta documentacion de uso.

Fuera de alcance:
- Crear flows de negocio reales (eso es S1+).
- Pack/unpack del solution `innova-flows` completo (la solution se hace cuando exista al menos 1 flow productivo).

## Estructura canonica (los 4 scopes)

```
Trigger (Manual / Dataverse / Scheduler)
        |
        v
Scope - Validations  ----Cancelled----> (fin)
        |
   Succeeded
        v
Scope - Main Logic   ----Failed/TimedOut---+
        |                                  |
   Succeeded                               |
        v                                  |
Scope - Notifications ----Failed/TimedOut--+
        |                                  |
   Succeeded                               v
        v                       Scope - Error Handler
       (fin OK)                 (Compose log + Terminate Failed)
```

Reglas obligatorias:

- Cada scope con `runAfter` explicito.
- Error Handler con `runAfter` = `Failed` OR `TimedOut` de los 3 anteriores.
- Toda accion externa (HTTP, Office365, Dataverse, Teams, SharePoint) con `retryPolicy` Fixed 10s x 4 minimo.
- Names sin espacios (usar underscore). Sin `Compose 2`, `Send_an_email`.
- Connection References, nunca embebidas.
- Inputs del trigger via `triggerBody()?['CampoX']` con `coalesce` para defaults.

## Prerrequisitos

1. Service Principal configurado para DEV (issue #16 / runbook 05).
2. `.env.dev` con `INNOVA_TENANT_ID`, `INNOVA_SP_CLIENT_ID`, `INNOVA_SP_CLIENT_SECRET`, `INNOVA_DEV_URL`.
3. Solution `innova_core` existente en DEV (esta desde el bootstrap).
4. PowerShell 7+ con cmdlets `Invoke-RestMethod`/`Invoke-WebRequest` disponibles (vienen en PS Core).

## Implementacion paso a paso

### Paso 1 - Validar la plantilla JSON localmente

```powershell
node -e "JSON.parse(require('fs').readFileSync('solutions/innova-flows/templates/flow-canonico-plantilla.json','utf8'))"
```

Si no arroja error, el JSON es valido.

### Paso 2 - Registrar via API

```powershell
pwsh ./scripts/flows/register-flow-template.ps1
```

Output esperado:

```
=== INNOVA: Registrar flow plantilla en DEV ===
[1/4] Obteniendo token SP...
  Token OK
[2/4] Resolviendo solution + owner...
  Solution: <guid>
  Owner (SP user): <guid>
[3/4] Buscando workflow existente...
  No existe. Creando...
  Creado: <workflowid>
[4/4] Verificando...
  statecode  : 0 (Draft; activar manualmente)
```

El flow queda en estado **Draft** (statecode=0) porque la activacion via SP es problematica para triggers manuales: requiere validar la conexion del trigger que es user-context. El owner humano debe activarlo.

### Paso 3 - Activar el flow (manual, una vez)

1. Abrir <https://make.powerautomate.com/>.
2. Environments -> seleccionar DEV.
3. Solutions -> `innova_core`.
4. Buscar "INNOVA - Plantilla - Patron Estandar".
5. Edit (icono lapiz) -> verificar la estructura visual: deben aparecer los 4 scopes con la indentacion correcta.
6. Save (si pide).
7. Volver a la lista de la solution -> el flow -> **Turn on**.

### Paso 4 - Test de los 3 escenarios

#### Opcion A - Manual desde el panel Test

1. En el editor del flow -> **Test** (esquina sup. derecha).
2. **Manually** -> **Test**.
3. Pegar el JSON de cada escenario (ver mas abajo) y click **Run flow**.
4. Verificar el resultado de cada scope en la vista de run.

#### Opcion B - Via HTTP POST URL

1. En el editor -> click en el trigger Manual.
2. Settings (panel derecho) -> copiar **HTTP POST URL**.
3. Ejecutar:

```powershell
pwsh ./scripts/flows/test-flow-template.ps1 -TriggerUrl '<la URL copiada>'
```

El script POSTea los 3 payloads en secuencia.

### Casos de prueba

#### Caso 1 - Camino feliz

Payload:

```json
{
  "Mensaje_de_prueba": "Test camino feliz - todos los scopes deberian completar OK",
  "Forzar_fallo_validacion": false,
  "Forzar_fallo_main": false
}
```

Resultado esperado:

| Scope | Status |
|---|---|
| Validations | Succeeded |
| Main Logic | Succeeded |
| Notifications | Succeeded |
| Error Handler | Skipped (run-after no se cumple) |
| **Run final** | **Succeeded** |

#### Caso 2 - Cancelado por validacion

Payload:

```json
{
  "Mensaje_de_prueba": "lo que sea",
  "Forzar_fallo_validacion": true,
  "Forzar_fallo_main": false
}
```

Resultado esperado:

| Scope | Status |
|---|---|
| Validations | Cancelled (por Terminate dentro del Condition) |
| Main Logic | Skipped |
| Notifications | Skipped |
| Error Handler | Skipped (run-after Failed/TimedOut, no Cancelled) |
| **Run final** | **Cancelled** |

Nota importante: el Error Handler **NO** corre cuando el run termina Cancelled.
Esto es por diseno: Cancelled = validacion fallo intencionalmente, no es un
error tecnico que merezca log. Si quisieramos loggear los cancelados, habria
que duplicar la condicion `Falla_de_validacion` con un Compose de log antes
del Terminate.

#### Caso 3 - Error tecnico

Payload:

```json
{
  "Mensaje_de_prueba": "Test error",
  "Forzar_fallo_validacion": false,
  "Forzar_fallo_main": true
}
```

Resultado esperado:

| Scope | Status |
|---|---|
| Validations | Succeeded |
| Main Logic | Failed (Compose `int('texto')` lanza error) |
| Notifications | Skipped (run-after Succeeded de Main, no se cumple) |
| Error Handler | Succeeded (sus actions corren, terminando con Terminate Failed) |
| **Run final** | **Failed** |

## Cierre ALM

1. Commit del JSON + scripts + esta documentacion.
2. Actualizar `CHANGELOG.md`.
3. PR con evidencia de los 3 escenarios ejecutados (capturas del Run history).

## Reusar la plantilla para flows nuevos

Para crear un flow nuevo derivado:

1. Identificar el nombre canonico: ver [docs/conventions/power-automate-style.md](../conventions/power-automate-style.md).
2. Copiar `solutions/innova-flows/templates/flow-canonico-plantilla.json` a una ubicacion temporal.
3. Renombrar `displayName` y `uniquename`.
4. Cambiar el trigger:
   - **Mantener Manual (PowerApps V2)** si el flow se invoca desde Canvas App.
   - **Reemplazar por trigger Dataverse** ("When a row is added/modified/deleted") si reacciona a cambios en la BD.
   - **Reemplazar por trigger Scheduler** ("Recurrence") si es un flow recurrente.
5. **No tocar los 4 scopes ni los run-after.**
6. Reemplazar los 2 Compose marcados `// TODO real`:
   - El de Notifications -> Office365 Send Email V2 o Workflow (child flow `INNOVA - Helper - Enviar Correo con Plantilla`).
   - El de Error Handler -> 2 acciones: Add row a `pas_errorlog` + Send Email V2 al admin.
7. Agregar `retryPolicy` Fixed 10s x 4 a cada accion externa nueva.
8. Validar JSON.
9. Registrar (manualmente via maker portal o adaptando el script de registro).
10. Probar los 3 escenarios obligatorios.

## Definition of Done para esta historia

- Plantilla JSON valida y comentada.
- Script de registro idempotente que funciona en DEV.
- Script de test que cubre los 3 escenarios.
- Runbook (este documento) con el procedimiento completo.
- README del template folder con resumen de uso.

## Riesgos conocidos

- **Activacion via SP**: Dataverse rechaza activar (statecode=1) un flow Modern via SP cuando el trigger es Manual. Workaround: activar humano una vez tras registro. No bloquea reproducibilidad.
- **`category=5` no oficialmente documentado para POST workflows**: Microsoft documenta el patron para Classic Workflows (category=0). Modern Flow se acepta empirically pero podria romperse en versiones futuras. Si falla, ver fallback en el output del script de registro (importar via package en maker portal).
- **El JSON `clientdata` es opaco**: Si Microsoft cambia el formato interno (poco probable en 4.x pero posible), habria que regenerar la plantilla exportando un flow real de la misma version.

## Siguiente paso sugerido

Crear el primer flow derivado: `INNOVA - Iniciativa Creada - Notificar PMO`
(runbook 08, historia piloto). Reusa esta plantilla cambiando solo el trigger
y los 2 Compose `// TODO real`.
