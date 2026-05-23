# M12 — Tracking "Mis Solicitudes" (transversal)

> **Pantalla**: transversal (accesible desde el home de cada rol)
> **Tablas principales**: `pas_iniciativa` (Read)
> **Stream**: `canvas`

## Objetivo de negocio

Que cualquier usuario pueda ver el estado actualizado de las iniciativas en las que participa (como Solicitante, Patrocinador, Colaborador, Aprobador) sin tener que contactar al PMO.

## Historias de usuario (issues GitHub)

### M12-H1 — Pantalla "Mis Solicitudes": galería filtrada por mi rol en la iniciativa

| Campo | Contenido |
|---|---|
| **Objetivo** | Mostrar iniciativas donde el usuario actual aparece en algún campo de participación (creador, sponsor, colaborador, aprobador pendiente) |
| **Alcance** | Canvas con galería + filtros (estado, mi rol, fecha). Cada item navegable al detalle |
| **Criterios de aceptación** | (1) Solo muestra iniciativas relevantes al usuario. (2) Filtros funcionan. (3) Performance aceptable |
| **Validaciones** | Test con usuario que participa en 0, 1, 10+ iniciativas |
| **Riesgos** | Query no delegable. Mitigación: usar Dataverse Views con FetchXML server-side |
| **Labels** | `activity`, `p1`, `canvas` |

### M12-H2 — Detalle de iniciativa "vista pública" (read-only por estado)

| Campo | Contenido |
|---|---|
| **Objetivo** | El usuario puede entrar al detalle de su iniciativa y ver evaluación, estimación, decisiones, ejecución y resultado final en modo lectura |
| **Alcance** | Canvas screen con tabs análogos a M6-H1 pero read-only y con respeto a FLS (oculta cotizaciones si no es PMO, etc.) |
| **Criterios de aceptación** | (1) Vista respeta FLS. (2) Estado del proceso visible (timeline). (3) No permite editar |
| **Validaciones** | Test con 5 roles distintos |
| **Riesgos** | Filtración de información sensible. Mitigación: FLS estricto por rol |
| **Labels** | `activity`, `p1`, `canvas` |

### M12-H3 — Notificaciones push de cambios de estado a usuarios participantes

| Campo | Contenido |
|---|---|
| **Objetivo** | Cuando una iniciativa cambia de estado, notificar por correo a todos los participantes (no solo al aprobador siguiente) |
| **Alcance** | Flow disparado por Update de estado en `pas_iniciativa`. Compone lista de destinatarios + envía correo con resumen y link |
| **Criterios de aceptación** | (1) Notifica a todos los participantes. (2) Sin duplicados. (3) Configurable por usuario (opt-out) |
| **Validaciones** | Test con varios cambios consecutivos |
| **Riesgos** | Spam. Mitigación: consolidar varias notificaciones en una si pasan en <X min |
| **Labels** | `activity`, `p2`, `flows` |

## Tablas Dataverse tocadas

- `pas_iniciativa` (Read)
- (potencial) `pas_notificacion_preferencia` por usuario (decidir en Sprint 0 si modelarla)

## Flows requeridos

- `INNOVA - Cambio Estado - Notificar Participantes`

## Dependencias previas

- M2 cerrado (debe existir al menos un caso)
- Paralelizable con M3-M11

## Criterios de aceptación globales del módulo

- Usuarios consultan estado sin contactar PMO
- Notificaciones útiles (no spam)

## Riesgos

- Performance con miles de iniciativas. Mitigación: índices Dataverse, paginación
- Definición de "participante" no consensuada. Mitigación: workshop antes de M12

## Definition of Done

- 3 historias cerradas
- Solutions exportadas
- Runbook
- Tests
- Demo a usuarios piloto
