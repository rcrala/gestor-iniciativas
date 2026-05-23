# Convenciones de Naming — Dataverse

## Publisher prefix

Todo el código custom de INNOVA usa el publisher prefix `pas` (Grupo Pasquí).

## Tablas

- Singular, snake_case-friendly pero sin guiones bajos internos en el nombre de entidad
- Display name: PascalCase en español (lo que ve el usuario)
- Plural name: plural en español

| Logical Name | Display Name | Plural Name |
|---|---|---|
| `pas_iniciativa` | Iniciativa | Iniciativas |
| `pas_cotizacion` | Cotización | Cotizaciones |
| `pas_evaluacionpmo` | Evaluación PMO | Evaluaciones PMO |
| `pas_evaluacionti` | Evaluación TI | Evaluaciones TI |
| `pas_horatrabajo` | Hora de Trabajo | Horas de Trabajo |
| `pas_centrocosto` | Centro de Costo | Centros de Costo |
| `pas_miembrocomite` | Miembro del Comité | Miembros del Comité |
| `pas_votocomite` | Voto del Comité | Votos del Comité |
| `pas_documentoadj` | Documento Adjunto | Documentos Adjuntos |
| `pas_plantillacorreo` | Plantilla de Correo | Plantillas de Correo |
| `pas_parametro` | Parámetro del Sistema | Parámetros del Sistema |

## Columnas

- snake_case, lowercase, prefix `pas_`
- Sin abreviaciones cripticas

### Sufijos por tipo

| Sufijo | Tipo | Ejemplo |
|---|---|---|
| `_id` | GUID (auto) | `pas_iniciativa_id` (no es necesario crearlo manualmente) |
| `_ref` | Lookup (cuando el nombre es ambiguo) | `pas_aprobador_ref` |
| `_estado` | Choice | `pas_estado` |
| `_fecha` | Date Only | `pas_fecha_creacion` |
| `_fecha_hora` | DateTime | `pas_fecha_hora_aprobacion` |
| `_monto` | Currency | `pas_monto_estimado` |
| `_horas` | Decimal | `pas_horas_pmo` |
| `_es_<adj>` | Boolean | `pas_es_multi_empresa` |
| `_requiere_<x>` | Boolean | `pas_requiere_desarrollo` |
| `_url` | URL | `pas_url_documento` |
| `_correo` | Email | `pas_correo_aprobador` |
| `_telefono` | Phone | `pas_telefono_solicitante` |

### Convenciones especiales

- Texto corto (≤ 250 chars): sin sufijo. `pas_titulo`, `pas_descripcion_corta`
- Texto largo (multiline): sufijo `_detalle`. `pas_justificacion_detalle`
- Choice: nombre semántico sin sufijo de tipo. `pas_complejidad`, `pas_prioridad`
- Multi-Select Choice: pluralizar. `pas_sistemas_integrar`
- Currency: SIEMPRE con campo currency asociado

## Relaciones

### 1:N

- Schema name: `pas_<parent>_<child>` (entidad padre primero)
- Ejemplo: `pas_iniciativa_cotizacion` (una Iniciativa tiene muchas Cotizaciones)
- Lookup column en el child: `pas_iniciativa_ref` o `pas_iniciativa` si no hay ambigüedad

### N:N

- Schema name: `pas_<entity_a>_<entity_b>`
- Intersect entity custom solo cuando se necesitan campos en la relación: `pas_<a>_<b>_int`

## Choice (Option Set)

### Globales (cuando se reutilizan)

- Schema name: `pas_<dominio>_<concepto>`
- Ejemplo: `pas_iniciativa_estado`, `pas_cotizacion_tipo`

### Valores

- Display: PascalCase en español
- Value numérico: siempre >= 100000000 (rango custom)

Ejemplo de `pas_iniciativa_estado`:

| Value | Label |
|---|---|
| 100000001 | Borrador |
| 100000002 | En Evaluación PMO |
| 100000003 | En Evaluación TI |
| 100000004 | En Aprobación Jefatura |
| 100000005 | En Ejecución PMO |
| 100000006 | En Aprobación Iniciativa |
| 100000007 | En Cotización |
| 100000008 | En Aprobación Gerencia |
| 100000009 | En Aprobación Comité |
| 100000010 | Aprobada |
| 100000011 | Rechazada |
| 100000012 | Devuelta a PMO |
| 100000013 | Cerrada |

## Roles de seguridad

- Schema name: `pas-<rol>` (con guión, convención de Dataverse para roles)
- Display name: en español

| Schema | Display |
|---|---|
| `pas-solicitante` | INNOVA - Solicitante |
| `pas-pmo` | INNOVA - PMO |
| `pas-ti` | INNOVA - TI |
| `pas-jefatura` | INNOVA - Jefatura del Solicitante |
| `pas-gerencia` | INNOVA - Gerencia General |
| `pas-comite` | INNOVA - Comité de Proyectos |
| `pas-administrador` | INNOVA - Administrador |
