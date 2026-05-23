# Estilo de Power Automate

## Naming de flows

| Tipo | Patrón | Ejemplo |
|---|---|---|
| Top-level | `INNOVA - <Trigger> - <Purpose>` | `INNOVA - Iniciativa Creada - Notificar PMO` |
| Child flow | `INNOVA - Helper - <Purpose>` | `INNOVA - Helper - Enviar Correo con Plantilla` |
| Scheduled | `INNOVA - Scheduler - <Purpose>` | `INNOVA - Scheduler - Recordatorios Cada 3 Días` |

## Patrón estándar de flow

```
1. Trigger (Dataverse Create/Update sobre pas_iniciativa)
2. Initialize Variables (si hay state cross-action)
3. Scope: Validations
   - Validar precondiciones
   - Si falla, terminar con Cancelled
4. Scope: Main Logic
   - Lógica de negocio principal
   - Run after: solo si Validations = Succeeded
5. Scope: Notifications
   - Llamar child flow para correos y Teams
   - Run after: solo si Main Logic = Succeeded
6. Scope: Error Handling
   - Log a tabla de errores
   - Notificación a admin
   - Run after: cualquier scope = Failed o TimedOut
```

## Conexiones

- **Service principal** para Dataverse connector en QA y PROD
- Connection References explícitas en cada solution
- Nunca usar cuentas personales en flows productivos

## Manejo de errores

Cada acción externa (HTTP, Outlook, Teams, SharePoint) DEBE:

- Estar dentro de un `Scope` con `Configure run after`
- Tener retry policy: Fixed 10s × 4 (default), o exponencial para servicios sensibles
- Loggear en caso de fallo

Ejemplo de scope de errores:

```
Scope: Error Handler
  Configure run after: Main Logic has failed | timed out
  Actions:
    - Compose: serialize error details
    - Add row to "pas_errorlog" table
    - Send email to admin (with link to flow run history)
    - Terminate: Failed
```

## Plantillas de correo

- Almacenadas en la tabla `pas_plantillacorreo`
- Tokens entre llaves: `{Iniciativa.Titulo}`, `{Aprobador.Nombre}`, `{URL.Pantalla}`
- Child flow `INNOVA - Helper - Enviar Correo con Plantilla` reemplaza tokens y envía

## Notificaciones a Teams

- Adaptive Cards con deep links a la pantalla relevante de Power Apps
- Botones de acción rápida solo para "Ver detalle" — la aprobación se hace en la app, no en Teams (mantiene auditabilidad)

## Recordatorios cada 3 días

- Scheduled flow corriendo diariamente a las 8:00 AM
- Consulta iniciativas en estado de espera por más de 3 días
- Consolida por aprobador (un correo por persona con todos sus pendientes, no uno por iniciativa)
- Esto evita saturación y mejora la experiencia del aprobador
