# Análisis del requerimiento del cliente vs modelo INNOVA actual

> **Fuente**: [`Requerimiento_Flujo de Iniciativas.Labera.docx`](./Requerimiento_Flujo%20de%20Iniciativas.Labera.docx)
> **Fecha**: 2026-05-24
> **Tool usado**: Microsoft `markitdown` para conversión docx → markdown
> **Imágenes**: 14 PNGs extraídos del docx, 7 mockups de pantallas funcionales + flujo + UI auxiliares

## Validaciones positivas (lo que SÍ está alineado)

| Tema | Requerimiento cliente | Mi modelo / plan | Status |
|---|---|---|---|
| Flujo de 8 pasos | Solicitante → PMO → (TI cond.) → Jefatura → PMO Ejec. → Jefatura Val. → Cotización → Gerencia/Comité | M2-M10 | ✅ alineado |
| 7 roles | Solicitante, PMO, TI, Jefatura, Gerencia, Comité, Administrador | Mismos 7 roles + matriz S0-3 | ✅ alineado |
| Comité unanimidad | "Todos los miembros presionan Aprobar" = Aprobada | `pas_votocomite` + BR-7 | ✅ alineado |
| ROI | (Ahorros − Costo) / Costo × 100% | `pas_roi_porcentaje` calculado | ✅ formula confirmada |
| Soft delete catálogos | "No debe permitirse la eliminación... utilizar desactivación" | `pas_activa` / `pas_activo` en config tables | ✅ alineado |
| Active Directory auth | Credenciales corporativas | Entra ID + ADR-0001 | ✅ alineado |
| Recordatorios cada 3 días | "Notificaciones recurrentes cuando no ha cambiado de estado en 3 días" | Parametro `DiasRecordatorio = 3` | ✅ ya planeado |
| Cotización ganadora | Solo una marcada | `pas_es_ganadora` + BR-3 | ✅ alineado |
| Reportería exportable | XLSX, PDF, CSV | M13 paginated reports | ✅ planeado |
| Dashboard Power BI | Tiempo real, KPIs ejecutivos | M13-H1 | ✅ planeado |
| Multi-empresa | "Para todas las empresas de Grupo" | `pas_empresa` + BU + ADR-0003 | ✅ alineado |

## Gaps identificados (necesitan ajuste al modelo v1.2)

### 🔴 Críticos (afectan flujo central)

#### G1. Tabla `pas_departamento` faltante
**Cliente pide**: "Departamento: Lista desplegable parametrizable acorde a la empresa elegida"
**Mi modelo actual**: No existe.
**Acción**: nueva tabla `pas_departamento` (lookup a `pas_empresa`), CRUD via M11.

#### G2. Tabla `pas_sistema` (catálogo de sistemas integrables)
**Cliente pide**: "Sistemas a integrar: lista desplegable parametrizable, catálogo por compañía, selección múltiple"
**Mi modelo actual**: No existe.
**Acción**: nueva tabla `pas_sistema` (lookup a `pas_empresa`) + relación N:M con `pas_iniciativa`.

#### G3. Tabla `pas_colaboradorcosto` (proceso actual)
**Cliente pide**: Tabla dinámica en pantalla Solicitante con columnas Nombre / Puesto / Horas invertidas en proceso actual (puede agregar N filas).
**Mi modelo actual**: No existe. Texto suelto en algún campo.
**Acción**: nueva tabla `pas_colaboradorcosto` (N:1 con `pas_iniciativa`).

#### G4. Campos faltantes en `pas_iniciativa`
**Cliente pide**:
- Justificación de la iniciativa (Memo)
- Beneficios estratégicos esperados (Memo)
- Requiere integración entre sistemas (Boolean)
- Costo actual del proceso (Money) — capturado por PMO en pantalla #2 (mi modelo lo tiene en evaluacionpmo? verificar)

**Acción**: agregar 4 columnas a `pas_iniciativa`.

#### G5. Clasificación → multi-select
**Cliente pide**: "Clasificación: puede elegir varias (Regulatoria, Operativa, Estratégica, Tecnología)"
**Mi modelo actual**: `pas_clasificacion` es Picklist (single).
**Acción**: cambiar a `MultiSelectPicklist` o crear tabla de relación N:M `pas_iniciativa_clasificacion` (nombre colisiona con choice; mejor renombrar choice).

