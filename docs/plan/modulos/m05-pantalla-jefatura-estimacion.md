# M5 — Pantalla Jefatura — Aprobación de Estimación (#4)

> **Pantalla**: #4 del análisis funcional
> **Tablas principales**: `pas_iniciativa` (decisión y prioridad)
> **Stream**: `canvas` + `flows`

## Objetivo de negocio

Permitir a la Jefatura del Solicitante revisar la evaluación PMO (+ estimación TI si aplica), asignar prioridad (P1/P2/P3), y decidir si aprueba, devuelve o rechaza la iniciativa.

## Historias de usuario (issues GitHub)

### M5-H1 — Pantalla Jefatura: bandeja de aprobación

| Campo | Contenido |
|---|---|
| **Objetivo** | La Jefatura ve solo las iniciativas en estado "Pendiente Aprobación Jefatura" de su BU |
| **Alcance** | Canvas screen con galería filtrada por BU y rol. Resumen de la iniciativa con evaluación PMO y estimación TI consolidados |
| **Criterios de aceptación** | (1) Filtros correctos. (2) Vista consolidada legible. (3) Permite abrir detalle |
| **Validaciones** | Test con usuario rol Jefatura en BU específica |
| **Riesgos** | Cambios en estructura organizacional. Mitigación: lookup vivo |
| **Labels** | `activity`, `p0`, `canvas` |

### M5-H2 — Pantalla Jefatura: registrar decisión + prioridad

| Campo | Contenido |
|---|---|
| **Objetivo** | Capturar la decisión (Aprobar / Devolver / Rechazar) y, si aprueba, la prioridad P1/P2/P3 con justificación |
| **Alcance** | Canvas con sección de decisión. `Patch()` a `pas_iniciativa`. Comentario obligatorio si devuelve o rechaza |
| **Criterios de aceptación** | (1) Las 3 decisiones funcionan. (2) Comentario requerido en casos negativos. (3) Prioridad obligatoria al aprobar |
| **Validaciones** | Test funcional con los 3 caminos |
| **Riesgos** | Sin justificación en aprobaciones. Mitigación: campo opcional pero recomendado en UI |
| **Labels** | `activity`, `p0`, `canvas` |

### M5-H3 — Flow: routing post-decisión Jefatura

| Campo | Contenido |
|---|---|
| **Objetivo** | Rutear la iniciativa según la decisión: Aprobada → PMO Cotizaciones; Devuelta → vuelve al PMO; Rechazada → estado final, notificar Solicitante |
| **Alcance** | Flow disparado por Update en `pas_iniciativa` con decisión Jefatura. Lógica de routing + notificaciones |
| **Criterios de aceptación** | (1) Estados correctos según decisión. (2) Notificaciones correctas. (3) Si rechazada, log de motivo |
| **Validaciones** | Test de las 3 transiciones |
| **Riesgos** | Loops de devolución infinitos. Mitigación: contador de devoluciones, alerta tras 3 |
| **Labels** | `activity`, `p0`, `flows` |

## Tablas Dataverse tocadas

- `pas_iniciativa` (Update: decisión Jefatura, prioridad, estado)

## Flows requeridos

- `INNOVA - Decision Jefatura - Routing`
- `INNOVA - Decision Jefatura - Notificar Solicitante`

## Dependencias previas

- M3 cerrado (M4 si requiere desarrollo)
- Resolución confiable de "Jefatura del Solicitante" (probablemente vía Entra ID manager attribute)

## Criterios de aceptación globales del módulo

- Jefatura aprueba/devuelve/rechaza en menos de 5 min por iniciativa
- Routing post-decisión funciona en los 3 casos
- Solicitante recibe notificación cuando aplica

## Riesgos

- Jefatura sin tiempo para revisar genera backlog. Mitigación: F3 recordatorios cada 3 días
- Conflicto entre prioridad asignada por Jefatura y prioridad del PMO. Mitigación: convención clara, prioridad de Jefatura prevalece

## Definition of Done

- 3 historias cerradas
- Solutions exportadas
- Runbook `docs/runbooks/m05-jefatura-estimacion.md`
- Tests documentados
- Demo a usuarios de Jefatura
