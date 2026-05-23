# M2 — Pantalla Solicitante (#1)

> **Pantalla**: #1 del análisis funcional
> **Tablas principales**: `pas_iniciativa`
> **Stream**: `canvas` + `flows` + `core`

## Objetivo de negocio

Permitir al Solicitante registrar una iniciativa con toda la información mínima necesaria para que el PMO pueda iniciar la evaluación.

## Historias de usuario (issues GitHub)

### M2-H1 — Pantalla Solicitante: información general y de la iniciativa

| Campo | Contenido |
|---|---|
| **Objetivo** | Implementar la pantalla #1 con secciones de "Información general", "Información de la iniciativa" y tabla dinámica de colaboradores |
| **Alcance** | Canvas screen con `Patch()` contra `pas_iniciativa`. Generador automático de consecutivo (numeración secuencial). Validación de campos requeridos. Componente reutilizable de tabla de colaboradores |
| **Criterios de aceptación** | (1) Usuario con rol Solicitante puede crear iniciativa. (2) Consecutivo único generado automáticamente. (3) Campos obligatorios validados antes del Submit. (4) Colaboradores se agregan/eliminan sin perder el formulario |
| **Validaciones** | Smoke test manual con 3 escenarios. Validación de delegación en consulta de catálogos |
| **Riesgos** | Race condition en consecutivo concurrente. Mitigación: usar plugin C# o flow con lock |
| **Labels** | `activity`, `p0`, `canvas`, `core` |

### M2-H2 — Flow "Iniciativa Creada → Notificar PMO"

Ya documentado en [docs/runbooks/08-historia-piloto-notificacion-pmo.md](../../runbooks/08-historia-piloto-notificacion-pmo.md). Crear issue referenciando ese runbook como criterios de aceptación.

### M2-H3 — Adjuntar documentos a la iniciativa

| Campo | Contenido |
|---|---|
| **Objetivo** | Permitir adjuntar documentos de soporte (PDF, Word, Excel, imagen) que se almacenan en SharePoint |
| **Alcance** | Componente de upload en la pantalla. Flow que mueve el archivo al SharePoint configurado y registra `pas_documentoadj` con metadata |
| **Criterios de aceptación** | (1) Múltiples archivos hasta N MB. (2) Tipos permitidos configurables. (3) Vínculo de descarga visible |
| **Validaciones** | Test con archivos al límite de tamaño y de tipos no permitidos |
| **Riesgos** | Límites de Power Apps en upload de archivos. Mitigación: usar custom connector o PCF si excede |
| **Labels** | `activity`, `p1`, `canvas`, `flows` |

## Tablas Dataverse tocadas

- `pas_iniciativa` (Create, Update por el Solicitante mientras está en estado "Borrador")
- `pas_documentoadj` (Create)
- Lookups: `pas_centrocosto`, usuarios

## Flows requeridos

- `INNOVA - Iniciativa Creada - Notificar PMO`
- `INNOVA - Documento Adjunto - Mover a SharePoint`
- (Helper) `INNOVA - Helper - Generar Consecutivo`

## Dependencias previas

- Sprint 0 cerrado (modelo, solution, SP, plantillas)
- Estructura SharePoint definida

## Criterios de aceptación globales del módulo

- Solicitante puede crear iniciativa end-to-end
- Adjuntos viajan a SharePoint correctamente
- PMO recibe notificación en menos de 2 min
- Tracking "Mis Solicitudes" (M12) muestra la iniciativa creada

## Riesgos

- Cambios en el modelo de datos que afecten la pantalla. Mitigación: M1 estable antes de empezar
- UX no aprobada por usuarios reales. Mitigación: mockup en Figma antes de implementar

## Definition of Done

- 3 historias cerradas con PR mergeado
- Canvas exportado y unpacked en `solutions/innova-canvas/`
- Flows exportados en `solutions/innova-flows/`
- Runbook `docs/runbooks/m02-pantalla-solicitante.md`
- Test plan en `tests/m02/`
- Demo al Solicitante piloto
