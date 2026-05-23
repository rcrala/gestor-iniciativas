# Modelo de Datos — INNOVA

> **Estado**: Placeholder. El modelo detallado se construye en Sprint 0 como uno de los entregables prioritarios.

## Tablas previstas

| Logical Name | Display Name | Propósito |
|---|---|---|
| `pas_iniciativa` | Iniciativa | Entidad principal |
| `pas_cotizacion` | Cotización | Hasta 3 por iniciativa (1 interna + 2 externas) |
| `pas_evaluacionpmo` | Evaluación PMO | Análisis de complejidad y costo |
| `pas_evaluacionti` | Evaluación TI | Estimación de desarrollo (condicional) |
| `pas_horatrabajo` | Hora de Trabajo | Registro de horas PMO/TI por centro de costo |
| `pas_centrocosto` | Centro de Costo | Catálogo de centros de costo |
| `pas_miembrocomite` | Miembro del Comité | Catálogo de miembros y suplentes |
| `pas_votocomite` | Voto del Comité | Voto individual por miembro y iniciativa |
| `pas_documentoadj` | Documento Adjunto | Metadata de archivos en SharePoint |
| `pas_plantillacorreo` | Plantilla de Correo | Cuerpo y asunto por tipo de evento |
| `pas_parametro` | Parámetro del Sistema | Configuración (monto umbral, etc.) |

## Choice sets globales previstos

- `pas_iniciativa_estado` (17 valores)
- `pas_iniciativa_prioridad` (P1, P2, P3)
- `pas_iniciativa_complejidad` (Baja, Media, Alta, Muy Alta)
- `pas_iniciativa_clasificacion` (Mejora, Nuevo Proceso, Cumplimiento, etc.)
- `pas_cotizacion_tipo` (Interna, Externa)
- `pas_decision` (Aprobar, Devolver, Rechazar)

## Pendiente para Sprint 0

- Diagrama ER completo
- Definición de columnas de cada tabla con tipos y constraints
- Relaciones 1:N y N:N
- Reglas de negocio (Business Rules en Dataverse)
- Índices y consideraciones de performance
- Estrategia de migración de iniciativas existentes (ADR pendiente)
