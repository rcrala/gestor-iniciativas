# Análisis: SDD Initiative Prioritization Engine vs modelo INNOVA actual

> **Fuente del cliente**: [`sdd_mvp_prioritization_engine_markdown.md`](./sdd_mvp_prioritization_engine_markdown.md) (v1.0 Draft, autor: "OpenAI / AI Solution Architect")
> **Fecha**: 2026-05-24
> **Modelo actual**: v1.5 (post-EPIC #27)

## TL;DR

El cliente trae un Specification-Driven Doc para 3 motores de priorización (Eisenhower, Impact-Effort, Scoring configurable). El SDD está escrito **stack-agnostic con sesgo a React/NestJS/PostgreSQL**, no a Power Platform. La funcionalidad **es valiosa y compatible** con INNOVA, pero requiere:

1. Re-mapeo de stack (React → Canvas/PCF, PostgreSQL → Dataverse, etc.)
2. 4-7 columnas nuevas en `pas_iniciativa`
3. 2 tablas nuevas (`pas_criterio_priorizacion` + `pas_iniciativa_score`)
4. 2 choices nuevos (Eisenhower quadrant, Impact-Effort classification)
5. 1 pantalla nueva (Matriz Eisenhower + Bubble chart Impact-Effort)
6. Lógica de cálculo en flow helper (o plugin C# si performance lo requiere)

**Tamaño estimado**: equivalente a un módulo M (M-PRIO), 1-2 sprints. Recomendable como **EPIC separado** del #27.

**Decisiones pendientes con cliente**: 6 (C7-C12 al final).

## Mapeo del SDD al stack de INNOVA

El SDD propone una solución greenfield. Como INNOVA ya existe en Power Platform:

| SDD original | INNOVA equivalente |
|---|---|
| React + NextJS frontend | Canvas App (pantalla M-PRIO) + PCF Control para los charts |
| TailwindCSS | Fluent UI base de Canvas + design tokens del cliente (M-VTC) |
| Recharts / ECharts | PCF Control con `react-chartjs-2` o `recharts` empaquetado |
| FastAPI / NestJS backend | Power Automate flows + Dataverse Web API |
| PostgreSQL + Prisma | Dataverse + dataverse-client |
| Keycloak / Auth0 | Entra ID (ya integrado) |
| JSON Rules Engine | Dataverse Business Rules + Power Automate `Switch` actions |
| Docker + Kubernetes | Power Platform managed solutions |
| REST API | Web API nativa de Dataverse (OData v4) |
| RabbitMQ (futuro) | Power Automate child flows + Dataverse webhooks |

**El cliente debe saber** que vamos a implementar los conceptos del SDD pero en stack Power Platform — el SDD le sirve como spec funcional, no como guía técnica.

## Qué del SDD YA cubrimos parcialmente

### Entidad Initiative

| Campo SDD | Mapeo INNOVA | Estado |
|---|---|---|
| `initiativeId` UUID | `pas_iniciativaid` Uniqueidentifier | ✅ |
| `title` String | `pas_titulo` | ✅ |
| `description` Text | `pas_descripcion` + `pas_descripcion_ampliada` | ✅ |
| `category` String | `pas_clasificacion` Choice | ✅ |
| `owner` String | `pas_solicitante` Lookup → systemuser | ✅ |
| `department` String | (G4 #31 agregará `pas_departamento` lookup) | 🟡 pendiente G4 |
| `status` Enum | `pas_estado` Choice (17 valores) | ✅ |
| `urgency` Integer 1-5 | — | ❌ falta |
| `importance` Integer 1-5 | — (tenemos `pas_prioridad` Choice P1/P2/P3, no equivale) | ❌ falta |
| `businessImpact` Integer 1-10 | — | ❌ falta |
| `technicalEffort` Integer 1-10 | — (tenemos `pas_complejidad` Choice Baja/Media/Alta/MuyAlta, no equivale) | ❌ falta |
| `complexity` Integer 1-10 | — | ❌ falta (relacionado a `pas_complejidad` pero escala distinta) |
| `strategicAlignment` Integer 1-10 | — | ❌ falta |
| `estimatedCost` Decimal | `pas_monto_estimado` Money | ✅ |
| `priorityScore` Decimal calculado | — | ❌ falta |
| `createdAt` / `updatedAt` | `createdon` / `modifiedon` (audit nativo) | ✅ |

### Otras entidades

- `ScoreCriteria` → **no existe**. Necesita tabla nueva `pas_criterio_priorizacion`
- `InitiativeScore` → **no existe**. Necesita tabla bridge `pas_iniciativa_score`

### Requisitos no-funcionales del SDD

| Requisito | Status INNOVA |
|---|---|
| Performance dashboard < 2s | Power BI cumple holgadamente |
| Performance score recalc < 1s | Flow helper con `Concurrency=1` debería cumplir; si no, plugin C# |
| API < 500ms | Dataverse Web API típicamente < 200ms |
| 100k+ iniciativas | Dataverse soporta sin problema; consultas paginadas vía OData |
| JWT auth + RBAC | Entra ID + Security Roles INNOVA cubren |
| Audit logging | Audit nativo de Dataverse cubre |
| HTTPS | Garantizado por la plataforma |
| 99.5% availability | SLA de Microsoft Power Platform es 99.9% para productivo |
| Backup diario | Restore points nativos (7 días en P1) |

## Gaps específicos (GPx)

### 🔴 Críticos (sin esto el motor no funciona)

#### GP1. Nuevas columnas en `pas_iniciativa` para scoring

Agregar:
- `pas_urgencia` Integer 1-5 — capturado en M2 (Nueva Solicitud)
- `pas_importancia` Integer 1-5 — capturado en M2
- `pas_impacto_negocio` Integer 1-10 — capturado en M3 (Evaluación PMO)
- `pas_esfuerzo_tecnico` Integer 1-10 — capturado en M3 o M4 (Estimación TI)
- `pas_alineacion_estrategica` Integer 1-10 — opcional, capturado en M3
- `pas_score_prioridad` Decimal — **calculado** por flow
- `pas_cuadrante_eisenhower` Choice → `pas_cuadrante_eisenhower` (DO_NOW / PLAN / DELEGATE / ELIMINATE)
- `pas_clasificacion_impacto_esfuerzo` Choice → `pas_clasificacion_ie` (QUICK_WIN / STRATEGIC / FILL_IN / AVOID)

**Coexistencia con campos actuales**:
- `pas_prioridad` (P1/P2/P3) actual: **decisión de jefatura**. Mantener.
- `pas_complejidad` (Baja/Media/Alta/MuyAlta) actual: **estimación PMO**. Mantener; se puede mapear a `pas_esfuerzo_tecnico` con conversión (Baja=2, Media=5, Alta=7, MuyAlta=10) o capturar independiente.

#### GP2. Nueva tabla `pas_criterio_priorizacion`

| Columna | Tipo | Notas |
|---|---|---|
| `pas_nombre` | String, Primary | "ROI", "Alineación Estratégica", "Riesgo de no hacer", etc. |
| `pas_descripcion` | Memo | |
| `pas_peso` | Decimal (0-1) | Suma de pesos activos debe ser 1.0 (= 100%) |
| `pas_categoria` | String | agrupa criterios por área |
| `pas_min_valor` | Integer | default 1 |
| `pas_max_valor` | Integer | default 10 |
| `pas_activo` | Boolean | soft-delete pattern |

**Owner**: Organization. CRUD por Admin (M11 ampliada).

#### GP3. Nueva tabla bridge `pas_iniciativa_score`

| Columna | Tipo | Notas |
|---|---|---|
| `pas_iniciativa` | Lookup → pas_iniciativa | Cascade Delete |
| `pas_criterio` | Lookup → pas_criterio_priorizacion | Restrict Delete |
| `pas_valor` | Integer | dentro del rango [min_valor, max_valor] del criterio |
| `pas_valor_ponderado` | Decimal | calculado: valor × peso del criterio en ese momento |
| `pas_fecha_calculo` | DateTime | snapshot |

**Owner**: User (sigue la iniciativa).

#### GP4. Nuevos Global Choices

- `pas_cuadrante_eisenhower`: DO_NOW (1), PLAN (2), DELEGATE (3), ELIMINATE (4)
- `pas_clasificacion_ie`: QUICK_WIN (1), STRATEGIC (2), FILL_IN (3), AVOID (4)

#### GP5. Flow `INNOVA - Helper - Calcular Priorizacion`

Child flow disparado al cambiar:
- `pas_urgencia`, `pas_importancia` → recalcular `pas_cuadrante_eisenhower`
- `pas_impacto_negocio`, `pas_esfuerzo_tecnico` → recalcular `pas_clasificacion_ie` y `pas_score_prioridad`
- Cualquier fila en `pas_iniciativa_score` → recalcular `pas_score_prioridad` total (Σ valor × peso)

**Pseudocódigo**:

```
ENTRADA: iniciativaId
1. Obtener iniciativa
2. Eisenhower:
   IF urgencia >= 4 AND importancia >= 4 → DO_NOW
   ELIF urgencia <  4 AND importancia >= 4 → PLAN
   ELIF urgencia >= 4 AND importancia <  4 → DELEGATE
   ELSE                                    → ELIMINATE
3. Impact-Effort:
   IF impacto >= 7 AND esfuerzo <= 4 → QUICK_WIN
   ELIF impacto >= 7 AND esfuerzo >  4 → STRATEGIC
   ELIF impacto <  7 AND esfuerzo <= 4 → FILL_IN
   ELSE                                → AVOID
   PriorityScore = impacto / esfuerzo
4. Configurable:
   scores = List pas_iniciativa_score WHERE iniciativa = iniciativaId
   TotalScore = Σ (s.valor × s.criterio.peso) si criterio.activo
5. Patch iniciativa con cuadrante, clasificacion_ie, score_prioridad
```

**Concurrencia**: el cálculo es por-iniciativa, sin race. No requiere `Concurrency=1`.

### 🟡 Importantes (UX/admin)

#### GP6. Validación "suma de pesos = 1.0"

El SDD lo pide explícitamente (FR-031). Requiere validación cuando admin activa/desactiva/edita criterios. Opciones:
- **Business Rule en pas_criterio_priorizacion**: rechaza save si suma ≠ 1.0
- **Plugin C# pre-validate**: misma lógica pero permite redondeo a 2 decimales (1.000000001 ≈ 1.0)
- **Validación visual en M11**: indicador rojo si no suma, no bloquea save pero advierte

**Recomendación**: combinación validación visual + plugin para hard-block. Sin plugin la validación se puede burlar via API.

#### GP7. Pantalla M-PRIO (Priorización)

Nueva pantalla en Canvas App con:
- **Matriz Eisenhower 2×2** con iniciativas posicionadas (PCF Control que renderice cuadrantes y permita drag-and-drop opcional)
- **Bubble chart Impact-Effort** (PCF Control con recharts/d3, eje X=esfuerzo, eje Y=impacto, tamaño=monto, color=estado)
- **Tabla de ranking** ordenada por `pas_score_prioridad` descendente (Canvas Gallery)
- **Panel de criterios** (link a M11 si es admin)

#### GP8. Dashboard ejecutivo de priorización

Power BI report con:
- Iniciativas por cuadrante Eisenhower (donut)
- Iniciativas por clasificación I-E (barras agrupadas)
- Top 10 iniciativas por score (tabla)
- Tendencia de score promedio mensual (line chart)
- Filtros: empresa, departamento, fecha

Cabe en el módulo M13 (reportería) o como dashboard separado.

### 🟢 Menores (extensibilidad)

#### GP9. Events / triggers para futuras integraciones

El SDD menciona `InitiativeCreated`, `ScoreCalculated`, etc. En Power Platform esto se traduce a:
- **Dataverse webhooks** para listeners externos (Future)
- **Service Bus** para eventos asíncronos (Future)
- **Power Automate triggers** para reacciones internas (ya disponible)

No hay que implementar nada nuevo: documentar que la arquitectura los soporta cuando se necesiten.

#### GP10. AI / predictive layer (Phase 3 del SDD)

Out-of-scope del MVP. Cuando aplique:
- Azure ML / Azure OpenAI integradon vía Power Automate
- AI Builder de Power Platform para modelos de scoring

## Qué del SDD NO aplica directamente

| SDD propone | Justificación NO aplica |
|---|---|
| Stack React/NextJS/FastAPI/PostgreSQL | INNOVA es Power Platform — el cliente debe estar enterado de que adaptamos los conceptos al stack acordado |
| Docker + Kubernetes + Helm | Power Platform managed solutions cubren ALM |
| Keycloak / Auth0 | Entra ID ya integrado |
| JWT custom | Auth de Power Platform delega a Entra ID |
| GitLab CI / Azure DevOps | Ya usamos GitHub Actions (decisión repo) |
| Prometheus / Grafana | Power Platform Admin Center + Application Insights cubren observability |
| RabbitMQ | No necesario en MVP; Dataverse webhooks + service bus si crece |

**No es que el SDD esté mal** — está escrito agnóstico. Solo hay que dejarlo claro con el cliente.

## Preguntas para el cliente (C7-C12)

| # | Pregunta | Razón |
|---|---|---|
| C7 | ¿`pas_prioridad` actual (P1/P2/P3 asignada por Jefatura) se mantiene o reemplaza con el sistema de scoring nuevo? | Coexisten 2 conceptos de "prioridad" |
| C8 | ¿Quién captura `urgencia`, `importancia`, `impacto_negocio`, `esfuerzo_tecnico`? ¿Solicitante en M2 o PMO en M3 o ambos? | Determina dónde van los inputs en la UI |
| C9 | ¿Cuándo se recalcula `priorityScore`? Live (al cambiar campo) o batch (al cerrar etapa)? | Live = flow trigger en cada update; batch = scheduled |
| C10 | ¿Los 3 engines (Eisenhower, Impact-Effort, Scoring configurable) son vistas paralelas del mismo dato o tres procesos distintos? El SDD los presenta separados pero podrían compartir inputs | Define si hay 3 columnas calculadas o 1 |
| C11 | ¿Entiende el cliente que vamos a implementar los conceptos del SDD en Power Platform (no en React/FastAPI/PostgreSQL como propone el SDD)? | Confirmación explícita de scope técnico |
| C12 | ¿Prioridad relativa al EPIC #27? Opciones: (a) bloquea M2-M14 hasta que esto exista (b) paralelo a M2-M14 (c) Phase 2 (post-MVP) | Decisión de roadmap |

## Recomendación de plan

**Si el cliente confirma C7-C12**:

1. **Abrir EPIC nuevo** `M-PRIO Initiative Prioritization Engine` (paralelo al #27, no bloqueante)
2. **Issues hijos** (basados en GPs):
   - GP1 — Columnas nuevas en `pas_iniciativa` (4-7 columnas)
   - GP2 — Tabla `pas_criterio_priorizacion`
   - GP3 — Tabla bridge `pas_iniciativa_score`
   - GP4 — Choices `pas_cuadrante_eisenhower` + `pas_clasificacion_ie`
   - GP5 — Flow helper `Calcular Priorizacion`
   - GP6 — Validación suma pesos (plugin C# o Business Rule)
   - GP7 — Pantalla M-PRIO en Canvas App + 2 PCF Controls (matriz + bubble)
   - GP8 — Dashboard Power BI de priorización
   - GP9 (futuro) — Events / webhooks
3. **Esfuerzo estimado**: 1-2 sprints (3-4 semanas con 1 dev)
4. **Sin dependencia con EPIC #27** — puede arrancar tan pronto el cliente confirme, en paralelo

## Referencias

- SDD fuente: [`sdd_mvp_prioritization_engine_markdown.md`](./sdd_mvp_prioritization_engine_markdown.md)
- Modelo INNOVA actual: [`docs/architecture/data-model.md`](../../architecture/data-model.md) v1.5
- Análisis del requerimiento anterior: [`docs/01-Requeriments/analisis-requerimiento-cliente.md`](../analisis-requerimiento-cliente.md)
- EPIC #27 en curso (no bloquea este): [#27](https://github.com/rcrala/gestor-iniciativas/issues/27)