#### G6. Reconciliar nombres de estados
**Cliente pide** (estados específicos del cuadro resumen):
- "Revisión inicial PMO" (no "En Evaluación PMO" como yo)
- "Estimación Desarrollo"
- "Revisión Estimación de la Jefatura"
- "Estimación Aprobada por Jefatura"
- "Estimación Devuelta por Jefatura"
- "Estimación Rechazada por Jefatura"
- "Revisión Iniciativa Jefatura"
- "Iniciativa Devuelta por Jefatura"
- "En Cotización"
- "Revisión Gerencia de Negocio"
- "Aprobada por Gerencia General de Negocio"
- "Rechazada por Gerencia General de Negocio"
- "Revisión Comité de Proyectos"
- "Aprobada"
- "Rechazo del Comité"

**Mi modelo actual**: 17 estados con nombres diferentes (ej. "En Evaluación PMO" vs "Revisión inicial PMO").
**Acción**: actualizar `pas_iniciativa_estado` choice con los nombres exactos del cliente. Mantener los valores numéricos para no romper datos futuros (aunque no hay datos todavía).

#### G7. Algoritmo de consecutivo específico
**Cliente pide**: `COA-2026-001` = primeras 3 letras de empresa + año + secuencia.
**Mi modelo actual**: `INI-{año}-{seq:00000}` (sin empresa).
**Acción**:
- Agregar `pas_codigo_corto` (3 chars) a `pas_empresa` — ya tenemos `pas_nombre_corto`, podemos usar/reusar
- Actualizar el flow helper `INNOVA - Helper - Generar Consecutivo` para producir el formato correcto
- Documentar en `data-model.md`

#### G8. Parámetros adicionales faltantes
**Cliente pide** (deben estar parametrizables):
- Horas por complejidad: Baja=16, Media=48, Alta=56, Muy Alta=96
- Tarifa hora PMO
- Tarifa hora desarrollador
- Umbral de escalamiento Comité = USD 10,000
- Multi-empresa = más de 1 empresa involucrada

**Mi modelo actual**: `pas_parametro` ya soporta todo esto, pero no tengo los registros pre-seed.
**Acción**: en `seed-data.ps1` (S0-10) agregar estos parámetros con valores placeholder del cliente:
```
TarifaHoraPMO = 25000
TarifaHoraDesarrollador = 35000
UmbralEscalamientoComite_USD = 10000
HorasComplejidadBaja = 16
HorasComplejidadMedia = 48
HorasComplejidadAlta = 56
HorasComplejidadMuyAlta = 96
DiasRecordatorio = 3
```

### 🟡 Importantes (afectan UX / operación)

#### G9. Catálogo de "PMOs asignables"
**Cliente pide**: "Indicar el PMO asignado: lista desplegable parametrizable (Ines, Walter, Evelyn)"
**Mi modelo actual**: `pas_evaluador` es lookup directo a `systemuser`.
**Análisis**: dos opciones:
- A) Mantener systemuser lookup, filtrado en UI a usuarios con rol PMO
- B) Crear tabla `pas_pmo_asignable` con lookup a systemuser (catálogo curado)

**Recomendación**: opción A (más simple, no duplica info de directorio). Filtro en Canvas por rol del usuario.

#### G10. Pantalla de Inicio con tarjetas funcionales
**Cliente pide**: Welcome screen con tarjetas (Crear / Dar seguimiento / Tomar decisiones / Analizar) + sección "Necesitas ayuda".
**Mi modelo actual**: M2-M11 cubren las pantallas operativas, pero no hay un módulo explícito de "Pantalla de Inicio".
**Acción**: agregar al plan un módulo M0 (Inicio) o incluirlo en M2 (Solicitante) como pantalla #0 de la app.

#### G11. Notificaciones por Teams además de correo
**Cliente pide**: "Enviar notificaciones por Teams a la persona que se le asigne una aprobación"
**Mi modelo actual**: planeado en `entrega-cliente.md` Connection References (`cr_innova_teams`) — pero el patrón aún no documentado.
**Acción**: documentar en S0-8 (plantilla flow) la acción "Enviar mensaje Teams" como step del scope Notifications.

