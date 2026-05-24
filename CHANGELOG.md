# Changelog

Todos los cambios notables de INNOVA se documentan aquí.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/), y el versionado sigue [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Changed
- **Modelo v1.4**: reconciliados los 17 labels de `pas_iniciativa_estado` con el cuadro resumen del cliente (EPIC #27, issue #33). Values numéricos preservados (no había datos en DEV/QA). 16 labels actualizados via `UpdateOptionValue` API. Nueva función `Update-DataverseGlobalOptionSetLabel` en `scripts/setup/lib/dataverse.ps1`. Script `02-create-choice-sets.ps1` ahora también sincroniza labels en option sets existentes (no solo crea nuevos)

### Added
- **Modelo v1.3**: nueva tabla `pas_sistema` (catálogo de sistemas integrables hijo de `pas_empresa`) + tabla puente N:M `pas_iniciativa_sistema` (UserOwned). Alineación con requerimiento del cliente G2 (EPIC #27, issue #29): "Sistemas a integrar: lista desplegable parametrizable, catálogo por compañía, selección múltiple". Bridge usa Cascade Delete hacia `pas_iniciativa` (cleanup automático) y Restrict hacia `pas_sistema` (protege catálogo). Aplicado en DEV (2 tablas + 3 relaciones + 29 privilegios nuevos → 189 totales)
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
