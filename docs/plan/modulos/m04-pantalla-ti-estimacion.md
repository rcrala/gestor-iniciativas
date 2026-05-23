# M4 — Pantalla TI Estimación (#3)

> **Pantalla**: #3 del análisis funcional
> **Tablas principales**: `pas_evaluacionti`, `pas_horatrabajo`
> **Stream**: `canvas` + `flows`
> **Condicional**: Solo se activa si la evaluación PMO marcó "Requiere Desarrollo = Sí"

## Objetivo de negocio

Permitir al equipo de TI estimar el esfuerzo de desarrollo cuando la iniciativa requiere software, devolviendo horas, costo y supuestos al PMO.

## Historias de usuario (issues GitHub)

### M4-H1 — Pantalla TI: lista de iniciativas pendientes de estimación

| Campo | Contenido |
|---|---|
| **Objetivo** | TI ve solo iniciativas en estado "En Evaluación TI" |
| **Alcance** | Canvas screen análoga a M3-H1, filtrada por estado y por BU si aplica |
| **Criterios de aceptación** | (1) Solo iniciativas correctas. (2) Información del PMO visible (resumen del levantamiento) |
| **Validaciones** | Smoke test |
| **Riesgos** | (mismos que M3-H1) |
| **Labels** | `activity`, `p0`, `canvas` |

### M4-H2 — Pantalla TI: registrar estimación (horas, costo, supuestos, riesgos técnicos)

| Campo | Contenido |
|---|---|
| **Objetivo** | Capturar la estimación con horas por tipo de recurso, costo total, supuestos críticos y riesgos técnicos |
| **Alcance** | Canvas con secciones. `Patch()` a `pas_evaluacionti`. Horas de estimación se registran en `pas_horatrabajo` con tipo "Estimación TI" |
| **Criterios de aceptación** | (1) Estimación completa capturada. (2) Costo calculado con tarifa parametrizable. (3) Botón "Devolver al PMO" funciona |
| **Validaciones** | Test funcional con caso simple y complejo |
| **Riesgos** | Tarifas múltiples por tipo de recurso. Mitigación: tabla de tarifas en parámetros |
| **Labels** | `activity`, `p0`, `canvas`, `core` |

### M4-H3 — Flow: cambio de estado tras estimación TI

| Campo | Contenido |
|---|---|
| **Objetivo** | Cuando TI completa la estimación, devolver al PMO para que la Jefatura apruebe |
| **Alcance** | Flow Update sobre `pas_evaluacionti` → cambiar estado iniciativa a "Pendiente Aprobación Jefatura" + notificar Jefatura del Solicitante (BU-aware) |
| **Criterios de aceptación** | (1) Estado correcto. (2) Notificación a la Jefatura adecuada. (3) Iniciativa visible para la Jefatura |
| **Validaciones** | Test con 2 BUs distintas |
| **Riesgos** | Resolución de "Jefatura del Solicitante" cuando hay cambios de organigrama. Mitigación: lookup vivo en Entra ID, no cache |
| **Labels** | `activity`, `p0`, `flows` |

## Tablas Dataverse tocadas

- `pas_iniciativa` (Update)
- `pas_evaluacionti` (Create, Update)
- `pas_horatrabajo` (Create)

## Flows requeridos

- `INNOVA - Estimacion TI Completa - Notificar Jefatura`

## Dependencias previas

- M3 cerrado (debe existir la transición desde evaluación PMO)
- Parámetro `Tarifa Hora TI` configurado

## Criterios de aceptación globales del módulo

- TI ve iniciativas que requieren su estimación
- Estimación queda registrada con costo
- Iniciativa pasa a Jefatura para aprobación

## Riesgos

- Volumen alto de estimaciones que saturen a TI. Mitigación: SLA configurable + reportería de carga
- Estimaciones inconsistentes entre desarrolladores. Mitigación: checklist en la pantalla

## Definition of Done

- 3 historias cerradas
- Solutions exportadas
- Runbook `docs/runbooks/m04-ti-estimacion.md`
- Tests documentados
- Demo al equipo TI
