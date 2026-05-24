# Sprint 0 — Bootstrap técnico

> **Duración estimada**: 2 semanas
> **Prerequisito**: Fase 0 cerrada (convenciones y templates en GitHub)
> **Objetivo**: Dejar listas las bases técnicas sobre las que se construyen todos los módulos funcionales.

> **Principio**: Sprint 0 no depende de stakeholders externos. Todo dato del cliente (lista de empresas, tarifas, umbrales, plantillas de correo, miembros del Comité, URLs SharePoint) se modela como tabla + Environment Variable y se carga vía seed-data o se administra vía M11. Para Sprint 0 usamos **valores placeholder** que se ajustan después sin tocar código.

## Salidas esperadas

1. Modelo de datos completo (ER, columnas, relaciones, business rules)
2. Business Units creadas en DEV
3. 7 Security Roles definidos con permisos por tabla
4. Solution `innova-core` con tablas vacías exportada y commiteada
5. Connection References + Service Principal funcionando
6. CI/CD pipeline (`.github/workflows/ci.yml`) empaquetando y desplegando
7. Patrones canónicos de Power Fx, Power Automate flow y test documentados con ejemplos
8. Plantilla de seed data para catálogos iniciales

## Issues a abrir en GitHub (10 actividades)

### S0-1 — Diseño detallado del modelo de datos (M1)

| Campo | Contenido |
|---|---|
| **Objetivo** | Producir el diagrama ER completo con las 12 tablas previstas y todas sus columnas, **clasificando cada tabla por origen del dato** |
| **Alcance** | Actualizar `docs/architecture/data-model.md` con: diagrama ER (mermaid), columnas de cada tabla (tipo, requerido, descripción), relaciones 1:N y N:N, business rules detectadas, choice sets globales con todos los valores. **Para cada tabla, clasificar el origen del dato**: proceso (creado por usuarios funcionales), configuración (CRUD via M11 Admin), tenant (Environment Variable). Ver matriz en [m01-modelo-datos.md](modulos/m01-modelo-datos.md) |
| **Criterios de aceptación** | (1) Diagrama renderiza en GitHub. (2) Cada tabla tiene tabla markdown de columnas. (3) Cada relación documenta cardinalidad y comportamiento on-delete. (4) Cada tabla clasificada por origen del dato. (5) Aprobación de Tech Lead |
| **Validaciones requeridas** | Validar contra historias de cada pantalla. Confirmar que ninguna tabla tiene datos hardcodeados que deberían ser configurables |
| **Riesgos** | Sub-iterar el modelo cuando aparezcan reglas nuevas en módulos. Mitigación: dejar versión 1.0 y permitir 1.x antes de M2 |
| **Labels** | `activity`, `p0`, `core`, `docs` |

### S0-2 — Crear Business Units en DEV (ADR-0003)

| Campo | Contenido |
|---|---|
| **Objetivo** | Implementar la jerarquía de BUs definida en ADR-0003 con **nombres placeholder** que se renombran después vía Admin sin tocar código |
| **Alcance** | Crear BU raíz `Grupo Pasquí`, 3 BUs hijas con nombres placeholder (`Empresa A`, `Empresa B`, `Empresa C`), BU transversal `Comité`. Documentar en `docs/runbooks/01-crear-business-units.md`. **Las BUs se pueden renombrar y agregar/quitar** desde el Power Platform Admin Center sin redeploy |
| **Criterios de aceptación** | (1) BUs visibles en Power Platform Admin Center > DEV. (2) Runbook con captura de pantalla por paso. (3) Runbook documenta cómo agregar/renombrar/quitar BUs post-deploy |
| **Validaciones requeridas** | Verificar que un usuario asignado a `Empresa A` solo ve datos de esa BU. Renombrar una BU y verificar que no rompe nada |
| **Riesgos** | Eliminar BU con datos asociados deja registros huérfanos. Mitigación: en runbook, soft-delete o reasignación antes de borrar |
| **Labels** | `activity`, `p0`, `core` |

### S0-3 — Definir 7 Security Roles

