# Sprint 0 — Bootstrap técnico

> **Duración estimada**: 2 semanas
> **Prerequisito**: Fase 0 cerrada (convenciones y templates en GitHub)
> **Objetivo**: Dejar listas las bases técnicas sobre las que se construyen todos los módulos funcionales.

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
| **Objetivo** | Producir el diagrama ER completo con las 11 tablas previstas y todas sus columnas |
| **Alcance** | Actualizar `docs/architecture/data-model.md` con: diagrama ER (mermaid), columnas de cada tabla (tipo, requerido, descripción), relaciones 1:N y N:N, business rules detectadas, choice sets globales con todos los valores |
| **Criterios de aceptación** | (1) Diagrama renderiza en GitHub. (2) Cada tabla tiene tabla markdown de columnas. (3) Cada relación documenta cardinalidad y comportamiento on-delete. (4) Aprobación de Tech Lead + Functional Lead |
| **Validaciones requeridas** | Walkthrough con stakeholders. Validar contra historias de cada pantalla |
| **Riesgos** | Sub-iterar el modelo cuando aparezcan reglas nuevas en módulos. Mitigación: dejar versión 1.0 y permitir 1.x antes de M2 |
| **Labels** | `activity`, `p0`, `core`, `docs` |

### S0-2 — Crear Business Units en DEV (ADR-0003)

| Campo | Contenido |
|---|---|
| **Objetivo** | Implementar la jerarquía de BUs definida en ADR-0003 |
| **Alcance** | Crear BU raíz `Grupo Pasquí`, BUs hijas por cada empresa del Grupo (lista a confirmar con stakeholder), BU transversal `Comité`. Documentar en `docs/runbooks/01-crear-business-units.md` |
| **Criterios de aceptación** | (1) BUs visibles en Power Platform Admin Center > DEV. (2) Runbook con captura de pantalla por paso. (3) Lista de empresas confirmada por stakeholder |
| **Validaciones requeridas** | `pac admin list` o equivalente para listar BUs |
| **Riesgos** | Lista de empresas del Grupo no congelada. Mitigación: abrir ticket al sponsor antes de empezar |
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

### S0-5 — Configurar Service Principal y Connection References

| Campo | Contenido |
|---|---|
| **Objetivo** | Que los flows usen identidad de service principal (no usuario), y que las conexiones sean portables entre ambientes |
| **Alcance** | Registrar App Registration en Entra ID. Asignar permisos en DEV (rol System Customizer + acceso a Dataverse). Crear Connection References para Dataverse, Office 365 Outlook, Teams, SharePoint. Documentar en `docs/runbooks/02-service-principal.md`. Guardar el ClientId (no el secret) en `docs/architecture/secrets-inventory.md` |
| **Criterios de aceptación** | (1) App Reg creada. (2) Secret en KeyVault o equivalente (NUNCA en git). (3) Connection References usadas por al menos un flow de prueba. (4) Documentación reproducible para QA y PROD |
| **Validaciones requeridas** | Flow de prueba ejecuta como service principal (verificar en el run log) |
| **Riesgos** | Permisos insuficientes del SP. Mitigación: probar con caso real antes de cerrar |
| **Labels** | `activity`, `p0`, `core`, `flows` |

### S0-6 — Completar CI/CD pipeline GitHub Actions

| Campo | Contenido |
|---|---|
| **Objetivo** | Que `.github/workflows/ci.yml` empaquete las solutions, valide naming, y opcionalmente despliegue a QA en merge a main |
| **Alcance** | Workflow steps: (a) instalar PAC CLI, (b) `pac solution pack` por cada solution, (c) lint de naming (regex `^pas_`), (d) lint de Power Fx con `pac power-fx`, (e) `pac solution check` para validar contra el catálogo de Microsoft, (f) artifacts subidos como release artifacts, (g) opcional: import a QA con service principal usando secret `PAC_CLIENT_SECRET` |
| **Criterios de aceptación** | (1) Workflow corre en cada PR. (2) Lint falla si encuentra columnas sin prefijo `pas_`. (3) Artifacts visibles en la run. (4) Job opcional de deploy condicionado a `if: github.ref == 'refs/heads/main'` |
| **Validaciones requeridas** | PR de prueba que rompa una regla (ej: columna sin prefijo) debe fallar el workflow |
| **Riesgos** | Tiempo de ejecución largo si se incluye `solution check`. Mitigación: correrlo solo en push a main, no en cada PR |
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

### S0-10 — Seed data inicial para catálogos

| Campo | Contenido |
|---|---|
| **Objetivo** | Tener un script que pueble los catálogos básicos para que cualquier desarrollador pueda trabajar en su ambiente |
| **Alcance** | Implementar `scripts/seed-data.ps1` que: cree centros de costo iniciales, plantillas de correo básicas, parámetros de sistema (umbral de escalamiento, días de recordatorio), miembros del Comité de prueba. Usar PAC CLI o Web API. Idempotente (no duplica si ya existen) |
| **Criterios de aceptación** | (1) Script corre sin error sobre DEV vacío. (2) Re-ejecutarlo no duplica datos. (3) Datos seed documentados en `scripts/README.md` |
| **Validaciones requeridas** | Test sobre environment limpio. Test de re-ejecución |
| **Riesgos** | Datos seed con info sensible de empresas reales. Mitigación: usar nombres ficticios o placeholder |
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