#### G12. Pantallas de mantenimiento explícitas
**Cliente pide**: "Pantallas de mantenimiento donde se puedan parametrizar los valores de las opciones que contienen listas desplegables"
**Mi modelo actual**: M11 Administrador cubre esto.
**Acción**: confirmar que M11 incluye:
- Catálogo empresas (M11-nuevo)
- Catálogo departamentos (M11-nuevo, hijo de empresa)
- Catálogo sistemas (M11-nuevo, hijo de empresa)
- Catálogo PMOs disponibles (si vamos por opción B de G9)
- Catálogo prioridades (Alta/Media/Baja — ya está en pas_iniciativa_prioridad)
- Catálogo clasificaciones (ya está)
- Catálogo complejidades + horas (ya está, hay que conectar con parámetro)

### 🟢 Menores (cosméticos o detalles)

#### G13. Vista "Tabla de carga de horas" para reportería
**Cliente pide**: Tabla con columnas específicas: Nombre PMO, Iniciativa, Consecutivo, Empresa, Departamento, CC, Horas PMO, Horas TI, Total, Mes, Año.
**Mi modelo actual**: `pas_horatrabajo` tiene la data; Mes y Año son derivables de `pas_fecha_trabajo`.
**Acción**: crear una **Vista Dataverse** (no tabla nueva) que produzca este shape para reportes.

#### G14. Mockup design language para UX
**Cliente provee**: Diseños con sidebar izquierdo de iconos, header con marca + user, cards de KPI con tendencias, tablas con badges de estado, charts modernos.
**Acción**: estos mockups son la fuente de verdad para issues UX-1/UX-2 que mencionamos antes. El cliente YA está aplicando "Monitoring First" naturalmente (las pantallas de Inicio, Tracking, Reporte, Dashboard tienen KPI cards prominentes).

#### G15. Costo actual del proceso ambiguo
**Cliente pide** en pantalla Solicitante: tabla colaboradores con horas (`pas_colaboradorcosto`).
**Cliente pide** también en pantalla PMO #1: "Costo actual del proceso: Campo para ingresar la información (solo admite valores numéricos)".
**Conflicto**: ¿es la tabla del solicitante automáticamente sumada y editable por PMO, o es un campo independiente?
**Acción**: clarificar con cliente. Asumir: PMO ve la tabla del solicitante y puede sobrescribir con un monto consolidado en `pas_costo_actual_proceso_pmo` (Money).

## Hallazgos de UX/Design

Los mockups del cliente revelan:

| Elemento | Observación |
|---|---|
| **Sidebar izquierdo** | Iconos verticales (Inicio, Solicitudes, Mis solicitudes, Catálogos, Reportes, Dashboard, Configuración). Estilo dashboard moderno |
| **Header** | Logo INNOVA + buscador (en algunas pantallas) + user menu derecha |
| **KPI Cards** | Prominentes en Inicio, Mis Solicitudes, Reporte y Dashboard. Total + porcentaje + tendencia visual |
| **Filtros** | Persistentes arriba de tablas (Buscar, Estado, Prioridad, Empresa, Rango fechas) |
| **Detalle lateral** | Click en fila de tabla abre panel derecho con detalle + timeline de estados |
| **Estados como badges** | Colores diferenciados por estado, no solo texto |
| **Power BI embebido** | El Dashboard muestra gráficos típicos de Power BI (donut, barras, líneas, KPI con tendencia) |
| **Color principal** | Azul corporativo + accents naranja/verde/rojo para estados |
| **Iconografía** | Coherente, posible Fluent UI Icons o similar |

**Conclusión UX**: el cliente ya proveyó el design language. Para implementar:
1. Extraer la paleta de colores del mockup (issue UX-1)
2. Mapear cada mockup a su pantalla M2-M14 (issue UX-2)
3. Usar el mismo design system en Canvas (componentes reutilizables vía `App.OnStart`)

## Acciones recomendadas (priorizadas)

### Plan inmediato

