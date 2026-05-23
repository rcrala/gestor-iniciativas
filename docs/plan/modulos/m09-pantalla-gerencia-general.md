# M9 — Pantalla Gerencia General (#8)

> **Pantalla**: #8 del análisis funcional
> **Tablas principales**: `pas_iniciativa`
> **Stream**: `canvas` + `flows`

## Objetivo de negocio

Permitir a la Gerencia General aprobar iniciativas cuyo monto está bajo el umbral de escalamiento, sin necesidad de pasar por Comité.

## Historias de usuario (issues GitHub)

### M9-H1 — Pantalla Gerencia General: bandeja de aprobación

| Campo | Contenido |
|---|---|
| **Objetivo** | Gerencia General ve iniciativas en estado "Pendiente Gerencia General" |
| **Alcance** | Canvas screen con galería filtrada. Vista de resumen completo (evaluación + estimación + cotización ganadora + ejecución) |
| **Criterios de aceptación** | (1) Filtro correcto. (2) Vista consolidada. (3) Acceso solo con rol `INNOVA Gerencia` |
| **Validaciones** | Test con usuario rol Gerencia |
| **Riesgos** | Sobrecarga visual. Mitigación: tabs |
| **Labels** | `activity`, `p0`, `canvas` |

### M9-H2 — Pantalla Gerencia General: aprobar/rechazar con comentario

| Campo | Contenido |
|---|---|
| **Objetivo** | Capturar decisión de Gerencia: Aprobar o Rechazar, con comentario obligatorio si rechaza |
| **Alcance** | Canvas con sección decisión. `Patch()` a `pas_iniciativa` con estado final |
| **Criterios de aceptación** | (1) Ambas decisiones funcionan. (2) Comentario obligatorio en rechazo |
| **Validaciones** | Test ambos caminos |
| **Riesgos** | — |
| **Labels** | `activity`, `p0`, `canvas` |

### M9-H3 — Flow: decisión Gerencia General → cierre

| Campo | Contenido |
|---|---|
| **Objetivo** | Si Aprobada → estado "Aprobada" final + notificar Solicitante + PMO; si Rechazada → estado "Rechazada" + notificar |
| **Alcance** | Flow Update sobre `pas_iniciativa.decision_gerencia` |
| **Criterios de aceptación** | (1) Estado final correcto. (2) Notificaciones correctas |
| **Validaciones** | Test ambos caminos |
| **Riesgos** | — |
| **Labels** | `activity`, `p0`, `flows` |

## Tablas Dataverse tocadas

- `pas_iniciativa` (Update)

## Flows requeridos

- `INNOVA - Decision Gerencia - Cierre`

## Dependencias previas

- M7 cerrado (debe poder llegar a estado "Pendiente Gerencia General")
- Parámetro umbral de escalamiento configurado

## Criterios de aceptación globales del módulo

- Gerencia aprueba/rechaza en menos de 3 min por iniciativa
- Cierre correcto del flujo

## Riesgos

- Acumulación de iniciativas por inactividad. Mitigación: recordatorios F3 + delegación a suplentes (parámetro)

## Definition of Done

- 3 historias cerradas
- Solutions exportadas
- Runbook
- Tests
- Demo
