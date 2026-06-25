# INNOVA — Project context for Claude Code

> ⚠️ **Repositorio en mantenimiento (Power Platform).** El desarrollo activo
> continúa en el producto React + .NET: https://github.com/rcrala/innova
> (ver ADR-0006). Aplica cambios aquí solo para soporte de la versión Power
> Platform existente.

This file gives Claude Code the context it needs to be productive in this repository. Keep it short, accurate, and updated as the project evolves. When in doubt, prefer this file over assumptions.

## What is INNOVA?

INNOVA is a corporate workflow platform for managing project initiatives at Grupo Pasquí (Costa Rica). It standardizes how initiatives flow from a Requester through PMO evaluation, optional IT estimation, Line Management approval, PMO execution, vendor quotations, and final approval by General Management or the Projects Committee.

The application replaces email + Excel processes with a single, auditable, traceable platform across all Grupo Pasquí companies.

## Tech stack

- Microsoft Power Platform (Dataverse, Power Apps Canvas, Power Automate, Power BI)
- Microsoft Entra ID for SSO
- SharePoint Online for document storage
- PAC CLI (Power Platform CLI) for ALM
- GitHub for git hosting and GitHub Actions for CI/CD
- Claude Code with `microsoft/power-platform-skills` plugins
- C# Dataverse plug-ins only when Power Fx + Power Automate cannot handle the case
- PCF Controls (TypeScript + React) only when standard Canvas controls are insufficient

## Repository layout

```
.claude/              Claude Code settings and agent configs
docs/                 Architecture, ADRs, conventions, glossary
solutions/            Power Platform Solutions (unpacked)
  innova-core/        Tables, columns, relationships, security roles
  innova-flows/       Power Automate cloud flows
  innova-canvas/      Canvas apps (unpacked YAML)
  innova-reports/     Power BI reports and dashboards
pcf/                  PCF Controls (TypeScript + React)
plugins/              Dataverse plug-ins (C#)
scripts/              Bootstrap, deploy, and dev scripts
tests/                Test plans and automated tests
.github/workflows/    CI/CD pipelines
```

## Critical commands

```bash
# Authentication
pac auth list
pac auth create --name innova-dev --environment <env-url>
pac auth select --name innova-dev

# Solutions (export from DEV, then unpack and commit)
pac solution list
pac solution export --name innova-core --path ./exported/innova-core.zip
pac solution unpack --zipfile ./exported/innova-core.zip \
    --folder ./solutions/innova-core --packagetype Unmanaged

# Solutions (pack for QA/PROD deployment)
pac solution pack --folder ./solutions/innova-core \
    --zipfile ./out/innova-core.zip --packagetype Managed
pac solution import --path ./out/innova-core.zip

# Canvas Apps
pac canvas unpack --msapp App.msapp --sources solutions/innova-canvas/Canvas/App
pac canvas pack --sources solutions/innova-canvas/Canvas/App --msapp App.msapp

# PCF Controls
pac pcf init --namespace Pasqui --name MyControl --template field
pac pcf push --publisher-prefix pas

# Plugins
pac plugin push
```

See `docs/runbooks/` for environment-specific runbooks.

## Naming and prefix conventions

Publisher prefix is `pas` (Pasquí). Every Dataverse customization carries this prefix. The full reference lives in `docs/conventions/dataverse-naming.md`; the rules below are the short version.

### Tables

- Format: `pas_<entity>` in singular, lowercase, no underscores between words within the entity name
- Examples: `pas_iniciativa`, `pas_cotizacion`, `pas_evaluacionpmo`, `pas_horatrabajo`
- Display name in Spanish: "Iniciativa", "Cotización"

### Columns

- Format: `pas_<column>` in snake_case
- Examples: `pas_consecutivo`, `pas_monto_estimado`, `pas_fecha_aprobacion`, `pas_requiere_desarrollo`
- Lookups: `pas_<target>_ref` when name is ambiguous, otherwise `pas_<target>`
- Status columns: `pas_estado` (always use Choice, never plain text)
- Money columns: always pair with a currency lookup

### Power Apps and Flows

- Apps: `INNOVA - <Module>` — e.g. `INNOVA - Tracking Mis Solicitudes`
- Flows: `INNOVA - <Trigger> - <Purpose>` — e.g. `INNOVA - Iniciativa Creada - Notificar PMO`
- Child flows: `INNOVA - Helper - <Purpose>` — e.g. `INNOVA - Helper - Enviar Correo con Plantilla`

### Files

- Markdown: kebab-case (`data-model.md`)
- PowerShell: kebab-case (`seed-data.ps1`)
- C#: PascalCase (`IniciativaCreatedPlugin.cs`)
- TypeScript: kebab-case for files, PascalCase for components

## Power Fx style (short version)

- Variables in PascalCase prefixed by scope: `gblUserRole` (global), `locFormState` (context), `colIniciativasFiltered` (collection)
- Use `;;` for multi-statement formulas, never `;`
- Prefer `Patch()` for record updates; never use `Collect()` to add rows to a Dataverse table (use `Patch` with `Defaults(table)`)
- Always check `IsBlank()` or `IsEmpty()` before accessing record fields from filtered collections
- Use App.Formulas (named formulas) for reusable expressions
- Filter must be delegable when querying tables that may exceed 2000 rows

Full guide: `docs/conventions/power-fx-style.md`.

## Power Automate style (short version)

- Wrap external calls (HTTP, connectors) in a `Scope` with `Configure run after` for error handling
- Use service principal authentication for the Dataverse connector wherever possible
- Use child flows for reusable logic (email templates, role-based notifications)
- Set retry policy on every external action (default `Fixed 10s × 4`)
- Name actions descriptively — never leave "Compose 2" or "Send email 5"
- Use `triggerOutputs()?['body/...']` instead of dynamic content tokens when renaming actions

