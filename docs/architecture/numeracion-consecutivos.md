# Algoritmo de consecutivo de iniciativas — INNOVA

> **Versión**: 1.1 (issue #34 / G7 — EPIC #27)
> **Estado**: **Implementado como Plug-in C#** (`IniciativaPreCreatePlugin`) deployado en DEV. Smoke test passing. Ver [`plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaPreCreatePlugin.cs`](../../plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaPreCreatePlugin.cs).
>
> **Cambio de Opción A → Opción B**: la decisión original era Power Automate con `Concurrency Control=1`. Se cambió a Plug-in C# porque (1) implementable end-to-end via código sin portal, (2) menor latencia, (3) ventana de race-condition más pequeña (mismo transaction), (4) tests unit-testables.

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

## Estrategia anti race-condition (implementada)

Dataverse no provee transacciones de aislamiento configurables, pero los plug-ins en **Stage 20 (PreOperation)** corren DENTRO del transaction del Create, lo que minimiza la ventana entre `Max()` y el `Insert`.

### Implementación actual: Plug-in C# Pre-Create

`IniciativaPreCreatePlugin` registrado en DEV con:
- **Mode**: Synchronous
- **Stage**: 20 (PreOperation, transactional)
- **Message**: Create
- **Entity**: pas_iniciativa
- **Filter**: ninguno (corre en todo Create)

El plug-in:
1. Filtra por mensaje Create + entidad pas_iniciativa
2. Si target ya trae `pas_consecutivo` no vacío → respeta (idempotencia para imports)
3. Resuelve `empresa.pas_codigo_corto` via `Retrieve`
4. Valida regex `^[A-Z]{3}$` en codigo_corto (throw `InvalidPluginExecutionException` si inválido)
5. Calcula MAX(pas_consecutivo_secuencia) WHERE empresa=X AND anio=Y → siguiente = max+1 (o 1 si no hay)
6. Si siguiente > 999 → throw "límite alcanzado"
7. Mutta target con pas_consecutivo, pas_consecutivo_secuencia, pas_anio
8. El Insert del transaction usa esos valores

### Ventana de race-condition residual

Entre el `RetrieveMultiple(Max)` y el commit del Insert puede haber otro Create concurrente que vea el mismo Max. Para throughput < 1 iniciativa/segundo (esperado en INNOVA) esto NUNCA va a pasar en la práctica. Si en el futuro pasa:

**Opción de mitigación (no implementada)**: agregar unique constraint a nivel de entidad sobre `(pas_empresa, pas_anio, pas_consecutivo_secuencia)`. El segundo Insert fallaría con DuplicateRecord; agregar retry loop en el plug-in (max 3 reintentos con delay 50ms).

### Opciones rechazadas

- **Power Automate con Concurrency=1**: más latencia, dependencia del flow runtime, harder to unit-test
- **SQL custom function (TDS endpoint)**: rompe portabilidad al tenant del cliente

## Tests

- **Unit tests** (`plugins/Pasqui.Innova.Plugins.Tests/ConsecutivoFormatterTests.cs`): 28 tests del formatter puro
- **Logic tests** (`IniciativaPreCreatePluginTests.cs`): 17 tests con fakes de `IOrganizationService` que cubren los 6 casos del runbook (sección "Pruebas mínimas") + idempotencia + errores
- **Smoke test E2E** (`scripts/plugins/smoke-test-consecutivo.ps1`): crea iniciativa via API en DEV, verifica consecutivo asignado, formato regex, year correcto; auto-cleanup post-validación

Total: **45 tests passing** local + smoke test PASS en DEV.

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
