# Changelog

Todos los cambios notables de INNOVA se documentan aquí.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/), y el versionado sigue [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Added
- **Modelo v1.2**: nueva tabla `pas_departamento` (catálogo de departamentos hijo de `pas_empresa`) — alineación con requerimiento del cliente G1 (EPIC #27, issue #28). Soft-delete pattern (`pas_activo`). Filtrado por empresa en la UI vía relación N:1 `pas_departamento_empresa`. Permisos: Read Global para los 7 roles + CRUD Global para `INNOVA Administrador`. Aplicado en DEV (1 tabla + 1 relación + 12 privilegios nuevos → 160 totales)
- Análisis del requerimiento del cliente (docs/01-Requeriments/) con respuestas C1-C6 incorporadas (PR #36)
- EPIC #27 "Modelo v1.2 alineación con requerimientos cliente" + 8 issues hijos (#28-#35)
- Estructura inicial del repositorio
- `CLAUDE.md` con contexto del proyecto para Claude Code
- `AGENTS.md` como quickstart operativo para agentes de IA
- Skill de ejecución estandarizada de historias: `.claude/skills/deliver-story-innova/skill.md`
- Documentación de arquitectura: visión general, modelo de datos (placeholder)
- ADRs 0001 (stack Power Platform), 0002 (adopción Claude Code), 0003 (Business Units por empresa)
- Convenciones: naming Dataverse, estilo Power Fx, estilo Power Automate, mensajes de commit
- Glosario del dominio (español/inglés)
- Runbook operativo de historia piloto: `docs/runbooks/08-historia-piloto-notificacion-pmo.md`
- Script de bootstrap del ambiente de desarrollo (`scripts/bootstrap.ps1`)
- Configuración de Claude Code (`.claude/settings.json`)
- Pipeline CI placeholder (`.github/workflows/ci.yml`)
