# Fase 0 — Alineación

> **Duración estimada**: 1 semana
> **Objetivo**: Dejar listas todas las convenciones, herramientas y decisiones que el resto del proyecto va a asumir como dado.

## Salidas esperadas

1. Directriz GitHub adoptada formalmente como convención del repo
2. Labels, plantillas de issue y plantilla de PR creadas en GitHub
3. `.mcp.json` y `.claude/settings.json` portables (sin rutas hardcodeadas a una máquina)
4. Decisión documentada sobre cuándo y cómo se aprovisiona PROD

## Issues a abrir en GitHub

### Issue #1 — Adopción de la directriz GitHub workflow

| Campo | Contenido |
|---|---|
| **Objetivo** | Establecer la directriz GitHub como convención oficial del repo, eliminar contradicciones existentes |
| **Alcance** | Mover `docs/15-Directriz/20260521-github-workflow.md` → `docs/conventions/github-workflow.md`. Reconciliar con `docs/conventions/commit-messages.md` (debe ser referencia, no duplicado). Actualizar `README.md` (sección "Flujo de contribución") y `CLAUDE.md` (Definition of Done) |
| **Criterios de aceptación** | (1) La directriz vive en `docs/conventions/`. (2) `commit-messages.md` referencia la directriz para el footer `Refs #<id>`. (3) `README.md` describe el flujo: branch desde `main`, issue primero, PR con evidencia. (4) `CLAUDE.md` Definition of Done incluye `Refs #<id>` en commits. (5) No queda mención a `develop` ni a `dev-cfg` en ningún doc |
| **Validaciones requeridas** | `grep -r "develop\|dev-cfg" docs/ README.md CLAUDE.md` debe devolver vacío. Lectura cruzada de los 4 documentos sin contradicciones |
| **Riesgos** | Romper enlaces existentes a `docs/15-Directriz/`. Mitigación: dejar redirect markdown o validar grep de enlaces |
| **Labels** | `activity`, `p1`, `docs` |
| **Branch sugerido** | `issue-<id>-docs-adoptar-directriz-github` |

### Issue #2 — Setup GitHub Issues (labels + plantillas)

| Campo | Contenido |
|---|---|
| **Objetivo** | Tener labels y plantillas listas para abrir issues del proyecto con metadata consistente |
| **Alcance** | Crear labels (`activity`, `bug`, `p0`, `p1`, `p2`, streams `core`/`canvas`/`flows`/`reports`/`pcf`/`plugins`/`docs`/`ci`, `epic`, `blocked`). Crear `.github/ISSUE_TEMPLATE/activity.yml` con los 5 campos de la directriz. Crear `.github/ISSUE_TEMPLATE/bug.yml`. Crear `.github/pull_request_template.md` con la estructura de la directriz |
| **Criterios de aceptación** | (1) Al abrir nuevo issue en GitHub, se ofrece elegir entre "Activity" y "Bug" con los campos prellenados. (2) Al abrir un PR, la descripción viene prellenada con Resumen / Issues / Evidencia / Riesgos. (3) `gh label list` muestra todos los labels definidos |
| **Validaciones requeridas** | Probar creando un issue de prueba con el template (luego cerrarlo). Probar PR draft con el template |
| **Riesgos** | Conflictos con labels que GitHub crea por default. Mitigación: borrar o renombrar los default no usados |
| **Labels** | `activity`, `p1`, `ci` |
| **Branch sugerido** | `issue-<id>-ci-templates-github` |

### Issue #3 — Portabilidad de .mcp.json y .claude/settings.json

| Campo | Contenido |
|---|---|
| **Objetivo** | Eliminar rutas absolutas hardcodeadas (`/home/randal/...`, `/mnt/c/Randall/...`) que impiden que otros developers puedan usar el repo |
| **Alcance** | (a) `.mcp.json`: decidir si `code-review-graph` se asume disponible vía `code-review-graph` en PATH o vía variable de entorno. (b) `.claude/settings.json`: los hooks usan `/mnt/c/Randall/...` como `--repo`, debe ser `.` o variable. (c) Crear `docs/setup-mcp.md` con instrucciones de instalación en Windows nativo y en WSL |
| **Criterios de aceptación** | (1) Cualquier developer puede clonar el repo y, siguiendo `docs/setup-mcp.md`, dejar funcionando Claude Code sin editar los archivos commiteados. (2) `git diff` después de un clone fresco no muestra cambios en estos archivos. (3) Los hooks siguen ejecutándose correctamente |
| **Validaciones requeridas** | Test manual: clonar el repo en una segunda ubicación y verificar que Claude Code arranca sin errores |
| **Riesgos** | Que `code-review-graph` no exponga forma de configurar el `--repo` dinámicamente. Mitigación: si no, dejar variable de entorno documentada |
| **Labels** | `activity`, `p2`, `ci` |
| **Branch sugerido** | `issue-<id>-ci-mcp-portabilidad` |

### Issue #4 — ADR-0004 estrategia de entrega al tenant del cliente

| Campo | Contenido |
|---|---|
| **Objetivo** | Definir la estrategia completa de entrega al tenant del cliente, dado que PROD no vive en GTC sino en el tenant de Grupo Pasquí |
| **Alcance** | Crear `docs/decisions/0004-entrega-cliente.md` (ADR) y `docs/architecture/entrega-cliente.md` (guía operativa). Actualizar `docs/architecture/00-overview.md` (sección Ambientes). Ampliar Sprint 0 issues S0-5 (Environment Variables + Deployment Settings JSON) y S0-6 (CI/CD produce GitHub Release entregable). Agregar historia M14-H1b (acompañamiento primer import en cliente). Quitar PROD de `scripts/bootstrap.ps1` |
| **Criterios de aceptación** | (1) ADR-0004 aprobado por Tech Lead y Patrocinador. (2) `entrega-cliente.md` cubre prerrequisitos, secuencia de import, Environment Variables, Connection References, rollback. (3) Sprint 0 y M14 reflejan el modelo de entrega. (4) `bootstrap.ps1` sin referencia a PROD |
| **Validaciones requeridas** | Revisión cruzada por Tech Lead. Validación con admin Power Platform del cliente de los prerrequisitos listados |
| **Riesgos** | Cliente sin licencias adecuadas o sin Service Principal. Mitigación: validar prerrequisitos en sesión kickoff con el cliente |
| **Labels** | `activity`, `p1`, `docs` |
| **Branch sugerido** | `issue-<id>-docs-estrategia-entrega-cliente` |

## Orden recomendado

```
Issue #1 (directriz)  →  Issue #2 (templates)  →  Issue #3 (MCP)  →  Issue #4 (PROD)
       ↓                       ↓
   merge a main          merge a main
```

Issue #1 primero porque condiciona los issues #2-#4 (definen los templates y el flow).

## Definition of Done de Fase 0

- 4 issues cerrados con PR mergeado
- README.md y CLAUDE.md alineados con la directriz
- Labels y plantillas funcionando en GitHub
- ADR-0004 publicado
- Branch `wip-20260523-create-plan` mergeado y eliminado (este plan)
- Tablero/Project board de GitHub creado con los hitos del roadmap

## Salida hacia Sprint 0

Cuando Fase 0 cierre, el equipo puede abrir issues de Sprint 0 con confianza de que las convenciones están establecidas. Ver [sprint-0-bootstrap.md](sprint-0-bootstrap.md).