| Campo | Contenido |
|---|---|
| **Objetivo** | Crear los 7 roles de INNOVA con permisos por tabla acordes al modelo de datos |
| **Alcance** | Roles: `INNOVA Solicitante`, `INNOVA PMO`, `INNOVA TI`, `INNOVA Jefatura`, `INNOVA Gerencia`, `INNOVA Comité`, `INNOVA Administrador`. Matriz de permisos en `docs/architecture/security-roles.md` (Create / Read / Write / Delete / Append / AppendTo por tabla y por rol, con scope BU/Org según corresponda) |
| **Criterios de aceptación** | (1) Roles creados en DEV. (2) Matriz documentada y aprobada. (3) Cada rol probado con un usuario de prueba |
| **Validaciones requeridas** | Login con usuario de prueba en cada rol, verificar que ve solo lo que debe |
| **Riesgos** | Sobre-permisos al rol Administrador. Mitigación: separar `Administrador Funcional` vs `System Administrator` |
| **Labels** | `activity`, `p0`, `core` |

### S0-4 — Crear solution `innova-core` con tablas vacías

| Campo | Contenido |
|---|---|
| **Objetivo** | Tener el contenedor versionable con la estructura del modelo de datos (sin datos aún) |
| **Alcance** | Crear las 11 tablas en `innova-core` siguiendo `docs/conventions/dataverse-naming.md`. Aplicar columnas, choice sets y relaciones del issue S0-1. Exportar como Unmanaged y `pac solution unpack` en `solutions/innova-core/` |
| **Criterios de aceptación** | (1) Solution exportada y unpacked. (2) Archivos versionados en git. (3) `pac solution pack` reconstruye el zip sin errores |
| **Validaciones requeridas** | Round-trip: pack → import en un environment limpio → export → unpack → diff vacío |
| **Riesgos** | Cambios manuales en DEV que no queden en el solution. Mitigación: convención de "solo cambios vía solution" |
| **Labels** | `activity`, `p0`, `core` |

### S0-5 — Service Principal, Connection References y Environment Variables

| Campo | Contenido |
|---|---|
| **Objetivo** | Establecer el modelo de identidad (SP), conexiones portables (Connection References) y parametrización por tenant (Environment Variables) que permite entregar el solution al cliente sin acoplar URLs/IDs nuestros. Ver [ADR-0004](../decisions/0004-entrega-cliente.md) |
| **Alcance** | (1) Registrar App Registration en Entra ID **nuestro** para DEV/QA; documentar pasos equivalentes que el cliente debe seguir en su tenant. (2) Crear Connection References: `cr_innova_dataverse`, `cr_innova_outlook`, `cr_innova_sharepoint`, `cr_innova_teams`, `cr_innova_office365users`. (3) Modelar Environment Variables de Dataverse para todo lo tenant-specific (URLs SharePoint, correos institucionales, IDs Teams, parámetros operativos). (4) Documentar inventario en `docs/architecture/entrega-cliente.md`. (5) Generar `deployment-settings.dev.json` y `deployment-settings.qa.json` de ejemplo |
| **Criterios de aceptación** | (1) App Reg creada en GTC. (2) Secret en Key Vault, nunca en git. (3) Las 5 Connection References usadas por al menos un flow piloto. (4) 6+ Environment Variables modeladas y consumidas. (5) `deployment-settings.dev.json` y `.qa.json` generados con valores reales. (6) Plantilla `deployment-settings.prod.template.json` versionada para que el cliente la rellene. (7) Runbook reproducible en `docs/runbooks/02-service-principal.md` cubre tanto el SP nuestro como el del cliente |
| **Validaciones requeridas** | (a) Flow de prueba ejecuta como SP (verificar en run log). (b) Importar solution en QA con `--settings-file deployment-settings.qa.json` y verificar que las variables aparecen poblados. (c) Romper a propósito una Environment Variable y validar que el flow falla con error claro |
| **Riesgos** | (1) Permisos insuficientes del SP. Mitigación: probar con caso real. (2) Olvidar parametrizar algo y descubrirlo en cliente. Mitigación: revisión por checklist antes de cerrar el issue |
| **Labels** | `activity`, `p0`, `core`, `flows` |

