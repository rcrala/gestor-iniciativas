# M6 — Pantalla PMO Ejecución (#5)

> **Pantalla**: #5 del análisis funcional
> **Tablas principales**: `pas_iniciativa`, `pas_horatrabajo`, `pas_documentoadj`
> **Stream**: `canvas` + `flows`

## Objetivo de negocio

Permitir al PMO documentar la ejecución de la iniciativa una vez aprobada y con cotización seleccionada: avances, entregables, horas reales, y dar por terminada la ejecución para pasar a validación de Jefatura.

## Historias de usuario (issues GitHub)

### M6-H1 — Pantalla PMO Ejecución: detalle de la iniciativa en ejecución

| Campo | Contenido |
|---|---|
| **Objetivo** | El PMO ve la iniciativa con toda la información acumulada (evaluación, estimación, cotización ganadora, aprobaciones) y un área de ejecución |
| **Alcance** | Canvas screen con tabs: Resumen, Cotización ganadora, Ejecución (editable), Adjuntos |
| **Criterios de aceptación** | (1) Información acumulada visible. (2) Editable solo si estado = "En Ejecución" |
| **Validaciones** | Smoke test |
| **Riesgos** | Sobrecarga de información en una sola pantalla. Mitigación: tabs |
| **Labels** | `activity`, `p1`, `canvas` |

### M6-H2 — Pantalla PMO Ejecución: registrar avances y horas reales

| Campo | Contenido |
|---|---|
| **Objetivo** | Capturar diariamente/semanalmente: bitácora de avance, hitos cumplidos, horas reales por colaborador y centro de costo |
| **Alcance** | Sub-galería de avances con `Patch()` por entrada. Tabla de horas con `Patch()` a `pas_horatrabajo`. Adjuntar entregables que viajan a SharePoint |
| **Criterios de aceptación** | (1) Avances persisten. (2) Horas suman correctamente. (3) Entregables suben a SharePoint correcto |
| **Validaciones** | Test con 5+ entradas de avance |
| **Riesgos** | Performance con cientos de entradas. Mitigación: galería paginada |
| **Labels** | `activity`, `p1`, `canvas`, `flows` |

### M6-H3 — Pantalla PMO Ejecución: marcar como Terminada → enviar a validación de Jefatura

| Campo | Contenido |
|---|---|
| **Objetivo** | Cerrar la fase de ejecución con un resumen final y disparar el flujo hacia M7 |
| **Alcance** | Botón "Terminar ejecución" con confirmación. `Patch()` estado a "Pendiente Validación Jefatura". Validación: no se puede terminar sin al menos 1 entregable y 1 avance |
| **Criterios de aceptación** | (1) Estado se actualiza solo si validaciones pasan. (2) Flow a M7 dispara. (3) Resumen final guardado |
| **Validaciones** | Test happy path y test con validaciones falladas |
| **Riesgos** | Re-aperturas de ejecución una vez cerrada. Mitigación: solo Administrador puede re-abrir |
| **Labels** | `activity`, `p1`, `canvas`, `flows` |

## Tablas Dataverse tocadas

- `pas_iniciativa` (Update: estado, resumen ejecución)
- `pas_horatrabajo` (Create)
- `pas_documentoadj` (Create)

## Flows requeridos

- `INNOVA - Ejecucion Terminada - Notificar Jefatura`

## Dependencias previas

- M5 cerrado
- M8 (cotizaciones) cerrado: debe existir cotización ganadora
- Estructura SharePoint para ejecución

## Criterios de aceptación globales del módulo

- PMO documenta ejecución sin perder información
- Entregables y horas quedan trazables
- Cierre dispara la siguiente fase

## Riesgos

- Volumen de adjuntos pesados. Mitigación: cuota por iniciativa, política de archivado
- Multiusuario en simultáneo sobre la misma iniciativa. Mitigación: lock soft con visualización de "siendo editada por X"

## Definition of Done

- 3 historias cerradas
- Solutions exportadas
- Runbook `docs/runbooks/m06-pmo-ejecucion.md`
- Tests documentados
- Demo PMO
