# M1 — Modelo de datos (transversal)

> **Tipo**: Módulo transversal, prerequisito de todos los demás
> **Pantalla**: ninguna (capa de persistencia)
> **Entregable principal**: `docs/architecture/data-model.md` v1.0 + tablas en `solutions/innova-core/`

## Objetivo de negocio

Establecer la estructura de datos que soporta el ciclo completo de una iniciativa: registro, evaluación, estimación, aprobaciones, cotizaciones, ejecución y reportería.

## Historias de usuario

Como Arquitecto, quiero un modelo de datos completo y documentado para que cualquier desarrollador pueda construir pantallas y flows sin ambigüedad.

> **Nota**: Las actividades concretas de este módulo viven en [sprint-0-bootstrap.md](../sprint-0-bootstrap.md#s0-1--diseño-detallado-del-modelo-de-datos-m1) (issue S0-1). Este archivo existe para que el módulo esté representado en el roadmap.

## Tablas Dataverse tocadas

Las 11 tablas previstas en [docs/architecture/data-model.md](../../architecture/data-model.md):

`pas_iniciativa`, `pas_cotizacion`, `pas_evaluacionpmo`, `pas_evaluacionti`, `pas_horatrabajo`, `pas_centrocosto`, `pas_miembrocomite`, `pas_votocomite`, `pas_documentoadj`, `pas_plantillacorreo`, `pas_parametro`

## Flows requeridos

Ninguno (capa de persistencia).

## Dependencias previas

- Fase 0 cerrada
- ADR-0003 (Business Units) aprobado

## Criterios de aceptación globales

- Diagrama ER completo, con cardinalidades y comportamiento on-delete
- Cada tabla documentada con columnas tipadas y descritas
- Choice sets globales con todos los valores listados
- Business Rules de Dataverse identificadas
- Validación cruzada contra las 8+ pantallas del análisis funcional

## Riesgos

- Iteración del modelo al avanzar en módulos. Mitigación: versionado del documento, cambios por ADR cuando rompen compatibilidad
- Discrepancia entre el WBS original y el modelo derivado de pantallas. Mitigación: walkthrough con stakeholder antes de cerrar v1.0

## Definition of Done

- Issue S0-1 cerrado
- Tablas creadas en `innova-core` (issue S0-4)
- BUs y roles aplicados (issues S0-2, S0-3)
- `docs/architecture/data-model.md` v1.0 commiteado