### S0-6 — CI/CD GitHub Actions: validar + empaquetar + entregar al cliente

| Campo | Contenido |
|---|---|
| **Objetivo** | Que `.github/workflows/ci.yml` empaquete las solutions, valide naming/calidad, despliegue automáticamente a **nuestro QA** y produzca un **GitHub Release con el ZIP entregable al cliente**. No hay auto-deploy a PROD (PROD vive en tenant cliente — ver [ADR-0004](../decisions/0004-entrega-cliente.md)) |
| **Alcance** | **Workflow PR**: (a) instalar PAC CLI, (b) `pac solution pack`, (c) lint de naming (regex `^pas_`), (d) lint Power Fx, (e) `pac solution check`. **Workflow merge-to-main**: además (f) auto-import a nuestro QA con SP secret `PAC_QA_CLIENT_SECRET`, (g) smoke test en QA. **Workflow release-tag (v*)**: (h) empaquetar como Managed, (i) generar plantilla `deployment-settings.prod.template.json` (sin valores reales), (j) calcular SHA-256, (k) crear GitHub Release con todos los ZIPs + plantilla + checksums + release notes auto-generados desde CHANGELOG.md |
| **Criterios de aceptación** | (1) Workflow PR corre verde. (2) Lint falla si encuentra columnas sin prefijo `pas_`. (3) Merge a main auto-importa a QA y corre smoke test. (4) Tag `v*` produce GitHub Release con artefactos listos para entregar al cliente. (5) Plantilla `deployment-settings.prod.template.json` tiene placeholders claros para que el cliente la rellene |
| **Validaciones requeridas** | (a) PR de prueba con columna sin prefijo debe fallar. (b) Merge a main debe dejar QA actualizado. (c) Tag de prueba `v0.0.1-test` debe producir Release descargable |
| **Riesgos** | (1) Tiempo de ejecución largo con `solution check`. Mitigación: correrlo solo en main y tags, no en cada PR. (2) Secret expuesto en logs. Mitigación: `secrets.PAC_QA_CLIENT_SECRET` con masking activo. (3) Release con datos de prueba contaminados. Mitigación: el job de release exporta de **una solution limpia** generada de fuentes, no de un environment activo |
| **Labels** | `activity`, `p1`, `ci` |

### S0-7 — Plantilla canónica de Power Fx

| Campo | Contenido |
|---|---|
| **Objetivo** | Tener un ejemplo "ideal" que sirva como referencia para todos los desarrolladores futuros |
| **Alcance** | Mini-app "INNOVA - Ejemplo Patrones" en DEV con: variable global de usuario, named formulas, `Patch()` con `Defaults()`, manejo de error con `IfError()`, navegación entre pantallas, formato de fecha CR, filtros delegables vs no-delegables. Exportar y guardar en `solutions/innova-canvas/_ejemplo-patrones/`. Documentar cada patrón en `docs/conventions/power-fx-patterns.md` |
| **Criterios de aceptación** | (1) App ejecuta sin errores. (2) Cada patrón comentado. (3) `docs/conventions/power-fx-patterns.md` listo |
| **Validaciones requeridas** | Code review por Tech Lead |
| **Riesgos** | App-ejemplo que se desactualiza con la plataforma. Mitigación: marcarla `[REFERENCIA]` y revisarla cada release de Power Platform |
| **Labels** | `activity`, `p1`, `canvas`, `docs` |

### S0-8 — Plantilla canónica de Power Automate flow

| Campo | Contenido |
|---|---|
| **Objetivo** | Tener el patrón Scope Validations + Main Logic + Notifications + Error Handler del runbook 08 implementado como flow de plantilla |
| **Alcance** | Crear flow `INNOVA - Plantilla - Patron Estandar` en `innova-flows`. Aplicar exactamente la estructura del runbook 08. Exportar, unpack en `solutions/innova-flows/`. Esto es el patrón que TODA nueva flow copia |
| **Criterios de aceptación** | (1) Flow funciona end-to-end. (2) Scopes con run-after correctos. (3) Retry policy aplicada |
| **Validaciones requeridas** | Test manual de los 3 casos del runbook 08 (feliz, datos faltantes, error técnico) |
| **Riesgos** | Que la plantilla se modifique en lugar de copiarse. Mitigación: marcar con `[PLANTILLA - NO MODIFICAR]` en el nombre |
| **Labels** | `activity`, `p1`, `flows`, `docs` |

