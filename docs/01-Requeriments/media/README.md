# Mockups del cliente — Índice visual

> **Fuente**: imágenes embebidas extraídas de [`../Requerimiento_Flujo de Iniciativas.Labera.docx`](../Requerimiento_Flujo%20de%20Iniciativas.Labera.docx)
> **Extraídas a este repo**: 2026-05-25
> **Total**: 14 PNG (1 diagrama de proceso + 13 mockups de pantalla)

Estos archivos son la **fuente visual de verdad para UX**. Cada pantalla M0-M13 tiene su mockup correspondiente del cliente. Cuando construyas las pantallas en Power Apps Studio, usá la imagen apuntada como referencia de layout, jerarquía visual y design language.

## Índice

| Archivo | Tipo | Pantalla / Módulo INNOVA | Notas |
|---|---|---|---|
| [`image1.png`](./image1.png) | Diagrama | **Flujo de proyectos** (8 pasos del proceso end-to-end) | No es pantalla — referencia conceptual del flujo con decisiones `Es un desarrollo?` y `Iniciativa mayor a $10,000?` |
| [`image2.png`](./image2.png) | Mockup | **M0 — Pantalla de Inicio** | "¡Bienvenido!" con 4 tarjetas (Crear / Dar seguimiento / Tomar decisiones / Analizar) + sección "¿Necesitas ayuda?". **Gap G10**: M0 no existe en el plan vigente; debe agregarse o anidarse en M2 |
| [`image3.png`](./image3.png) | Mockup | **M12 — Mis Solicitudes (tracking)** | KPI cards arriba + tabla con badges de estado + panel detalle lateral derecho |
| [`image4.png`](./image4.png) | Mockup | **M2 — Pantalla Solicitante** | "Nueva Solicitud de Iniciativa" con secciones: Información general, Información de la iniciativa, tabla dinámica de Colaboradores. Bloqueado por issues abiertos #30, #31, #32 |
| [`image5.png`](./image5.png) | Mockup | **M3 — Pantalla PMO Evaluación** | "Evaluación PMO de la Iniciativa" con resumen + bloque de evaluación (complejidad, costo del proceso, ROI, requiere desarrollo) |
| [`image6.png`](./image6.png) | Mockup | **M4 — Pantalla TI Estimación** | "Evaluación TI de la Iniciativa" con horas desarrollador y costo |
| [`image7.png`](./image7.png) | Mockup | **M5 — Pantalla Jefatura Estimación** | "Aprobación de la Jefatura Solicitante" con resumen + colaboradores + botones Aprobar/Devolver/Rechazar |
| [`image8.png`](./image8.png) | Mockup | **M6 — Pantalla PMO Ejecución** | "Ejecución PMO de la Iniciativa" con documentación de ejecución + horas reales invertidas |
| [`image9.png`](./image9.png) | Mockup | **M7 — Pantalla Jefatura Validación** | "Jefatura del Solicitante" (segunda revisión post-ejecución) con docs de ejecución + tiempo real + Aprobar/Devolver/Rechazar |
| [`image10.png`](./image10.png) | Mockup | **M8 — Pantalla PMO Cotizaciones** | 3 cotizaciones con datos comparativos + ROI |
| [`image11.png`](./image11.png) | Mockup | **M9 — Pantalla Gerencia General** | "Gerencia General del Negocio" con resumen + cotización ganadora + Aprobar/Rechazar |
| [`image12.png`](./image12.png) | Mockup | **M10 — Pantalla Comité** | "Comité de Proyectos" con resumen + voto Aprobar/Rechazar |
| [`image13.png`](./image13.png) | Mockup | **M13 — Reporte de Iniciativas** | Tabla amplia con filtros, exportación y badges de estado |
| [`image14.png`](./image14.png) | Mockup | **M13 — Dashboard de Iniciativas** | Gráficos KPI: donas, barras, líneas, tendencias |

## Design language observado (consistente en todos los mockups)

- **Sidebar izquierdo** de iconos verticales (Inicio, Solicitudes, Mis solicitudes, Catálogos, Reportes, Dashboard, Configuración)
- **Header** con logo INNOVA + user menu a la derecha; algunas pantallas suman buscador
- **Color principal** azul corporativo (#1B3A6B aprox); accents naranja/verde/rojo para estados
- **Estados como badges** con color diferenciado, no solo texto
- **KPI cards** prominentes con icono + número + tendencia (Inicio, Mis Solicitudes, Reporte, Dashboard)
- **Filtros persistentes** sobre tablas (Buscar, Estado, Prioridad, Empresa, Rango fechas)
- **Detalle lateral** — click en fila de tabla abre panel derecho con detalle + timeline de estados
- **Botonera inferior** consistente: primario verde (Aprobar/Enviar) + secundarios (Devolver/Rechazar/Salir)
- **Iconografía** estilo Fluent UI / similar

## Cómo usar estos mockups

1. Antes de armar una pantalla en Studio, abrí el mockup correspondiente como referencia
2. Si necesitás detalles del modelo de datos detrás, cruzá con [`../analisis-requerimiento-cliente.md`](../analisis-requerimiento-cliente.md) y [`../../architecture/data-model.md`](../../architecture/data-model.md)
3. Para los componentes reutilizables (sidebar, header, KPI cards, status badges), ver la Component Library de INNOVA (a construirse en `solutions/innova-canvas/component-library/`)

## Referencias cruzadas

- Análisis del requerimiento: [`../analisis-requerimiento-cliente.md`](../analisis-requerimiento-cliente.md)
- Plan por módulo: [`../../plan/modulos/`](../../plan/modulos/)
- Modelo de datos: [`../../architecture/data-model.md`](../../architecture/data-model.md)
- EPIC alineación cliente: [#27](https://github.com/rcrala/gestor-iniciativas/issues/27)
