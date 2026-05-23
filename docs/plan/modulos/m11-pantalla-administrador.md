# M11 — Pantalla Administrador

> **Pantalla**: dedicada
> **Tablas principales**: `pas_parametro`, `pas_centrocosto`, `pas_plantillacorreo`, `pas_miembrocomite`
> **Stream**: `canvas`

## Objetivo de negocio

Permitir al Administrador del sistema mantener los catálogos y parámetros sin necesidad de pasar por el equipo de desarrollo.

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

- Sprint 0 cerrado
- Paralelizable: puede empezar tan pronto como `innova-core` tenga las tablas

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
