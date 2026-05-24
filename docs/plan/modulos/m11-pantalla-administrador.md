# M11 — Pantalla Administrador

> **Pantalla**: dedicada
> **Tablas principales**: `pas_parametro`, `pas_centrocosto`, `pas_plantillacorreo`, `pas_miembrocomite`, (potencialmente `pas_empresa`)
> **Stream**: `canvas`
> **Prioridad en el plan**: **alta** — paralelizable con M2 desde el cierre de Sprint 0. M11-H1 y M11-H4 son **prerequisitos para go-live** porque sin ellos el cliente no puede ajustar parámetros ni miembros del Comité tras el import.

## Objetivo de negocio

Permitir al Administrador del sistema mantener los catálogos y parámetros sin necesidad de pasar por el equipo de desarrollo. Materializa el principio arquitectónico: **datos del cliente son configurables, no codeados** (ver [m01-modelo-datos.md](m01-modelo-datos.md#principio-rector)).

## Historias de usuario (issues GitHub)

### M11-H1 — Mantenimiento de parámetros del sistema

| Campo | Contenido |
|---|---|
| **Objetivo** | CRUD de `pas_parametro` (umbral de escalamiento, tarifas hora PMO/TI, días de recordatorio, etc.) |
| **Alcance** | Canvas con galería + form. Validación de tipos (numérico, string, fecha) |
| **Criterios de aceptación** | (1) CRUD funcional. (2) Audit log de cambios. (3) Solo rol Administrador accede |
| **Validaciones** | Test CRUD con cada tipo |
| **Riesgos** | Cambio de umbral con iniciativas en flight. Mitigación: aviso y log |
| **Labels** | `activity`, `p1`, `canvas` |

### M11-H2 — Mantenimiento de centros de costo

| Campo | Contenido |
|---|---|
| **Objetivo** | CRUD de `pas_centrocosto` |
| **Alcance** | Canvas estándar |
| **Criterios de aceptación** | (1) CRUD. (2) No eliminar si hay horas asociadas (soft delete) |
| **Validaciones** | Test borrado bloqueado |
| **Riesgos** | — |
| **Labels** | `activity`, `p2`, `canvas` |

### M11-H3 — Mantenimiento de plantillas de correo

| Campo | Contenido |
|---|---|
| **Objetivo** | CRUD de `pas_plantillacorreo` con asunto, cuerpo HTML, variables sustituibles |
| **Alcance** | Canvas con editor de texto enriquecido (o HTML plano si Power Apps no lo soporta). Vista previa con sustitución de variables |
| **Criterios de aceptación** | (1) CRUD. (2) Variables documentadas. (3) Preview funcional |
| **Validaciones** | Test envío con cada plantilla |
| **Riesgos** | Variables mal escritas rompen flows. Mitigación: validación + test de render |
| **Labels** | `activity`, `p1`, `canvas`, `flows` |

### M11-H4 — Mantenimiento de miembros del Comité

| Campo | Contenido |
|---|---|
| **Objetivo** | CRUD de `pas_miembrocomite` incluyendo titular, suplente, fechas de vigencia |
| **Alcance** | Canvas con lookups a usuarios Entra ID |
| **Criterios de aceptación** | (1) CRUD. (2) Solo activa el miembro si tiene suplente definido. (3) Vigencia respetada |
| **Validaciones** | Test con miembro fuera de vigencia |
| **Riesgos** | Comité sin quórum por error administrativo. Mitigación: alerta al admin |
| **Labels** | `activity`, `p1`, `canvas` |

## Tablas Dataverse tocadas

- `pas_parametro`, `pas_centrocosto`, `pas_plantillacorreo`, `pas_miembrocomite` (CRUD)

## Flows requeridos

- (Opcional) `INNOVA - Auditoria - Log Cambios Catalogos` si Dataverse audit no es suficiente

## Dependencias previas

- Sprint 0 cerrado (`innova-core` con las tablas creadas en S0-4)
- **Paralelizable con M2 desde el día 1 del Sprint 1** — no esperar al final

## Orden recomendado dentro de M11

Por prioridad de go-live, no por orden numérico de historias:

1. **M11-H1** (parámetros) — `p1`, **prerequisito de go-live** (cliente debe poder ajustar umbral y tarifas)
2. **M11-H4** (miembros Comité) — `p1`, **prerequisito de go-live** (Comité no funciona sin sus miembros configurados)
3. **M11-H3** (plantillas correo) — `p1`, mejora UX pero saltable al inicio (cliente puede vivir con plantillas seed por unas semanas)
4. **M11-H2** (centros de costo) — `p2`, se puede gestionar via maker portal por un tiempo

## Criterios de aceptación globales del módulo

- Administrador opera autosuficiente sin tocar el equipo de desarrollo
- Cambios trazables y auditables

## Riesgos

- Errores de configuración con impacto en producción. Mitigación: roles separados, confirmaciones, audit log

## Definition of Done

- 4 historias cerradas
- Solutions exportadas
- Runbook
- Tests
- Demo a Administrador piloto
