# M14 — Cierre, runbooks y training

> **Tipo**: Módulo de cierre
> **Stream**: `docs`

## Objetivo de negocio

Asegurar que INNOVA quede operable por el equipo de soporte y por los usuarios sin necesidad de los desarrolladores originales.

## Historias de usuario (issues GitHub)

### M14-H1 — Runbook consolidado de operación

| Campo | Contenido |
|---|---|
| **Objetivo** | Runbook único que cubra los flujos críticos de operación post-lanzamiento: deploy a PROD, rollback, alta de usuario, baja de usuario, cambio de BU, recovery de errores comunes |
| **Alcance** | `docs/runbooks/00-operacion-prod.md` con secciones por escenario, comandos PAC, capturas, criterios de éxito |
| **Criterios de aceptación** | (1) Runbook cubre 10+ escenarios. (2) Validado ejecutándolo en QA. (3) Aprobado por equipo de soporte |
| **Validaciones** | Walkthrough con equipo de soporte |
| **Riesgos** | Documentación que se desactualiza. Mitigación: revisión trimestral programada |
| **Labels** | `activity`, `p0`, `docs` |

### M14-H2 — Training para usuarios finales (por rol)

| Campo | Contenido |
|---|---|
| **Objetivo** | Materiales de training por rol: Solicitante, PMO, TI, Jefatura, Gerencia, Comité, Administrador |
| **Alcance** | Una guía PDF + video corto (5-10 min) por rol. Incluye casos de uso comunes y FAQ |
| **Criterios de aceptación** | (1) 7 guías + 7 videos. (2) Hosteado en SharePoint/Teams accesible. (3) Sesión de kick-off realizada |
| **Validaciones** | Encuesta post-training (≥ 80% satisfacción) |
| **Riesgos** | Materiales que envejecen con cambios. Mitigación: vincular a versión del sistema |
| **Labels** | `activity`, `p0`, `docs` |

### M14-H3 — Plan de soporte post-go-live

| Campo | Contenido |
|---|---|
| **Objetivo** | Definir SLA, canales (Teams, correo, ticket), responsabilidades de soporte L1/L2/L3, escalamiento a Microsoft |
| **Alcance** | `docs/runbooks/99-soporte-postgolive.md` con SLA, on-call rotation, contactos clave |
| **Criterios de aceptación** | (1) SLA acordado con stakeholder. (2) On-call definido para primeros 60 días. (3) Contactos Microsoft documentados |
| **Validaciones** | Simulación de incidente |
| **Riesgos** | Soporte sobrepasado al inicio. Mitigación: hypercare 30 días con equipo de desarrollo de respaldo |
| **Labels** | `activity`, `p0`, `docs` |

### M14-H4 — Auditoría final de seguridad y compliance

| Campo | Contenido |
|---|---|
| **Objetivo** | Verificar que en PROD no quedaron permisos excesivos, secretos expuestos, o configuraciones de prueba |
| **Alcance** | Checklist en `docs/runbooks/auditoria-prelanzamiento.md`: roles vs personas, FLS verificado, secretos solo en KeyVault, audit log activo, RLS Power BI activo |
| **Criterios de aceptación** | (1) Checklist 100% cumplido. (2) Firmado por Tech Lead y Patrocinador |
| **Validaciones** | Auditoría manual + script de validación si aplica |
| **Riesgos** | Hallazgos last-minute que retrasen go-live. Mitigación: correr esta auditoría 2 semanas antes del go-live |
| **Labels** | `activity`, `p0`, `docs` |

## Tablas Dataverse tocadas

Ninguna nueva. Solo lectura para validaciones.

## Flows requeridos

Ninguno nuevo.

## Dependencias previas

- M1-M13 cerrados
- PROD aprovisionado (ADR-0004)
- Plan de soporte definido

## Criterios de aceptación globales del módulo

- INNOVA está operable sin los desarrolladores originales
- Usuarios entrenados
- Soporte estructurado

## Riesgos

- Falta de adopción por usuarios. Mitigación: champions por área + sesiones de seguimiento
- Errores post-go-live no atendidos. Mitigación: hypercare 30 días

## Definition of Done

- 4 historias cerradas
- Documentación final en `docs/runbooks/`
- Training completado para 7 roles
- Auditoría firmada
- Go-live oficial declarado
- Post-mortem del proyecto en `docs/decisions/9999-postmortem-go-live.md`
