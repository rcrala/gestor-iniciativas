# Roadmap INNOVA

> Plan maestro de trabajo. Cada hito se descompone en issues de GitHub siguiendo [docs/15-Directriz/20260521-github-workflow.md](../15-Directriz/20260521-github-workflow.md).

## Resumen ejecutivo

INNOVA se entrega en **3 grandes bloques** secuenciados:

1. **Fase 0 — Alineación** (1 semana). Convenciones, GitHub workflow, plantillas, decisiones pendientes.
2. **Sprint 0 — Bootstrap técnico** (2 semanas). Modelo de datos, Business Units, security roles, solutions skeleton, CI/CD.
3. **Sprints funcionales — Módulos M1-M14** (14-18 semanas según paralelización). Una pantalla/capa por módulo.

Las **Fases transversales F1-F6** (ALM, seguridad, notificaciones, reportería, documentación, performance) corren en paralelo a los módulos.

## Estructura del plan

```
docs/plan/
├── 00-roadmap.md              ← este archivo
├── fase-0-alineacion.md       ← Fase 0 detallada
├── sprint-0-bootstrap.md      ← Sprint 0 detallado
└── modulos/
    ├── m01-modelo-datos.md
    ├── m02-pantalla-solicitante.md
    ├── m03-pantalla-pmo-evaluacion.md
    ├── m04-pantalla-ti-estimacion.md
    ├── m05-pantalla-jefatura-estimacion.md
    ├── m06-pantalla-pmo-ejecucion.md
    ├── m07-pantalla-jefatura-validacion.md
    ├── m08-pantalla-pmo-cotizaciones.md
    ├── m09-pantalla-gerencia-general.md
    ├── m10-pantalla-comite.md
    ├── m11-pantalla-administrador.md
    ├── m12-tracking-mis-solicitudes.md
    ├── m13-reporteria-power-bi.md
    └── m14-cierre-runbooks-training.md
```

## Mapeo módulo → pantalla → tablas

| Módulo | Pantalla del análisis | Tablas Dataverse principales | Depende de |
|---|---|---|---|
| **M1** | (transversal) Modelo de datos | Todas | — |
| **M2** | #1 Solicitante | `pas_iniciativa` | M1 |
| **M3** | #2 PMO Evaluación | `pas_evaluacionpmo` | M2 |
| **M4** | #3 TI Estimación | `pas_evaluacionti` | M3 (condicional) |
| **M5** | #4 Jefatura Estimación | (workflow + email) | M3, M4 |
| **M6** | #5 PMO Ejecución | `pas_horatrabajo` | M5 |
| **M7** | #6 Jefatura Validación de ejecución | (workflow) | M6 |
| **M8** | #7 PMO Cotizaciones | `pas_cotizacion`, `pas_documentoadj` | M3 (paralelizable) |
| **M9** | #8 Gerencia General | (workflow + umbral) | M7, M8 |
| **M10** | Comité de Proyectos | `pas_miembrocomite`, `pas_votocomite` | M9 (cuando escala) |
| **M11** | Administrador | `pas_parametro`, `pas_centrocosto`, `pas_plantillacorreo`, `pas_miembrocomite` | Sprint 0 (paralelo con M2 — H1 y H4 son prerequisitos de go-live) |
| **M12** | Tracking "Mis Solicitudes" (transversal) | (vista) | M2 |
| **M13** | Reportería Power BI | (consume todas) | M6 mínimo |
| **M14** | Cierre + runbooks + training | — | Todos |

## Fases transversales (F1-F6)

| Fase | Foco | Cuándo |
|---|---|---|
| **F1** | ALM / CI-CD | Refinamiento continuo, gran salto en Sprint 0 |
| **F2** | Seguridad (BU, roles, RLS, FLS, auditoría) | Revisión por sprint |
| **F3** | Notificaciones (correo, Teams) | Patrón canónico en Sprint 0, instancias por módulo |
| **F4** | Reportería Power BI | Crece con cada módulo entregado |
| **F5** | Documentación y training | Runbook por historia + glosario vivo |
| **F6** | Performance y monitoreo | Antes de QA/PROD |

## Ruta crítica

```
Fase 0 → Sprint 0 → M2 → M3 → M5 → M6 → M7 → M9 → M10 → M13 → M14
                     ↘ M11 (paralelo a M2 — H1 y H4 prerequisitos de go-live)
                     ↘ M4 (si requiere desarrollo)
                     ↘ M8 (paralelizable desde M3)
                     ↘ M12 (paralelizable desde M2)
```

## Convenciones de plan

### Naming de branches
Según directriz: `issue-<id>-<stream>-<tema-corto>` (con issue) o `wip-<yyyymmdd>-<tema-corto>` (sin issue aún).

### Streams (también usados como labels GitHub)
- `core` — Dataverse (tablas, columnas, BU, roles)
- `canvas` — Pantallas Power Apps
- `flows` — Power Automate
- `reports` — Power BI
- `pcf` — PCF Controls
- `plugins` — Plug-ins .NET Dataverse
- `docs` — Documentación, runbooks, ADRs
- `ci` — CI/CD pipelines, scripts

### Issue por actividad
Cada actividad concreta = 1 issue. Plantilla y campos obligatorios definidos en [Fase 0](fase-0-alineacion.md).

### Definition of Done por módulo
1. Todas las historias del módulo cerradas vía PR mergeado
2. Tablas/flows/pantallas exportados, unpacked y commiteados en `solutions/`
3. Tests funcionales documentados en `tests/` con evidencia
4. Runbook del módulo en `docs/runbooks/`
5. `CHANGELOG.md` actualizado
6. Demo al stakeholder

## Principio de configurabilidad

Sprint 0 y los módulos M1-M14 **no dependen de stakeholders externos** para empezar implementación. Todo dato que el cliente pueda querer cambiar (lista de empresas, tarifas, umbrales, plantillas de correo, miembros del Comité, URLs SharePoint, IDs Teams) se modela como:

- **Tabla Dataverse + CRUD via M11 Admin** (parámetros, catálogos, miembros)
- **Environment Variables** (URLs y conexiones tenant-specific)
- **Seed data placeholder** que se ajusta post-deploy

Sprint 0 usa valores placeholder (`Empresa A/B/C`, `TarifaHoraPMO=25000`, etc.) que se cambian sin tocar código.

## Riesgos identificados al planificar

| Riesgo | Mitigación |
|---|---|
| `WBS_INNOVA.xlsx` no está versionado — el mapeo de módulos podría no coincidir | Validar este roadmap contra el Excel original antes de empezar Sprint 0 |
| ~~PROD environment no aprovisionado~~ | **Resuelto en issue #5 (PR #6): PROD vive en tenant del cliente, ver ADR-0004**  |
| ~~`.mcp.json` y `.claude/settings.json` con rutas WSL hardcodeadas~~ | **Resuelto en issue #4 (PR #9)** |
| ~~Inconsistencias entre README.md (menciona `develop`) y la directriz GitHub (`dev-cfg` o `main`)~~ | **Resuelto en issue #2 (PR #7)** |
| Migración de iniciativas existentes en Excel/correo | ADR pendiente, abrir issue durante Sprint 1 |
| M11 (Admin) construido tarde y bloquea go-live | **M11-H1 y M11-H4 marcados como paralelos a M2 y prerequisitos de go-live** |

## Estado

- **Fecha de creación**: 2026-05-23
- **Branch de creación**: `wip-20260523-create-plan`
- **Estado**: Borrador para revisión
