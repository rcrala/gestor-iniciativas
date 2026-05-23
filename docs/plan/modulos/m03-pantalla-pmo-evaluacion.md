# M3 — Pantalla PMO Evaluación (#2)

> **Pantalla**: #2 del análisis funcional
> **Tablas principales**: `pas_evaluacionpmo`, `pas_horatrabajo`
> **Stream**: `canvas` + `flows`

## Objetivo de negocio

Permitir al PMO analizar una iniciativa recibida, registrar el levantamiento (horas, complejidad, riesgo), y decidir si requiere estimación de TI o pasa directo a Jefatura.

## Historias de usuario (issues GitHub)

### M3-H1 — Pantalla PMO: lista de iniciativas pendientes de evaluación

| Campo | Contenido |
|---|---|
| **Objetivo** | El PMO ve solo las iniciativas en estado "En Evaluación PMO" filtradas por su BU |
| **Alcance** | Canvas screen con galería filtrada. Búsqueda por consecutivo o título. Indicador de antigüedad |
| **Criterios de aceptación** | (1) Solo iniciativas en estado correcto. (2) Filtro por BU respetado por seguridad. (3) Performance aceptable con 500+ iniciativas |
| **Validaciones** | Test de delegación con dataset grande |
| **Riesgos** | Performance con >2000 iniciativas. Mitigación: filtros server-side, paginación |
| **Labels** | `activity`, `p0`, `canvas` |

### M3-H2 — Pantalla PMO: registrar evaluación (complejidad, clasificación, horas de levantamiento)

| Campo | Contenido |
|---|---|
| **Objetivo** | Capturar el levantamiento con todos los campos definidos: complejidad, clasificación, descripción ampliada, horas invertidas, requiere desarrollo (sí/no), riesgos |
| **Alcance** | Canvas con secciones tipo wizard. `Patch()` a `pas_evaluacionpmo`. Patch de horas a `pas_horatrabajo` con centro de costo del PMO |
| **Criterios de aceptación** | (1) Todos los campos del análisis capturados. (2) Costo de levantamiento calculado en vivo. (3) Si "requiere desarrollo" = Sí, se habilita botón "Enviar a TI" |
| **Validaciones** | Test funcional con los 5 casos (mejora simple, mejora compleja, requiere TI, no requiere TI, rechazada en evaluación) |
| **Riesgos** | Reglas de cálculo de costo que cambien. Mitigación: parametrizar tarifa por hora |
| **Labels** | `activity`, `p0`, `canvas`, `core` |

### M3-H3 — Flow: cambio de estado tras evaluación PMO

| Campo | Contenido |
|---|---|
| **Objetivo** | Cuando el PMO completa la evaluación, transicionar el estado según la decisión y notificar al siguiente actor |
| **Alcance** | Flow disparado por Update en `pas_evaluacionpmo` (status: Completa). Lógica: si requiere desarrollo → estado "En Evaluación TI" + notificar TI; si no → estado "En Aprobación Jefatura" + notificar Jefatura |
| **Criterios de aceptación** | (1) Estado actualizado correctamente. (2) Notificación correcta al actor correcto. (3) Log de transición en auditoría |
| **Validaciones** | Test de los 2 caminos (con/sin TI) |
| **Riesgos** | Concurrencia con M5. Mitigación: usar Choice de estado, no booleano |
| **Labels** | `activity`, `p0`, `flows` |

## Tablas Dataverse tocadas

- `pas_iniciativa` (Update: estado)
- `pas_evaluacionpmo` (Create, Update)
- `pas_horatrabajo` (Create)

## Flows requeridos

- `INNOVA - Evaluacion PMO Completa - Routing`
- `INNOVA - Evaluacion PMO Completa - Notificar TI`
- `INNOVA - Evaluacion PMO Completa - Notificar Jefatura`

## Dependencias previas

- M1, M2 cerrados
- Parametro `Tarifa Hora PMO` configurado en S0-10

## Criterios de aceptación globales del módulo

- PMO puede tomar una iniciativa, evaluarla y rutearla en menos de 10 minutos de UI
- El siguiente actor (TI o Jefatura) recibe notificación correcta
- Reportería ve la iniciativa con su estado actualizado

## Riesgos

- Reglas de clasificación poco claras. Mitigación: workshop con PMO antes de implementar
- Múltiples PMO trabajando la misma iniciativa. Mitigación: lock soft via campo "Asignado a"

## Definition of Done

- 3 historias cerradas
- Solutions exportadas y commiteadas
- Runbook `docs/runbooks/m03-pmo-evaluacion.md`
- Tests documentados
- Demo al equipo PMO piloto
