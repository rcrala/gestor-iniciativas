# Runbook 02 — Crear / mantener tablas, choices y relaciones de INNOVA

> **Para qué**: Provisionar el modelo de datos completo (12 tablas, 11 choices, 19 relaciones) en un environment nuevo (DEV/QA) sin maker portal, o reaplicar cambios incrementales.
> **Issue origen**: #15 (S0-4)
> **Modelo canónico**: [`docs/architecture/data-model.md`](../architecture/data-model.md)

## Concepto

Los scripts en `scripts/setup/` automatizan el provisioning de toda la metadata de Dataverse para INNOVA. Cada script es idempotente: re-ejecutarlo no duplica ni rompe nada.

```
scripts/setup/
├── lib/dataverse.ps1                     ← helpers reusables (auth, Web API, metadata)
├── 01-create-business-units.ps1          ← S0-2 (cubierto en runbook 01)
├── 02-create-choice-sets.ps1             ← 11 global option sets
├── 03-create-tables.ps1                  ← 12 tablas con columnas (no lookups)
└── 04-create-relationships.ps1           ← 19 relaciones N:1 (lookups)
```

**Orden de ejecución obligatorio**: 02 → 03 → 04. Choices antes que tablas (porque las tablas referencian choices). Relaciones después de tablas.

## Prerequisitos

- Az.Accounts instalado (`Install-Module Az.Accounts -Scope CurrentUser`)
- Sesión activa: `Connect-AzAccount -UseDeviceAuthentication -Subscription <id>`
- Usuario con rol `System Administrator` en el environment destino
- Solution `innova_core` y publisher `Pasqui` (prefix `pas`) ya creados en el environment
- BUs creadas (runbook 01)

## Provisioning desde cero (environment nuevo)

```powershell
# 1. Choice sets globales (11 sets)
pwsh ./scripts/setup/02-create-choice-sets.ps1 -Environment dev

# 2. Tablas con sus columnas escalares (12 tablas, ~95 columnas)
pwsh ./scripts/setup/03-create-tables.ps1 -Environment dev

# 3. Relaciones N:1 (19 lookups)
pwsh ./scripts/setup/04-create-relationships.ps1 -Environment dev
```

Tiempo estimado: ~5-10 minutos sobre environment vacío.

Para QA: `-Environment qa`. Mismo flujo.

## Provisioning incremental (modificar el modelo)

Si se agrega/cambia una columna o relación en `data-model.md`, hay que reflejarlo en el script correspondiente.

1. Editar la definición en `03-create-tables.ps1` (sección `$tables`) o `04-create-relationships.ps1` (sección `$relationships`)
2. Re-ejecutar el script — idempotencia detecta lo nuevo y lo crea, salta lo existente
3. Commitear los cambios al script + actualizar `data-model.md`

Para borrar una columna o relación, usar el maker portal (más visual). La lógica de "borrado programático" no está en estos scripts por seguridad.

## Convenciones que los scripts asumen

- **Prefijo**: todo lleva `pas_` (publisher Pasqui)
- **SchemaName**: `pas_Nombre_Columna` (PascalCase + underscores, así Dataverse preserva el snake_case en el LogicalName)
- **LogicalName**: `pas_nombre_columna` (lowercase con underscores)
- **Audit**: ON por default en todas las tablas excepto `pas_documentoadj` (alto volumen)
- **Ownership**: User-owned para tablas de proceso, Organization-owned para catálogos
- **Solution**: todo se crea dentro de `innova_core` vía header `MSCRM.SolutionUniqueName`

## Filtrado para debug iterativo

Ambos scripts soportan filtrar a un solo artefacto:

```powershell
# Solo una tabla
pwsh ./scripts/setup/03-create-tables.ps1 -OnlyTable pas_empresa

# Solo una relación
pwsh ./scripts/setup/04-create-relationships.ps1 -OnlyRelationship pas_iniciativa_empresa

# Dry-run
pwsh ./scripts/setup/03-create-tables.ps1 -WhatIf
```

## Artefactos manuales conocidos (DEV)

Durante la provisión inicial, antes de que los scripts estuvieran listos, se crearon manualmente algunos artefactos. Quedan registrados aquí para que cualquier ajuste futuro sepa de ellos:

| Artefacto | SchemaName | Origen | Acción |
|---|---|---|---|
| `pas_consecutivo` (columna primary) | `pas_consecutivo` (lowercase) | Manual | Aceptado — primary name no es renombrable post-creación |
| `pas_estado` (columna picklist) | `pas_estado` (lowercase) | Manual | Aceptado por simetría con pas_consecutivo |
| `pas_solicitante` (columna lookup) | `pas_solicitante` (lowercase) | Manual | Aceptado — la relación correspondiente quedó como `pas_iniciativa_solicitante_systemuser` |
| `pas_fecha_solicitud` (DateTime) | `pas_fecha_solicitud` | Manual | **Agregado al script y al modelo v1.1**, ahora reproducible |
| `pas_estados` (choice plural) | `pas_estados` | Manual, presumiblemente duplicado experimental | Mantener o eliminar — no se usa en código. No es el choice oficial (`pas_iniciativa_estado`) |

**Para QA y PROD**: cuando se ejecute provisioning fresh, todo será uniforme con SchemaName PascalCase porque saldrá del script. La inconsistencia es solo en DEV.

## Estado actual (registro de provisioning)

| Environment | Choices | Tablas | Columnas custom | Relaciones | Fecha |
|---|---|---|---|---|---|
| DEV (`org93905a7d`) | 11 oficiales + 1 manual (`pas_estados`) | 12 ✅ | ~96 (95 script + 1 manual) | 19 ✅ | 2026-05-24 |
| QA (`org8b65c4d6`) | — | — | — | — | pendiente |
| PROD (cliente) | — | — | — | — | pendiente — ver [`entrega-cliente.md`](../architecture/entrega-cliente.md) |

## Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `Only Local option set can be created` | Picklist columna no usó `GlobalOptionSet@odata.bind` | Ejecutar 02 primero, luego 03. Si el bug persiste, revisar lib helper |
| `Cannot convert a value to target type 'Edm.Decimal'` | Decimal Min/Max enviado como int en vez de [decimal] | Actualizar a versión del script con `[decimal]` cast en Build-DecimalAttribute |
| `An attribute with the specified name X already exists` | Lookup/columna creada manualmente | Script lo detecta vía idempotencia y skip. Si insiste, revisar Get-DataverseAttribute |
| `30 other components depend on this entity` | Trying to DELETE entity con relaciones activas | NO dropear tabla con dependencias. Surgical fix por columna/relación específica. |
| `IsGlobal flag must be set to false` | Estructura inline del optionset en lugar de bind | Asegurar uso de `GlobalOptionSet@odata.bind` (versión actualizada del script) |

## Próximos pasos del Sprint 0

- **#21 (S0-10)**: `seed-data.ps1` puebla los catálogos placeholder (3 centros costo, 5 plantillas correo, parámetros, etc.) — usa misma `lib/dataverse.ps1`
- **#14 (S0-3)**: matriz Security Roles ahora se puede ejecutar (necesitaba que las tablas existieran)
- **#16 (S0-5)**: Service Principal + Connection References + Environment Variables
- **#17 (S0-6)**: CI/CD pipeline que empaqueta `innova_core` y produce releases
