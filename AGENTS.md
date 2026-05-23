# AGENTS.md

## INNOVA Agent Quickstart

This repository uses Microsoft Power Platform for enterprise initiative management at Grupo Pasqui.
Use this file as the operational entry point, then follow linked docs instead of duplicating rules.

## Start Here

1. Project context and primary rules: [CLAUDE.md](CLAUDE.md)
2. Architecture and boundaries: [docs/architecture/00-overview.md](docs/architecture/00-overview.md)
3. ADR constraints: [docs/decisions/README.md](docs/decisions/README.md)
4. Data model status (Sprint 0 placeholder): [docs/architecture/data-model.md](docs/architecture/data-model.md)

## Authoritative Conventions

- Dataverse naming: [docs/conventions/dataverse-naming.md](docs/conventions/dataverse-naming.md)
- Power Fx style: [docs/conventions/power-fx-style.md](docs/conventions/power-fx-style.md)
- Power Automate style: [docs/conventions/power-automate-style.md](docs/conventions/power-automate-style.md)
- Commit style: [docs/conventions/commit-messages.md](docs/conventions/commit-messages.md)
- Domain glossary (Spanish terms): [docs/glossary.md](docs/glossary.md)

## Working Order (Default)

1. Read WBS and ADR constraints from [CLAUDE.md](CLAUDE.md).
2. Reuse existing patterns under solutions before introducing new ones.
3. Prefer low-code first:
   - Power Fx + Dataverse
   - Power Automate child flows
   - PCF only when standard controls are insufficient
   - C# plugins only when Power Fx + Power Automate cannot solve the case
4. Update docs and changelog in the same change set.

## Critical Non-Negotiables

- All Dataverse custom objects must use the pas_ prefix.
- UI labels must be in Spanish.
- Never use semicolon as Power Fx multi-statement separator; use double-semicolon only.
- Never hardcode tenant IDs, environment GUIDs, secrets, or certificates.
- Ask before adding new npm, NuGet, or other external dependencies.
- Never work in Dataverse Default Solution; use named solutions only.

## Common Commands

Use the scripts and solution docs as source of truth:
- Environment bootstrap: [scripts/bootstrap.ps1](scripts/bootstrap.ps1)
- Solution ALM workflow: [solutions/README.md](solutions/README.md)
- Test strategy and commands: [tests/README.md](tests/README.md)

Common command families used in this repo:
- pac auth list, pac auth create/select
- pac solution export/unpack, pack/import
- pac canvas unpack/pack
- pac pcf init/push
- pac plugin push
- dotnet test, npm test, npx playwright test

## Module Boundaries

- Core schema and security first: [solutions/innova-core/README.md](solutions/innova-core/README.md)
- Flows orchestration next: [solutions/innova-flows/README.md](solutions/innova-flows/README.md)
- Canvas app after flows/core: [solutions/innova-canvas/README.md](solutions/innova-canvas/README.md)
- Reporting on top: [solutions/innova-reports/README.md](solutions/innova-reports/README.md)

## Quality Gate Before Finishing

- Tests added or updated where applicable.
- Relevant docs updated when schema/API/behavior changes.
- CHANGELOG updated: [CHANGELOG.md](CHANGELOG.md)
- Exported and unpacked solution artifacts committed when solution content changes.

## If Information Is Missing

- Do not invent schema details if they are not documented.
- Raise assumptions explicitly and request clarification for ambiguous business rules.
- Prefer linking to existing docs rather than embedding long guidance.

## Workspace Skills

- Story delivery workflow: [.claude/skills/deliver-story-innova/skill.md](.claude/skills/deliver-story-innova/skill.md)
