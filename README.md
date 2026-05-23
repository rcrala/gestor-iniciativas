# INNOVA

**Plataforma Corporativa de Iniciativas — Grupo Pasquí**

INNOVA estandariza el ciclo completo de gestión de iniciativas de proyectos, desde el registro inicial por parte del solicitante hasta la aprobación final por la Gerencia General o el Comité de Proyectos.

## Stack tecnológico

- Microsoft Power Platform: Dataverse, Power Apps Canvas, Power Automate, Power BI
- Microsoft Entra ID (SSO)
- SharePoint Online (gestión documental)
- PAC CLI para ALM
- GitHub (Git + GitHub Actions)
- Claude Code con plugins oficiales de Microsoft Power Platform

## Roles del sistema

| # | Rol | Función principal |
|---|---|---|
| 1 | Solicitante | Registra iniciativas |
| 2 | PMO | Evalúa y ejecuta iniciativas |
| 3 | TI / Desarrollo | Estima desarrollos cuando aplica |
| 4 | Jefatura del Solicitante | Aprueba estimación e iniciativa ejecutada |
| 5 | Gerencia General | Aprueba bajo el umbral de escalamiento |
| 6 | Comité de Proyectos | Aprueba (unanimidad) cuando se escala |
| 7 | Administrador | Mantiene catálogos y parámetros del sistema |

## Empezar

### Prerrequisitos

- Windows 10/11, macOS o Linux
- PowerShell 7+ (Windows o Core)
- [PAC CLI](https://learn.microsoft.com/power-platform/developer/cli/introduction)
- Node.js 20+
- .NET 8 SDK
- Git
- Cuenta con permisos en el tenant de Grupo Pasquí

### Setup

```powershell
# Clonar el repositorio
git clone <url-del-repo> innova
cd innova

# Ejecutar el bootstrap
pwsh ./scripts/bootstrap.ps1
```

El script valida prerrequisitos, autentica contra Entra ID y configura los perfiles de PAC CLI contra los ambientes DEV/QA/PROD.

### Desarrollo con Claude Code

Este repositorio está optimizado para uso con [Claude Code](https://claude.com/code). El archivo `CLAUDE.md` contiene el contexto necesario para que Claude Code entienda la arquitectura, convenciones y flujos del proyecto.

```bash
# Instalar los plugins oficiales de Microsoft Power Platform
claude plugin install canvas-apps@power-platform-skills
claude plugin install model-apps@power-platform-skills
claude plugin install code-apps@power-platform-skills
```

## Estructura del repositorio

```
.claude/              # Configuración de Claude Code
docs/                 # Arquitectura, ADRs, convenciones, glosario
solutions/            # Power Platform Solutions (desempaquetadas)
pcf/                  # PCF Controls (TypeScript + React)
plugins/              # Plug-ins de Dataverse (C#)
scripts/              # Scripts de bootstrap, despliegue y desarrollo
tests/                # Planes y casos de prueba
.github/workflows/    # CI/CD
```

## Documentación clave

- [Arquitectura general](docs/architecture/00-overview.md)
- [Modelo de datos](docs/architecture/data-model.md) (pendiente — Sprint 0)
- [Decisiones arquitectónicas (ADRs)](docs/decisions/)
- [Glosario del dominio](docs/glossary.md)
- [Convenciones de naming Dataverse](docs/conventions/dataverse-naming.md)
- [Estilo de Power Fx](docs/conventions/power-fx-style.md)
- [Estilo de Power Automate](docs/conventions/power-automate-style.md)
- [Convención de commits](docs/conventions/commit-messages.md)

## Flujo de contribución

1. Crear branch desde `develop`: `feature/<modulo>-<tarea-corta>` (ejemplo: `feature/m2-pantalla-solicitante`)
2. Seguir convenciones en `docs/conventions/`
3. Ejecutar pruebas locales antes de PR
4. PR contra `develop` con descripción del cambio y screenshots cuando aplique
5. Code review obligatorio por al menos un colega
6. Merge tras CI verde y aprobación

## Equipo

Configuración inicial recomendada (Escenario 2 del roadmap):

| Recurso | Rol | Tiempo |
|---|---|---|
| R1 | Tech Lead / Arquitecto Power Platform | 100% |
| R2 | Desarrollador Power Platform | 100% |
| R3 | Functional & Project Lead | 100% |

Si el escenario cambia, actualizar este README y los ADRs correspondientes.

## Licencia

Propiedad de Grupo Pasquí. Uso interno. No distribuir.