### S0-9 — Framework de tests

| Campo | Contenido |
|---|---|
| **Objetivo** | Establecer cómo se documentan y ejecutan los tests para flows, canvas, plugins y PCF |
| **Alcance** | Estructura de carpetas en `tests/`. Plantilla de test plan en markdown. Decisión sobre Power Apps Test Studio vs tests manuales documentados. Setup mínimo de NUnit/xUnit para plugins .NET (si aplica). Setup de Jest para PCF |
| **Criterios de aceptación** | (1) `tests/README.md` describe la estrategia. (2) Plantilla `tests/_template-test-plan.md`. (3) Un test de ejemplo por categoría |
| **Validaciones requeridas** | Test de ejemplo ejecutable con un comando |
| **Riesgos** | Falta de tooling oficial de tests para Power Automate. Mitigación: definir formato de test manual con captura/log |
| **Labels** | `activity`, `p1`, `docs`, `flows`, `canvas` |

### S0-10 — Seed data inicial para catálogos (valores placeholder)

| Campo | Contenido |
|---|---|
| **Objetivo** | Tener un script que pueble los catálogos básicos con **valores placeholder** para que cualquier desarrollador pueda trabajar en su ambiente. Los valores reales del cliente se cargan vía M11 (Admin) post-instalación |
| **Alcance** | Implementar `scripts/seed-data.ps1` que cree con placeholders: 3 centros de costo (`CC-001`, `CC-002`, `CC-003`), 5 plantillas de correo básicas con texto genérico, parámetros de sistema (`UmbralEscalamientoComite = 5000000`, `TarifaHoraPMO = 25000`, `TarifaHoraTI = 35000`, `DiasRecordatorio = 3`), 3 miembros del Comité de prueba (usuarios de test del tenant GTC). Usar PAC CLI o Web API. Idempotente (no duplica si ya existen). **Mismo script corre en DEV/QA/PROD** — los valores reales se ajustan via M11 después |
| **Criterios de aceptación** | (1) Script corre sin error sobre DEV vacío. (2) Re-ejecutarlo no duplica datos. (3) Datos seed documentados en `scripts/README.md`. (4) Todos los valores son claramente identificables como placeholder (prefijo `PLACEHOLDER-` o valor numérico round) |
| **Validaciones requeridas** | Test sobre environment limpio. Test de re-ejecución. Test que M11 puede editar los valores cargados |
| **Riesgos** | Que developers asuman los valores placeholder como reales y los hagan referencia desde código. Mitigación: convención de prefijos + revisión en code review |
| **Labels** | `activity`, `p2`, `ci`, `core` |

## Orden recomendado

```
S0-1 (modelo) ─┬─→ S0-2 (BUs) ─→ S0-3 (roles)
               │
               └─→ S0-4 (solution core) ─→ S0-5 (SP/connections)
                                        │
                                        └─→ S0-6 (CI/CD)
                                        │
S0-7 (Fx) y S0-8 (flow) en paralelo desde aquí
                                        │
S0-9 (tests) puede ir desde el inicio
S0-10 (seed) cuando exista el modelo (después de S0-4)
```

## Definition of Done de Sprint 0

- 10 issues cerrados
- `innova-core` con todas las tablas, BUs y roles funcionando en DEV
- Un flow de ejemplo corriendo end-to-end
- CI/CD pipeline verde en al menos 3 PRs distintos
- Documentación al día (data-model, security-roles, runbooks 01-02)
- `scripts/seed-data.ps1` ejecutable
- Demo técnica al equipo

## Salida hacia módulos funcionales

Con Sprint 0 cerrado, los módulos M2-M14 pueden empezar a abrir issues con confianza de que toda la infraestructura técnica está lista. Ver `modulos/`.