Full guide: `docs/conventions/power-automate-style.md`.

## Definition of Done

Every PR must:

- Originate from an issue (`Refs #<id>` in every commit, `Closes #<id>` in the final commit) — see `docs/conventions/github-workflow.md`
- Branch from `main` updated, named `issue-<id>-<stream>-<short-topic>`
- Be reviewed by at least one other developer
- Have tests added or updated (unit tests for plugins, smoke tests for flows)
- Include exported, unpacked solution sources committed to git
- Update `CHANGELOG.md` (Keep a Changelog format)
- Update relevant docs if the schema or API changed
- Pass the CI pipeline (`.github/workflows/ci.yml`)
- Include a manual smoke-test log in the PR description
- Branch deleted (local and remote) after merge

## Common workflows

### Add a new Dataverse table

1. Open `docs/architecture/data-model.md` to confirm the conceptual schema
2. Create the table in DEV via the maker portal or `pac` CLI
3. Apply naming conventions strictly (`pas_<table>`)
4. Add security role permissions for each of the 7 INNOVA roles
5. Export the `innova-core` solution and unpack into `solutions/innova-core/`
6. Update `docs/architecture/data-model.md`
7. Add a smoke test in `tests/`

### Modify a Canvas App

1. `pac canvas unpack` the existing `.msapp`
2. Edit the YAML files in the unpacked directory
3. Validate against `docs/conventions/power-fx-style.md`
4. `pac canvas pack` to re-create the `.msapp`
5. Import into DEV environment via solution
6. Smoke test
7. Re-export the `innova-canvas` solution, unpack, commit

### Add a Power Automate flow

1. Decide: top-level trigger or child flow
2. Name per convention
3. Build in DEV environment using the maker portal (faster than YAML for complex flows)
4. Set connection references to service principal where possible
5. Include the error-handling `Scope` pattern
6. Test with multiple scenarios (including failure paths)
7. Export, unpack, commit

### Write a PCF Control

1. Check `docs/conventions/power-fx-style.md` for our patterns
2. `pac pcf init --namespace Pasqui --name <Name> --template field|dataset`
3. Use React functional components with hooks
4. TypeScript strict mode (no `any`)
5. Test in the test harness: `npm start`
6. `pac pcf push --publisher-prefix pas`

## Domain glossary (short)

The business operates in Spanish. UI labels are always in Spanish. Code, column names, and technical docs use English when there is a clean translation; Spanish when the term is canonical (Iniciativa, PMO, Comité).

| Spanish | English | Notes |
|---|---|---|
| Iniciativa | Initiative | Core entity. Table: `pas_iniciativa`. |
| Solicitante | Requester | User who creates the initiative. |
| Patrocinador | Sponsor | Executive backing the initiative. |
| Jefatura | Line Manager | The Solicitante's direct supervisor. |
| PMO | Project Management Office | Evaluates and executes initiatives. |
| Comité | Projects Committee | High-stakes approval body. Unanimous vote required. |
| Cotización | Quote | Vendor or internal cost estimate. |
| Levantamiento | Discovery | PMO's requirements analysis phase. |
| Ejecución | Execution | PMO's documented implementation phase. |
| Estimación | Estimation | Effort or cost estimate from PMO or IT. |
| Centro de costo | Cost Center | Used to charge hours and money. |
| ROI | Return on Investment | `(Annual Savings − Project Cost) / Project Cost × 100` |
| Empresa | Company | One of the Grupo Pasquí business units. |

Full glossary: `docs/glossary.md`.

## Important rules and "don'ts"

- NEVER commit credentials, connection strings, App Registration secrets, or `.pfx` files
- NEVER hardcode tenant IDs or environment GUIDs in source — use environment variables in Power Automate
- NEVER use English for UI labels in Canvas Apps — the users speak Spanish
- NEVER use `;` to chain Power Fx statements — that is `;;`
- NEVER add a new column without the `pas_` prefix
- NEVER modify the `Default Solution` directly — always work in our named solutions
- ALWAYS specify currency on money columns
- ALWAYS include audit-trail columns (`createdon`, `createdby`, `modifiedon`, `modifiedby`) — these are automatic in Dataverse but verify they are not stripped
- ALWAYS ask before introducing a new NuGet, npm, or PCF dependency

## References

- `docs/architecture/00-overview.md` — Architecture overview
- `docs/architecture/data-model.md` — Dataverse data model (to be filled in by Sprint 0)
- `docs/decisions/` — Architecture Decision Records (ADRs)
- `docs/glossary.md` — Full domain glossary
- `docs/conventions/` — Detailed coding conventions
- `docs/runbooks/` — Operational runbooks (deploy, rollback)
- External: `WBS_INNOVA.xlsx` — Work breakdown structure (143 tasks)
- External: `Analisis_INNOVA.docx` — Project analysis and module specs

## How to work with this codebase

When asked to implement a feature, follow this checklist:

1. **Read the WBS** — find the task in `WBS_INNOVA.xlsx` to understand acceptance criteria and effort budget
2. **Check ADRs** — see if any decision in `docs/decisions/` constrains the approach
3. **Read existing code** — look for similar patterns in `solutions/` before inventing new ones
4. **Apply conventions** — `docs/conventions/` is authoritative
5. **Ask before new dependencies** — never add libraries without confirmation
6. **Test locally** — DEV environment first, never PROD
7. **Document changes** — update `CHANGELOG.md` and docs as part of the same PR

Stay focused, ask clarifying questions when business rules are ambiguous, and prefer simple Power Fx + Power Automate solutions over custom PCF or plugins when both can solve the problem.

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
| ------ | ---------- |
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.
