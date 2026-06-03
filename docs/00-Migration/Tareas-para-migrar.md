# Tarea: Migrar source control de Canvas Apps a Power Platform Git Integration

## Contexto del problema

El repo instruye actualmente usar `pac canvas unpack` y `pac canvas pack` para
hacer source control de Canvas Apps con archivos YAML editados a mano. Microsoft
deprecó estos comandos. Evidencia oficial (verificar con web_fetch si tienes
dudas):

- https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/canvas
  Cita: "The pack and unpack commands are deprecated. To source control your
  canvas app, use the Power Platform Git Integration."
- https://www.microsoft.com/en-us/power-platform/blog/power-apps/git-integration-is-generally-available/
  Git Integration GA desde abril 2025, schema pa.yaml publicado.
- https://github.com/microsoft/PowerApps-Language-Tooling
  PASopa "is no longer supported".

El reemplazo es **Power Platform Git Integration** (alias Dataverse Git
Integration). Conecta el ambiente Dataverse al repo Azure DevOps, sincroniza
pa.yaml desde Power Apps Studio automáticamente, y resuelve merge conflicts
en la UI. No requiere unpack/pack manual.

## Cambios requeridos

### 1. CLAUDE.md

- Elimina cualquier mención a `pac canvas unpack` y `pac canvas pack` de la
  sección "Critical commands"
- Reemplaza el bloque de comandos Canvas por una nueva subsección
  "Canvas Apps source control (Git Integration)" con este flujo:
  - El admin conecta el ambiente DEV con el repo Azure DevOps una sola vez
  - Los makers editan en Power Apps Studio
  - Studio sincroniza pa.yaml con Git al guardar (commit desde el panel
    "Source control" del Studio o desde Azure DevOps)
  - Para traer cambios del repo al ambiente: "Pull" desde Studio
  - Los pa.yaml viven en el repo pero NUNCA se editan a mano
- En "Common workflows → Modify a Canvas App": reemplaza los pasos de
  unpack/pack por: abrir Studio, editar, guardar/commit, PR review en
  Azure DevOps
- Mantén intactas las secciones de Dataverse naming, Power Fx style,
  Power Automate style, plug-ins (`pac plugin push` sigue válido) y
  PCF (`pac pcf push` sigue válido)

### 2. Nuevo ADR-0005

Path: `docs/decisions/0005-power-platform-git-integration.md`

Usa el formato del `_template.md` existente. Contenido:

- Status: Aceptado, fecha de hoy
- Contexto: explica que el flujo original con `pac canvas unpack/pack` era
  frágil (YAML manual rompía el parsing, entropy.json causaba merge conflicts
  irresolubles, dependencias de componentes no roundtripeaban), y que
  Microsoft deprecó ambos comandos en 2025-2026 con Git Integration GA como
  reemplazo oficial
- Decisión: adoptar Power Platform Git Integration como único mecanismo de
  source control para todos los artefactos de Power Platform (Canvas,
  Model-Driven, Flows)
- Consecuencias positivas: schema pa.yaml publicado sin breaking changes,
  merge conflicts en UI, sincronización automática, sin tooling adicional,
  trazabilidad mantenida
- Consecuencias negativas: setup admin obligatorio antes de empezar
  desarrollo, los pa.yaml no se editan a mano (Studio es source of truth),
  desarrolladores deben aprender el panel Source Control de Studio
- Alternativas consideradas (con razón por la que no se eligieron):
  pac canvas unpack/pack (deprecado), PASopa (deprecado), exportar solution.zip
  + diff manual (sin trazabilidad real)

Actualiza `docs/decisions/README.md` agregando ADR-0005 al índice.

### 3. Nuevo runbook

Path: `docs/runbooks/00-git-integration-setup.md`

Verifica los pasos exactos con web_fetch a:
https://learn.microsoft.com/en-us/power-platform/alm/git-integration/connecting-to-git

Cubre:

- Prerrequisitos (permisos de System Admin en el ambiente, permisos en
  Azure DevOps Project, repo creado vacío)
- Pasos en Power Platform Admin Center para conectar ambiente DEV al repo
- Selección de la carpeta destino del solution dentro del repo
- Primera sincronización (push inicial)
- Validación: hacer un cambio menor en Studio, ver que aparezca el commit
- Troubleshooting de los 2-3 errores comunes documentados

### 4. scripts/bootstrap.ps1

- Elimina cualquier referencia a `pac canvas unpack` o `pac canvas pack`
- Añade un comentario al final que diga:
  "# El setup de Git Integration es una operación de admin del tenant.
   # Ver docs/runbooks/00-git-integration-setup.md antes de empezar a desarrollar."

### 5. docs/conventions/power-fx-style.md

Añade un párrafo al inicio del documento, justo después del título:

"Estas convenciones aplican al código Power Fx que Power Apps Studio escribe
en los archivos pa.yaml del repo. Los pa.yaml NO se editan a mano: Power Apps
Studio es source of truth para Canvas Apps. Las convenciones se hacen cumplir
durante el desarrollo dentro del Studio y se validan en el code review del PR."

### 6. README.md

En la sección "Empezar → Setup", reemplaza cualquier mención a unpack/pack
manual por una referencia al runbook de Git Integration. Añade un bullet
nuevo en los pasos de setup: "El admin del tenant debe haber conectado el
ambiente DEV con el repo (ver `docs/runbooks/00-git-integration-setup.md`)
antes de que el equipo empiece a desarrollar."

### 7. CHANGELOG.md

Bajo `## [Unreleased]`, crea o usa la subsección `### Changed`:

- "Source control de Canvas Apps migrado de `pac canvas unpack/pack`
  (deprecado por Microsoft) a Power Platform Git Integration. Ver ADR-0005."

## Definition of Done

Después de aplicar todos los cambios, verifica que:

- [ ] `grep -ri "pac canvas unpack" .` no devuelve resultados
- [ ] `grep -ri "pac canvas pack" .` no devuelve resultados (excepto si
      aparece en un ADR como referencia histórica al método deprecado)
- [ ] `docs/decisions/0005-power-platform-git-integration.md` existe
- [ ] `docs/decisions/README.md` lista ADR-0005
- [ ] `docs/runbooks/00-git-integration-setup.md` existe con pasos verificables
- [ ] `CHANGELOG.md` tiene la entrada en Unreleased → Changed
- [ ] El repo sigue siendo coherente (sin referencias rotas entre archivos)

## Commit

Un solo commit con este mensaje (Conventional Commits, scope `alm`):

Título: docs(alm): migrate source control to Power Platform Git Integration

Cuerpo:
Microsoft deprecated pac canvas unpack/pack in 2025-2026. The replacement
is Power Platform Git Integration, GA since April 2025, with published
pa.yaml schema and no breaking changes anticipated.

- Update CLAUDE.md to remove deprecated commands and document the new flow
- Add ADR-0005 with the architectural decision and trade-offs
- Add runbook 00-git-integration-setup.md for the admin connection step
- Clean scripts/bootstrap.ps1 of obsolete references
- Update README, power-fx-style and CHANGELOG accordingly

Refs: ADR-0005

## Idioma

Mantén el idioma actual de cada archivo: CLAUDE.md sigue en inglés, ADRs y
runbooks y conventions en español. README en español.

## Si encuentras algo inesperado

Si al hacer web_fetch verificas que algo cambió desde febrero 2026 (por
ejemplo, un nuevo comando recomendado), prefiere la documentación oficial
más reciente sobre estas instrucciones y documenta la desviación en el
commit message.