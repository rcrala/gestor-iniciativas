# Test Plan: INNOVA - Iniciativa Creada - Notificar PMO

> **Tipo**: flow
> **Artefacto**: [`solutions/innova-flows/flows/INNOVA-iniciativa-creada-notificar-pmo.json`](../../solutions/innova-flows/flows/INNOVA-iniciativa-creada-notificar-pmo.json)
> **Issue / PR origen**: #55 / PR #56 (S1-01, primer flow derivado de plantilla #19)
> **Ultima ejecucion**: pendiente del usuario (post-merge + register + activacion manual)
> **Resultado**: N/A

## Resumen

Cuando se crea una `pas_iniciativa` (cualquier registro nuevo), el flow envia
correo al equipo PMO usando la plantilla `iniciativa_creada_pmo` con los
tokens `{consecutivo}`, `{titulo}`, `{solicitante}`, `{urlIniciativa}` sustituidos.

**Trigger actual**: Dataverse `When a row is added` sobre `pas_iniciativa`,
scope Organization. **No** se filtra por estado (al MVP, todo Create se notifica).
Cuando el plug-in de estados (issue #51, deploy-blocked) este activo y el Canvas
App distinga Save-draft vs Submit, este flow puede evolucionar a trigger
`When a row is modified` con filtro `pas_estado = 100000001 (Revision PMO)`.

## Precondiciones

- Environment: dev (URL en `.env.dev`)
- Service Principal configurado (PR #48)
- Solution `innova_core` con:
  - Plantilla activa: `pas_plantillacorreo` con `pas_nombre_clave='iniciativa_creada_pmo'` y `pas_activa=true` (seedeada en PR #52)
  - Parametros: `PmoDestinatariosCorreo`, `AdminCorreo`, `UrlBaseApp` en `pas_parametro` (seed con `scripts/setup/09-seed-parametros-notificaciones.ps1`)
  - Connection References: `pas_innova_dataverse` (Dataverse) y `pas_innova_office365` (Office 365 Outlook)
- Flow registrado y activado (Turn on manual en maker portal post-registro)

## Casos de prueba

### Caso 1 - Camino feliz

**Objetivo**: validar que crear una iniciativa con datos completos dispara el correo al PMO.

**Pasos**:

1. Confirmar que el flow esta activado en maker portal -> Solutions -> innova_core -> el flow.
2. Crear iniciativa via Web API (script o curl), con titulo + solicitante + empresa validos:

```powershell
pwsh ./scripts/plugins/smoke-test-consecutivo.ps1
# Reusa el script que crea una iniciativa con consecutivo asignado automaticamente.
# Devuelve el id de la iniciativa creada.
```

3. En menos de 2 minutos:
   - Verificar inbox del correo en `PmoDestinatariosCorreo` (default `pmo@grupopasqui.com` placeholder; ajustar)
   - Verificar Run history del flow: status final `Succeeded`

**Esperado**:

| Scope | Status |
|---|---|
| Validations | Succeeded |
| Main Logic | Succeeded |
| Notifications | Succeeded (correo enviado) |
| Error Handler | Skipped |
| **Run final** | **Succeeded** |

Y en el correo:

- Asunto: contiene `[INNOVA] Nueva iniciativa requiere evaluacion - <consecutivo>` (ej. `EMA-2026-005`)
- Cuerpo HTML: el de la plantilla `iniciativa_creada_pmo` con todos los tokens reemplazados (sin `{consecutivo}` literal, sin `{titulo}` literal, etc.)
- Link "Ver iniciativa": URL construida como `<UrlBaseApp> + <iniciativaId>` (placeholder por ahora, real cuando exista el Canvas App)

**Evidencia**:

- Screenshot del inbox con el correo (no enmascarar nombre de iniciativa)
- Link del Run history (URL completa del flow run)
- Query OData: `pas_iniciativas(<id>)?$select=pas_consecutivo,pas_titulo,_pas_solicitante_value`

**Resultado**: pendiente

---

### Caso 2 - Validacion falla (datos minimos faltantes)

**Objetivo**: validar que iniciativas sin titulo o sin solicitante NO disparan correo.

**Pasos**:

1. Crear iniciativa via API sin `pas_titulo` (saltea la validacion de NotNull si la columna lo permite — probar con `pas_titulo=""` o nulo):

```powershell
$body = @{
    pas_titulo = ""
    'pas_empresa@odata.bind' = "/pas_empresas(<empresaId>)"
    'pas_solicitante@odata.bind' = "/systemusers(<userId>)"
} | ConvertTo-Json
# POST a /api/data/v9.2/pas_iniciativas
```

2. Si el plug-in de consecutivo asigna `pas_consecutivo` igualmente, el flow se disparara.
3. En Run history:

**Esperado**:

| Scope | Status |
|---|---|
| Validations | Cancelled (Terminate dentro del Condition) |
| Main Logic | Skipped |
| Notifications | Skipped |
| Error Handler | Skipped (run-after Failed/TimedOut, NO Cancelled) |
| **Run final** | **Cancelled** |

- NO se envia correo al PMO
- NO se dispara Error Handler (Cancelled NO es error tecnico)
- El runError muestra el detalle de que campo fallo

**Resultado**: pendiente

**Notas**: si `pas_titulo` es Required en el schema, el Create fallara antes del trigger (no llegara al flow). Para reproducir este caso, temporalmente cambiar el atributo a optional, o usar una version donde haya Borrador permitido sin titulo.

---

### Caso 3 - Error tecnico (plantilla inactiva o conexion Office365 caida)

**Objetivo**: validar que el Error Handler corre y notifica al admin cuando hay un error tecnico.

**Pasos**:

1. Desactivar la plantilla:

```powershell
# Patch pas_plantillacorreo set pas_activa=false where pas_nombre_clave='iniciativa_creada_pmo'
```

2. Crear iniciativa via API (datos validos).
3. El flow detectara plantilla faltante en Main Logic y forzara fallo (`@int('texto')` lanza error).
4. Error Handler corre, envia correo al admin.

**Esperado**:

| Scope | Status |
|---|---|
| Validations | Succeeded |
| Main Logic | Failed (Compose Forzar_fallo_plantilla_faltante) |
| Notifications | Skipped |
| Error Handler | Succeeded (correo admin enviado, Terminate Failed) |
| **Run final** | **Failed** |

- Inbox del admin (`AdminCorreo`, default `admin@grupopasqui.com`) recibe correo con asunto `[INNOVA-ERROR] Fallo en flow Notificar PMO - Run <id>` y body con el detalle JSON.

**Limpieza**: reactivar la plantilla (`pas_activa=true`).

**Resultado**: pendiente

---

## Cobertura

- [ ] Camino feliz (correo enviado + Run Succeeded)
- [ ] Validacion fallida (Run Cancelled, no correo)
- [ ] Error tecnico (Error Handler corre, admin notificado, Run Failed)
- [ ] Idempotencia: re-registrar el flow (segundo run de `register-iniciativa-creada-notificar-pmo.ps1`) NO crea duplicado, hace PATCH
- [ ] Tokens: TODOS reemplazados (search en cuerpo HTML por `{`, no debe encontrar tokens literales si la plantilla esta completa)
- [ ] Retry policy: simular timeout en Send Email V2 (no trivial) — verificar que reintenta 4 veces antes de fallar

## Notas

- El flow esta registrado pero **NO activado** automaticamente por el script (la activacion via SP de triggers Dataverse es problematica). Activacion manual obligatoria post-registro.
- Las connection references deben existir previo al registro. Si el script de registro reporta WARN sobre ellas, crearlas en maker portal y re-ejecutar.
- Cuando exista tabla `pas_errorlog`, agregar paso "Add row a pas_errorlog" en Error Handler antes del Send Email.

## Issues encontrados durante el test

(pendiente del usuario al ejecutar)

## Riesgos conocidos

- **Loop de notificaciones**: si la accion del Error Handler de este flow falla (ej. Send Email tambien cae), el run termina Failed sin notificar nadie. Mitigacion futura: Error Handler con `runAfter` que incluye Failed del Send Email del propio Error Handler -> Compose log adicional.
- **Cancelled no notifica**: Cancelled NO dispara Error Handler. Si queremos loggear validaciones fallidas, agregar Compose log antes de cada Terminate Cancelled (no agregado en esta version porque inflaria el JSON sin valor para MVP).
