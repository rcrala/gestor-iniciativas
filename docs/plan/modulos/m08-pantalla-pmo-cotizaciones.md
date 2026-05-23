# M8 — Pantalla PMO Cotizaciones (#7)

> **Pantalla**: #7 del análisis funcional
> **Tablas principales**: `pas_cotizacion`, `pas_documentoadj`
> **Stream**: `canvas` + `flows`

## Objetivo de negocio

Permitir al PMO solicitar y registrar cotizaciones (hasta 3: 1 interna + 2 externas), seleccionar la ganadora con justificación, y vincular el resultado a la iniciativa para que avance a ejecución.

## Historias de usuario (issues GitHub)

### M8-H1 — Pantalla PMO Cotizaciones: registrar cotizaciones (hasta 3)

| Campo | Contenido |
|---|---|
| **Objetivo** | Capturar hasta 3 cotizaciones por iniciativa con proveedor, monto, alcance, plazo, archivos adjuntos |
| **Alcance** | Canvas con galería editable de cotizaciones. `Patch()` a `pas_cotizacion`. Adjuntos a SharePoint vía `pas_documentoadj` |
| **Criterios de aceptación** | (1) Máximo 3 cotizaciones. (2) Tipo Interna / Externa. (3) Campos obligatorios validados. (4) Archivos adjuntos opcionales pero soportados |
| **Validaciones** | Test con 1, 2, 3 cotizaciones |
| **Riesgos** | Modelar más de 3 cotizaciones en el futuro. Mitigación: usar tabla relacionada (ya lo es), límite enforced por UI no por modelo |
| **Labels** | `activity`, `p0`, `canvas`, `core` |

### M8-H2 — Pantalla PMO Cotizaciones: seleccionar ganadora con justificación

| Campo | Contenido |
|---|---|
| **Objetivo** | Marcar cuál de las cotizaciones es la ganadora, con justificación textual obligatoria |
| **Alcance** | Toggle "Es ganadora" mutuamente exclusivo entre cotizaciones de la misma iniciativa. Campo `pas_justificacion` requerido al marcar |
| **Criterios de aceptación** | (1) Solo 1 ganadora por iniciativa. (2) Justificación obligatoria. (3) Cambiar ganadora actualiza correctamente |
| **Validaciones** | Test de exclusividad y de cambio de ganadora |
| **Riesgos** | Race condition si dos PMO marcan al mismo tiempo. Mitigación: plugin C# o flow con transacción |
| **Labels** | `activity`, `p0`, `canvas`, `flows` |

### M8-H3 — Flow: cotización ganadora seleccionada → habilitar Ejecución (M6)

| Campo | Contenido |
|---|---|
| **Objetivo** | Cuando se marca una ganadora y la iniciativa fue aprobada por Jefatura, transicionar el estado a "En Ejecución" |
| **Alcance** | Flow disparado por Update en `pas_cotizacion.es_ganadora = true`. Verificar que la iniciativa esté en estado "Aprobada por Jefatura". Si sí, `Patch()` estado iniciativa a "En Ejecución" + notificar PMO Ejecución |
| **Criterios de aceptación** | (1) Transición solo si pre-condición se cumple. (2) Notificación correcta |
| **Validaciones** | Test happy + test sin pre-condición (debe no transicionar) |
| **Riesgos** | Doble disparo si se cambia la ganadora. Mitigación: idempotencia checando el estado actual |
| **Labels** | `activity`, `p0`, `flows` |

## Tablas Dataverse tocadas

- `pas_cotizacion` (Create, Update)
- `pas_documentoadj` (Create)
- `pas_iniciativa` (Update: estado)

## Flows requeridos

- `INNOVA - Cotizacion Ganadora - Habilitar Ejecucion`

## Dependencias previas

- M5 cerrado (debe existir aprobación de Jefatura)
- Estructura SharePoint para cotizaciones

## Criterios de aceptación globales del módulo

- PMO registra 1-3 cotizaciones y selecciona ganadora
- Iniciativa puede transicionar a ejecución solo con cotización ganadora válida

## Riesgos

- Datos sensibles de proveedores. Mitigación: FLS en campos críticos
- Validación de montos no consistentes con la estimación previa. Mitigación: alerta UI si la ganadora difiere >X% de la estimación

## Definition of Done

- 3 historias cerradas
- Solutions exportadas
- Runbook
- Tests
- Demo
