# Algoritmo de consecutivo de iniciativas — INNOVA

> **Versión**: 1.0 (issue #34 / G7 — EPIC #27)
> **Estado**: Diseño aprobado. Implementación del flow helper queda pendiente para Sprint posterior (referenciado por S0-8 #19).

## Formato

```
COA-2026-001
└┬┘ └┬─┘ └┬─┘
 │   │    └─ Secuencia incremental por empresa+año, 3 dígitos con leading zeros (000-999)
 │   └────── Año de creación (4 dígitos)
 └────────── Código corto de la empresa (3 letras ASCII MAYÚSCULAS)
```

Ejemplos:
- `COA-2026-001` — primera iniciativa de "Comercial A" en 2026
- `COA-2026-002` — segunda iniciativa de "Comercial A" en 2026
- `PSI-2026-001` — primera iniciativa de "Pasquí Industrial" en 2026
- `PSI-2027-001` — primera de "Pasquí Industrial" en 2027 (la secuencia se reinicia por año)

## Esquema asociado

| Columna | Tabla | Tipo | Notas |
|---|---|---|---|
| `pas_codigo_corto` | `pas_empresa` | String(3), ApplicationRequired | Validar en UI/flow: regex `^[A-Z]{3}$` |
| `pas_consecutivo` | `pas_iniciativa` | String(20), ApplicationRequired | Resultado completo. Único por construcción |
| `pas_consecutivo_secuencia` | `pas_iniciativa` | Integer (0-999999) | Secuencia numérica aislada. Permite calcular el siguiente sin parsear el string |
| `pas_anio` | `pas_iniciativa` | Integer (2024-2100) | Año usado para la secuencia. Se llena por flow al transición de Borrador → Revisión inicial PMO |
| `pas_empresa` | `pas_iniciativa` | Lookup → pas_empresa | Empresa cuya secuencia se incrementa |

## Algoritmo

```
ENTRADA: iniciativaId
SALIDA:  consecutivo (string), secuencia (int)

1. Obtener iniciativa
   - empresa ← pas_iniciativa.pas_empresa
   - año ← Year(UtcNow()) — usar UTC para evitar drift por zona horaria
2. Obtener empresa
   - codigoCorto ← empresa.pas_codigo_corto
   - Si NULL → throw "Empresa sin codigo_corto configurado"
   - Si no matchea ^[A-Z]{3}$ → throw "Codigo corto debe ser 3 letras ASCII upper"
3. Calcular siguiente secuencia (con lock para evitar race)
   - candidates ← Filter(pas_iniciativa
                       , pas_empresa = empresa
                       , pas_anio = año
                       , pas_consecutivo_secuencia IS NOT NULL)
   - maxSeq ← Max(candidates.pas_consecutivo_secuencia) si existe, else 0
   - nuevaSeq ← maxSeq + 1
4. Componer consecutivo
   - consecutivo ← Format("{0}-{1}-{2:000}", codigoCorto, año, nuevaSeq)
5. Patchar iniciativa
   - pas_consecutivo = consecutivo
   - pas_consecutivo_secuencia = nuevaSeq
   - pas_anio = año
6. Devolver (consecutivo, nuevaSeq)
```

## Estrategia anti race-condition

Dataverse no provee transacciones de aislamiento. Para evitar consecutivos duplicados cuando dos iniciativas se envían simultáneamente:

### Opción A (recomendada): Power Automate `Concurrency Control = 1`

En el flow helper `INNOVA - Helper - Generar Consecutivo`:

- **Settings → Concurrency Control → On → Degree of Parallelism: 1**

Esto serializa todas las ejecuciones del flow. Throughput suficiente (< 1 iniciativa/segundo esperado).

Trade-off: una llamada bloquea brevemente las siguientes — aceptable.

### Opción B (futuro, si throughput aumenta): Plugin C# con `LockManager`

Si las iniciativas superan ~10/segundo, migrar a un plugin que use `System.Threading.SemaphoreSlim` por `empresaId+año` y haga el cálculo + insert en una sola transacción Dataverse vía `OrganizationServiceContext.SaveChanges()`.

### Opción C (rechazada): SQL custom function

Dataverse no expone `INSERT ... SELECT MAX() FROM ... FOR UPDATE` directamente. Habría que usar SQL TDS endpoint, lo cual rompe portabilidad al tenant del cliente.

## Flow helper

**Nombre**: `INNOVA - Helper - Generar Consecutivo`
**Tipo**: Child flow
**Trigger**: Manual / Child flow trigger
**Inputs**: `iniciativaId` (string GUID)
**Outputs**: `consecutivo` (string), `secuencia` (integer)
**Concurrency**: 1 (Settings)
**Run-after policy**: ninguna externa (el caller decide)

Implementación pendiente para sprint posterior — referenciado por S0-8 (#19).

## Validaciones de entrada (en M11 Admin)

Cuando el Administrador captura/edita una empresa:

| Campo | Validación |
|---|---|
| `pas_codigo_corto` | Exactamente 3 caracteres `^[A-Z]{3}$` |
| `pas_codigo_corto` | Único (no permitir duplicados) — validar via `Filter(pas_empresas, pas_codigo_corto = nuevo).Count = 0` |

## Migración del formato anterior

El formato anterior (`INI-{año}-{seq:00000}`) **no se usó en producción** (Sprint 0 sin datos). No requiere migración.

Si en el futuro hubiera datos con formato viejo, la migración sería:
1. Identificar todos los `pas_consecutivo` que matchean `^INI-\d{4}-\d{5}$`
2. Para cada uno: parsear el año y secuencia, calcular el nuevo formato usando el código corto de la empresa
3. Patchar con `pas_consecutivo` (nuevo) y `pas_consecutivo_secuencia` (parseado)

## Pruebas mínimas (cuando se implemente el flow)

| Caso | Setup | Esperado |
|---|---|---|
| Primera iniciativa de empresa A en 2026 | `pas_codigo_corto=COA`, año=2026, no iniciativas previas | `COA-2026-001`, seq=1 |
| Segunda iniciativa de empresa A en 2026 | + una previa con seq=1 | `COA-2026-002`, seq=2 |
| Primera iniciativa de empresa B en 2026 | `pas_codigo_corto=PSI` | `PSI-2026-001`, seq=1 (no interfiere con COA) |
| Primera iniciativa de empresa A en 2027 | año cambia | `COA-2027-001`, seq=1 (se reinicia por año) |
| Sin código corto | empresa sin `pas_codigo_corto` | flow falla con mensaje explícito |
| Código corto inválido | `pas_codigo_corto = "AB"` (2 chars) | flow falla en validación regex |

## Referencias

- Modelo: [`data-model.md`](data-model.md) v1.5+
- Issue: [#34](https://github.com/rcrala/gestor-iniciativas/issues/34)
- EPIC: [#27](https://github.com/rcrala/gestor-iniciativas/issues/27)
- Convención de empresas: [`docs/decisions/0003-arquitectura-multi-empresa.md`](../decisions/0003-arquitectura-multi-empresa.md)
