# Runbook 08 - Historia Piloto: Notificacion PMO al crear iniciativa

## Objetivo

Implementar y validar la historia:

Como PMO, quiero recibir una notificacion cuando se cree una iniciativa para iniciar evaluacion.

Este runbook estandariza el flujo de trabajo para la primera historia en `innova-flows`.

## Alcance

- Crear flow top-level en Power Automate.
- Trigger en Dataverse sobre creacion de `pas_iniciativa`.
- Notificar al equipo PMO por correo usando patron de proyecto.
- Dejar manejo de errores y evidencia de pruebas.

Fuera de alcance:
- Aprobaciones desde Teams.
- Cambios de modelo de datos no documentados.

## Referencias obligatorias

- [CLAUDE.md](../../CLAUDE.md)
- [docs/architecture/00-overview.md](../architecture/00-overview.md)
- [docs/conventions/power-automate-style.md](../conventions/power-automate-style.md)
- [docs/conventions/dataverse-naming.md](../conventions/dataverse-naming.md)
- [solutions/innova-flows/README.md](../../solutions/innova-flows/README.md)
- [tests/README.md](../../tests/README.md)

## Prerrequisitos

1. Acceso a Power Apps y Power Automate en ambiente DEV.
2. Permisos sobre la solution `innova-flows`.
3. Conexion Dataverse disponible en DEV.
4. Si se usa PAC CLI local, autenticacion activa:
   - `pac auth list`
   - `pac auth select --name innova-dev`

## Convenciones obligatorias

- Nombre del flow: `INNOVA - Iniciativa Creada - Notificar PMO`
- Estructura por scopes:
  - `Scope - Validations`
  - `Scope - Main Logic`
  - `Scope - Notifications`
  - `Scope - Error Handler`
- No hardcodear GUIDs, tenant IDs ni secretos.
- Usar Connection References de la solution.

## Implementacion paso a paso

### Paso 1 - Crear flow top-level

1. Abrir la solution `innova-flows` en maker portal.
2. Crear cloud flow automatizado con trigger Dataverse:
   - Trigger: When a row is added
   - Table name: `pas_iniciativa`
   - Scope: Organization (segun permisos del conector)
3. Asignar nombre exacto: `INNOVA - Iniciativa Creada - Notificar PMO`.

### Paso 2 - Scope Validations

1. Crear `Scope - Validations`.
2. Validar que el registro tenga datos minimos para notificar:
   - titulo/consecutivo no vacio
   - solicitante no vacio
3. Si falla, terminar ejecucion en estado Cancelled.

### Paso 3 - Scope Main Logic

1. Crear `Scope - Main Logic` con run after exitoso de Validations.
2. Construir payload base de notificacion con:
   - identificador de iniciativa
   - titulo
   - solicitante
   - fecha de creacion
3. Resolver destinatarios PMO por rol/grupo configurado.

### Paso 4 - Scope Notifications

1. Crear `Scope - Notifications` con run after exitoso de Main Logic.
2. Enviar correo de notificacion (directo o via child flow helper).
3. Aplicar retry policy en acciones externas (Fixed 10s x 4).

### Paso 5 - Scope Error Handler

1. Crear `Scope - Error Handler`.
2. Configurar run after cuando falle o expire cualquier scope previo.
3. Acciones minimas:
   - Compose con detalle del error
   - Registro en tabla de log de errores (si disponible)
   - Correo a administracion con referencia del run
   - Terminate Failed

## Casos de prueba

### Prueba 1 - Flujo feliz

1. Crear una iniciativa de prueba en DEV.
2. Confirmar que el flow se dispara una vez.
3. Confirmar envio de correo a PMO.
4. Guardar evidencia (captura de run + correo recibido).

Criterio de aceptacion:
- Notificacion enviada en menos de 2 minutos tras crear iniciativa.

### Prueba 2 - Datos faltantes

1. Forzar escenario con datos incompletos permitidos por el trigger.
2. Verificar salida por validacion con estado Cancelled.

Criterio de aceptacion:
- No hay envio de correo en escenario invalido.
- Queda trazabilidad del motivo.

### Prueba 3 - Error tecnico

1. Simular fallo en accion externa (por ejemplo, deshabilitar temporalmente conector en sandbox).
2. Verificar ejecucion de `Scope - Error Handler`.

Criterio de aceptacion:
- Se registra error y se notifica a admin.

## Cierre ALM

1. Exportar `innova-flows` desde DEV.
2. Desempaquetar en el repo.
3. Confirmar cambios de artefactos del flow en `solutions/innova-flows`.
4. Actualizar changelog y evidencia de pruebas.

Comandos de referencia:

```powershell
pac solution export --name innova-flows --path ./exported/innova-flows.zip
pac solution unpack --zipfile ./exported/innova-flows.zip --folder ./solutions/innova-flows --packagetype Unmanaged
```

## Definition of Done para esta historia

- Flow creado con naming y estructura oficiales.
- Manejo de errores aplicado.
- Pruebas minima feliz/invalida/error ejecutadas.
- Artefactos de solution versionados.
- Changelog actualizado.

## Siguiente historia sugerida

`INNOVA - Iniciativa Creada - Notificar Jefatura` reutilizando el mismo patron de scopes y validaciones.
