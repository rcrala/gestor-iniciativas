# Plantilla canonica de Power Automate flow (issue #19, S0-8)

Esta carpeta contiene la **plantilla canonica** que TODO flow nuevo de INNOVA debe copiar.

> **NO modificar `flow-canonico-plantilla.json` directamente.**
> Copialo a otra ubicacion, renombra, y empieza a trabajar sobre la copia.

## Estructura canonica

El patron viene del runbook 08 y la convencion oficial:

- `Scope - Validations` -> valida precondiciones; termina `Cancelled` si fallan
- `Scope - Main Logic` -> logica de negocio principal; run-after `Succeeded` de Validations
- `Scope - Notifications` -> envia correos/Teams; run-after `Succeeded` de Main Logic
- `Scope - Error Handler` -> log + correo admin + `Terminate Failed`; run-after `Failed`/`TimedOut` de cualquiera de los 3 anteriores

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
       (fin OK)                 (log + correo + Terminate Failed)
```

## Inputs de la plantilla

La plantilla usa **trigger Manual (PowerApps V2)** para ser testeable sin Dataverse trigger. Acepta 3 parametros:

| Parametro | Tipo | Para que sirve |
|---|---|---|
| `Mensaje_de_prueba` | string (requerido) | Texto que se incluye en el payload. Si vacio -> Cancelled. |
| `Forzar_fallo_validacion` | bool (default false) | true -> Terminate Cancelled en Validations |
| `Forzar_fallo_main` | bool (default false) | true -> error en Main Logic, dispara Error Handler |

Con estos 3 parametros se cubren los **3 escenarios obligatorios** del runbook 08:

1. **Camino feliz**: `Mensaje_de_prueba='hola'`, demas en false -> completa los 4 scopes Validations + Main + Notifications, Error Handler NO se ejecuta (run-after no se cumple).
2. **Cancelado por validacion**: `Mensaje_de_prueba=''` o `Forzar_fallo_validacion=true` -> Validations Terminate Cancelled, demas scopes no corren.
3. **Error tecnico**: `Forzar_fallo_main=true` -> Compose `@int('texto-no-numero')` lanza error, Main Logic Failed, Error Handler corre y Terminate Failed.

## Como usar para crear un flow nuevo

### Opcion A - Copiar la plantilla (recomendado)

1. Decidir nombre del flow nuevo segun [docs/conventions/power-automate-style.md](../../../docs/conventions/power-automate-style.md). Ejemplo: `INNOVA - Iniciativa Creada - Notificar PMO`.
2. Crear flow vacio en maker portal de la solution `innova-flows`.
3. En el editor del flow, ir a Settings -> "Switch to JSON view" (si esta disponible) o exportar el flow vacio, editarlo y reimportarlo.
4. Pegar el `definition` de `flow-canonico-plantilla.json`.
5. Cambiar el trigger:
   - Manual (PowerApps V2) -> mantener si es flow disparado desde Canvas App.
   - Dataverse "When a row is added/modified/deleted" -> reemplazar el `triggers.manual` por el trigger Dataverse correspondiente.
6. Reemplazar los Compose marcados `// TODO real` por las acciones reales:
   - `Compose_-_TODO_real_Send_email_o_child_flow` -> Office365 Send Email V2 o Workflow (child flow `INNOVA - Helper - Enviar Correo con Plantilla`).
   - `Compose_-_TODO_real_log_a_pas_errorlog_y_correo_admin` -> 2 acciones: Add row a `pas_errorlog` + Send Email V2 al admin.
7. Aplicar `retryPolicy` Fixed 10s x 4 a TODA accion externa nueva (la plantilla ya documenta la estructura).
8. Guardar, activar, probar con los 3 escenarios.

### Opcion B - Deploy directo de la plantilla via script

Para tener la plantilla EN VIVO en DEV (util para revisar el estructura visualmente en el editor):

```powershell
pwsh ./scripts/flows/register-flow-template.ps1
```

El script usa el Web API de Dataverse + Service Principal (`.env.dev`) para crear la row en `workflow` con `clientdata` = contenido del JSON. Idempotente: si ya existe, hace PATCH.

Luego para probar los 3 escenarios:

```powershell
pwsh ./scripts/flows/test-flow-template.ps1
```

## Convenciones obligatorias en cada flow derivado

- `runAfter` explicito en cada scope (no quedarse con `{}` excepto en el primero).
- Nombres descriptivos: NUNCA dejar `Compose 2`, `Condition`, `Send_an_email`.
- Underscores en lugar de espacios en los `actionName` keys (Logic Apps no admite espacios).
- Usar `triggerBody()?['CampoX']` para inputs del trigger (NUNCA tokens dinamicos del designer si el flow se serializa).
- `coalesce(..., default)` para inputs opcionales del trigger.
- `metadata.operationMetadataId` ayuda a la trazabilidad si se hacen merges; puede dejarse vacio.
- Connection References: definirlas en `properties.connectionReferences` cuando se agreguen conectores reales; nunca embeber `connectionId` directo.

## Cuando NO copiar esta plantilla

Si el flow es un **child flow** (`INNOVA - Helper - ...`) con responsabilidad unica (ej. envio de correo con plantilla), los 4 scopes son excesivos. En su lugar usar:

```
Trigger (Request - Manually from a flow)
Scope - Main Logic
Scope - Error Handler (run-after Failed/TimedOut de Main Logic)
Response (Status: 200 con el resultado / 500 con el error)
```

Validations + Notifications no aplican porque el caller (parent flow) ya valido y notifica.

## Referencias

- [Runbook 08 - Historia piloto notificacion PMO](../../../docs/runbooks/08-historia-piloto-notificacion-pmo.md)
- [Runbook 09 - Plantilla canonica](../../../docs/runbooks/09-flow-template-canonico.md)
- [Convencion Power Automate Style](../../../docs/conventions/power-automate-style.md)