1. **Issue nuevo "model-v1.2-cliente-alignment"** — actualizar `data-model.md`, `data-model` scripts, y matriz de seguridad para incorporar G1-G8 (gaps críticos)
2. **Issue nuevo "estados-cliente-reconciliacion"** — actualizar `pas_iniciativa_estado` choice con nombres exactos del cliente (G6)
3. **Issue UX-1**: extraer design system de los mockups del cliente (paleta, tipografía, componentes)
4. **Issue UX-2**: mapear cada mockup a pantalla M*-H1 (referencia visual para implementación)
5. **Actualizar S0-10 (#21)**: incluir los parámetros del cliente con valores defaults documentados (G8)
6. **Actualizar M2 plan**: incorporar pantalla #0 de Inicio (G10)

### Plan diferido (cuando empiece la implementación)

- Catalogos de departamento y sistemas → M11 amplia
- Vista de horas → M13 (reportería)
- Notificaciones Teams → patrón en S0-8 (#19)

## Asuntos a clarificar con el cliente (respondidos 2026-05-24)

| # | Pregunta | Respuesta del cliente |
|---|---|---|
| C1 | ¿"Costo actual del proceso" en pantalla PMO #2 es la sumatoria automática de la tabla de colaboradores del Solicitante, o es un campo independiente que PMO captura? (G15) | **Campo manual del PMO**. No suma automática. Se persiste en `pas_costo_actual_proceso` de `pas_iniciativa` |
| C2 | ¿PMOs asignables son lookup directo a usuarios con rol PMO, o quieren catálogo curado separado? (G9) | **Lookup directo a usuarios** (filtrar UI por rol PMO). No requiere tabla curada |
| C3 | ¿Los 3 PMOs mencionados (Ines, Walter, Evelyn) son nombres reales o placeholders? | **Placeholders / ejemplos**. No usar literales en seed |
| C4 | ¿El umbral USD 10,000 aplica también cuando es multi-empresa, o solo cuando es > $10K? | **Configurable**. Tanto el umbral como la regla de multi-empresa se exponen como parámetros en `pas_parametro` (M11) |
| C5 | ¿Departamento y Patrocinador deben ser parametrizables 100% (catálogo) o pueden referenciar Active Directory? | **Catálogo parametrizable**. `pas_departamento` (G1) ya cubre departamento. Patrocinador queda como lookup a `systemuser` filtrado por rol |
| C6 | ¿Branding (logo, colores corporativos finales) listo, o usamos los del mockup como referencia inicial? | **Mockup del cliente** como base inicial, pero **configurable** en `pas_parametro` (logo URL, colores hex) para que el cliente pueda cambiarlo sin tocar código |

Estas respuestas se incorporan al EPIC #27 y a los issues G1-G8 (#28-#35).

## Próximos pasos sugeridos

1. ~~**Validar este análisis con el cliente** — confirmar gaps y aclaraciones C1-C6~~ ✅ confirmado 2026-05-24
2. ~~**Crear los issues nuevos** para alineación v1.2 del modelo~~ ✅ EPIC #27 + issues #28-#35 abiertos
3. **Avanzar Sprint 0 restante** (S0-5, S0-6, S0-7, S0-8, S0-9, S0-10) con el modelo actualizado
4. **No empezar M2-M14 hasta que el modelo v1.2 esté consolidado** — sino refactor caro

## Tracking

- EPIC: [#27 — M-V12 Alineacion modelo v1.2 con requerimientos cliente](https://github.com/rcrala/gestor-iniciativas/issues/27)
- Issues hijos: #28 (G1) · #29 (G2) · #30 (G3) · #31 (G4) · #32 (G5) · #33 (G6) · #34 (G7) · #35 (G8)

## Referencias

- Documento fuente: [`Requerimiento_Flujo de Iniciativas.Labera.docx`](./Requerimiento_Flujo%20de%20Iniciativas.Labera.docx)
- Modelo actual: [`docs/architecture/data-model.md`](../architecture/data-model.md) v1.1
- Plan vigente: [`docs/plan/00-roadmap.md`](../plan/00-roadmap.md)
- Matriz seguridad: [`docs/architecture/security-roles.md`](../architecture/security-roles.md)
- Imágenes extraídas (referencia para devs): [`./media/`](./media/) (image1-14.png) — ver [`./media/README.md`](./media/README.md) con el mapeo de cada imagen a su pantalla M0-M13
