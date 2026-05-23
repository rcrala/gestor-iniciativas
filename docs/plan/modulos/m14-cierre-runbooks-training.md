# M14 — Cierre, runbooks y training

> **Tipo**: Módulo de cierre
> **Stream**: `docs`

## Objetivo de negocio

Asegurar que INNOVA quede operable por el equipo de soporte y por los usuarios sin necesidad de los desarrolladores originales.

## Historias de usuario (issues GitHub)

### M14-H1 — Runbook consolidado de operación

| Campo | Contenido |
|---|---|
| **Objetivo** | Runbook único que cubra los flujos críticos de operación post-lanzamiento del lado del cliente: alta de usuario, baja de usuario, cambio de BU, recovery de errores comunes, rotación de Service Principal secret, recovery de Connection References rotas |
| **Alcance** | `docs/runbooks/00-operacion-prod.md` con secciones por escenario, comandos PAC, capturas, criterios de éxito. Escrito para que **el equipo de operaciones del cliente** pueda ejecutarlo sin acompañamiento nuestro tras el handoff |
| **Criterios de aceptación** | (1) Runbook cubre 10+ escenarios. (2) Validado ejecutándolo en QA. (3) Aprobado por equipo de soporte del cliente |
| **Validaciones** | Walkthrough con equipo de soporte del cliente |
| **Riesgos** | Documentación que se desactualiza. Mitigación: revisión trimestral programada |
| **Labels** | `activity`, `p0`, `docs` |

### M14-H1b — Runbook de instalación en tenant cliente + acompañamiento primer import

| Campo | Contenido |
|---|---|
| **Objetivo** | Garantizar que el primer import en PROD del cliente se ejecuta sin fricción y queda documentado para imports posteriores autónomos. Ver [ADR-0004](../../decisions/0004-entrega-cliente.md) y [`entrega-cliente.md`](../../architecture/entrega-cliente.md) |
| **Alcance** | (1) Refinar `docs/architecture/entrega-cliente.md` con la experiencia del primer import real. (2) Sesión guiada con el admin Power Platform del cliente para los 10 pasos del runbook (provisión environment → BUs → SP → import 4 solutions → vincular Connection References → seed-data → reducir permisos SP → asignar roles → smoke test → aceptación firmada). (3) Generar `deployment-settings.prod.json` con valores reales del cliente (no commitear en git, entregar por canal seguro). (4) Lecciones aprendidas en `docs/runbooks/m14-handoff-cliente.md`. (5) Documento firmado de aceptación archivado |
| **Criterios de aceptación** | (1) Import completo en PROD sin errores no resueltos. (2) Smoke test pasa los 6 ítems del checklist. (3) Cliente firma aceptación. (4) Cliente puede ejecutar el runbook para actualizaciones futuras sin nuestro acompañamiento (probado con un release de prueba) |
| **Validaciones** | (a) Smoke test en PROD pasa. (b) Cliente ejecuta un release dummy v1.0.1 solo, sin nuestra intervención |
| **Riesgos** | (1) Cliente sin Service Principal listo. Mitigación: validar prerrequisitos 2 semanas antes. (2) Conexiones se vinculan con cuenta personal en lugar de cuenta funcional. Mitigación: checklist explícito + validación post-import. (3) Capacidad Dataverse insuficiente. Mitigación: estimar y validar antes |
| **Labels** | `activity`, `p0`, `docs`, `ci` |

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

- 5 historias cerradas (M14-H1, M14-H1b, M14-H2, M14-H3, M14-H4)
- Documentación final en `docs/runbooks/`
- Training completado para 7 roles
- Auditoría firmada
- Go-live oficial declarado por el cliente
- Aceptación del cliente firmada
- Post-mortem del proyecto en `docs/decisions/9999-postmortem-go-live.md`
