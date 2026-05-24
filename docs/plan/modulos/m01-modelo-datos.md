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

Las 12 tablas definidas en [docs/architecture/data-model.md](../../architecture/data-model.md), clasificadas por origen del dato:

| Tabla | Origen | CRUD por | Carga inicial |
|---|---|---|---|
| `pas_iniciativa` | **Proceso** | Solicitante (Create), PMO/TI/Jefatura/Gerencia/Comité (Update segun fase) | N/A (vacia) |
| `pas_evaluacionpmo` | **Proceso** | PMO | N/A |
| `pas_evaluacionti` | **Proceso** | TI | N/A |
| `pas_cotizacion` | **Proceso** | PMO | N/A |
| `pas_horatrabajo` | **Proceso** | PMO, TI | N/A |
| `pas_votocomite` | **Proceso** | Miembros Comité | N/A |
| `pas_documentoadj` | **Proceso** | Usuarios (metadata; archivo va a SharePoint) | N/A |
| `pas_empresa` | **Configuración** | M11 Administrador | Seed con 3 placeholders (`Empresa A/B/C`) |
| `pas_centrocosto` | **Configuración** | M11 Administrador | Seed con 3 placeholders |
| `pas_plantillacorreo` | **Configuración** | M11 Administrador | Seed con 5 plantillas genericas |
| `pas_parametro` | **Configuración** | M11 Administrador | Seed con umbrales y tarifas placeholder |
| `pas_miembrocomite` | **Configuración** | M11 Administrador | Seed con 3 usuarios de test |

**Lista de empresas del Grupo Pasquí**: **resuelto en S0-1 v1.0** — modelada como tabla `pas_empresa` con lookup 1:1 a `businessunit` (Opción A). Permite metadata adicional por empresa (logo, código contable, contacto principal) y CRUD via M11. Ver [`docs/architecture/data-model.md`](../../architecture/data-model.md#por-qué-pas_empresa-como-tabla-en-lugar-de-solo-bu) para el rationale.

**Datos tenant-specific** (NO viven en Dataverse, viven en Environment Variables — ver [`entrega-cliente.md`](../../architecture/entrega-cliente.md)):
- URL SharePoint del cliente
- Correos institucionales (PMO, Comité, no-reply)
- IDs de Teams channel
- Tenant ID

## Principio rector

**Si el cliente va a querer cambiar un valor sin contratar a un desarrollador, ese valor debe ser dato (configurable via M11 o Environment Variable), nunca código.**

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
