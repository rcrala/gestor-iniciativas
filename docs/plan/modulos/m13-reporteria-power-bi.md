# M13 — Reportería Power BI

> **Pantalla**: Power BI Service + paginated reports
> **Tablas principales**: todas (DirectQuery)
> **Stream**: `reports`

## Objetivo de negocio

Dar visibilidad ejecutiva del portafolio de iniciativas: pipeline por estado, montos comprometidos vs aprobados, throughput PMO, tiempos por fase, cumplimiento de SLA, distribución por empresa/centro de costo.

## Historias de usuario (issues GitHub)

### M13-H1 — Dashboard ejecutivo en tiempo real

| Campo | Contenido |
|---|---|
| **Objetivo** | Dashboard con KPIs clave: iniciativas por estado, monto total comprometido, top centros de costo, tiempo promedio por fase, % aprobación |
| **Alcance** | Power BI report con DirectQuery a Dataverse. RLS espejo de los permisos Dataverse. Publicado en workspace Power BI Pro |
| **Criterios de aceptación** | (1) KPIs cargan en < 5s. (2) RLS funciona (Gerencia ve solo su BU, Comité ve cross-BU). (3) Drill-through a detalle |
| **Validaciones** | Test con 3 usuarios de BUs distintas |
| **Riesgos** | Performance de DirectQuery con miles de filas. Mitigación: agregaciones, índices Dataverse |
| **Labels** | `activity`, `p1`, `reports` |

### M13-H2 — Paginated Reports para exportación a Excel/PDF/CSV

| Campo | Contenido |
|---|---|
| **Objetivo** | Reportes formateados para exportación (auditoría, comité, finanzas) |
| **Alcance** | Reportes: "Histórico de iniciativas por empresa", "Resumen Comité por trimestre", "Horas PMO/TI por centro de costo" |
| **Criterios de aceptación** | (1) 3 reportes en producción. (2) Exportan a XLSX y PDF correctamente. (3) Programados para envío mensual |
| **Validaciones** | Verificar export en cada formato |
| **Riesgos** | Capacidad de paginated reports (licenciamiento Premium). Mitigación: verificar capacity disponible antes |
| **Labels** | `activity`, `p2`, `reports` |

### M13-H3 — Suscripciones automáticas a reportes

| Campo | Contenido |
|---|---|
| **Objetivo** | Que ejecutivos reciban su dashboard/reporte por correo en frecuencia definida (semanal, mensual) |
| **Alcance** | Configurar Power BI Subscriptions. Documentar plantilla de suscripción |
| **Criterios de aceptación** | (1) Suscripciones funcionando para 3 usuarios piloto. (2) Documentación reproducible |
| **Validaciones** | Recibir el correo durante 1 ciclo |
| **Riesgos** | — |
| **Labels** | `activity`, `p2`, `reports` |

## Tablas Dataverse tocadas

Todas, vía DirectQuery.

## Flows requeridos

Ninguno propio. Posibles flows complementarios para consolidar datasets si performance lo requiere.

## Dependencias previas

- M6 cerrado mínimo (debe existir flujo completo de al menos 1 caso)
- License Power BI Pro / Premium confirmada
- Service Principal con permisos Dataverse para Power BI

## Criterios de aceptación globales del módulo

- Dashboard live en producción usado semanalmente por dirección
- 3 paginated reports operativos
- Suscripciones activas

## Riesgos

- Cambios en modelo de datos rompen reportes. Mitigación: versioning de dataset + tests automáticos de schema
- Licenciamiento Power BI insuficiente. Mitigación: validar al inicio

## Definition of Done

- 3 historias cerradas
- Reportes en `solutions/innova-reports/` (formato `.pbip` preferido sobre `.pbix`)
- Runbook
- Tests (smoke con captura de pantalla)
- Demo a dirección
