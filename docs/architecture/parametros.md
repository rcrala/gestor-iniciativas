# Parámetros operacionales — INNOVA

> **Versión**: 1.0 (issue #35 / G8 — EPIC #27)
> **Tabla**: `pas_parametro`
> **Script de seed**: [`scripts/setup/06-seed-parametros.ps1`](../../scripts/setup/06-seed-parametros.ps1)
> **Gestionado por**: Administrador via M11. Modificable en producción sin redeploy.

## ¿Por qué parámetros?

Toda regla de negocio susceptible de cambiar (umbrales, tarifas, días, branding) vive en `pas_parametro` en lugar de hardcoded en flows o Canvas Apps. Permite:

1. El cliente puede ajustar valores sin tocar código (vía M11 Admin)
2. La solución es portable a otros tenants sin recompilar
3. Versionado por audit nativo de Dataverse: quién cambió qué y cuándo
4. Test fixtures (cambiar `UmbralEscalamientoComite_USD` a $1 para forzar escalamiento en pruebas)

## Estructura de `pas_parametro`

| Columna | Tipo | Notas |
|---|---|---|
| `pas_clave` | String(100), Primary | Identificador estable (no localizar) |
| `pas_nombre_display` | String(200) | Etiqueta amigable para M11 |
| `pas_tipo` | Choice | Texto / Número / Fecha / Booleano |
| `pas_valor_texto` | String(2000) | Si tipo=Texto |
| `pas_valor_numero` | Decimal | Si tipo=Número |
| `pas_valor_fecha` | DateTime | Si tipo=Fecha |
| `pas_valor_booleano` | Boolean | Si tipo=Booleano |
| `pas_unidad` | String(20) | Documentación de la unidad ("CRC/hora", "USD", "días") |
| `pas_descripcion` | Memo(1000), required | Qué controla este parámetro |

Solo se popula la columna de valor correspondiente al `pas_tipo`.

## Parámetros sembrados por `06-seed-parametros.ps1`

| Clave | Tipo | Valor default | Unidad | Para qué |
|---|---|---|---|---|
| `TarifaHoraPMO` | Número | 25000 | CRC/hora | Snapshot en `pas_horatrabajo.pas_tarifa_aplicada` al crear horas tipo "Levantamiento PMO" |
| `TarifaHoraDesarrollador` | Número | 35000 | CRC/hora | Snapshot al crear horas tipo "Estimación TI" |
| `UmbralEscalamientoComite_USD` | Número | 10000 | USD | BR-14: si `pas_monto_estimado` (USD-equiv.) supera este valor, va a Comité |
| `MultiEmpresaEscalaComite` | Booleano | true | — | BR-13: si true, multi-empresa va siempre a Comité (independiente del monto). Configurable según C4 del cliente |
| `HorasComplejidadBaja` | Número | 16 | horas | Sugerido para `pas_evaluacionpmo.pas_horas_levantamiento` cuando PMO elige complejidad=Baja |
| `HorasComplejidadMedia` | Número | 48 | horas | Idem complejidad=Media |
| `HorasComplejidadAlta` | Número | 56 | horas | Idem complejidad=Alta |
| `HorasComplejidadMuyAlta` | Número | 96 | horas | Idem complejidad=Muy Alta |
| `DiasRecordatorio` | Número | 3 | días | BR-16: si una iniciativa lleva N días sin cambio de estado, mandar recordatorio |
| `BrandingLogoUrl` | Texto | `https://placeholder.cdn/innova-logo.png` | — | URL del logo del cliente. Configurable según C6 |
| `BrandingPrimaryColor` | Texto | `#0078D4` | hex | Color primario. Default del mockup; ajustar según branding del cliente |
| `BrandingSecondaryColor` | Texto | `#FF8C00` | hex | Color secundario / accent |

**Total**: 12 parámetros.

## Patrón de lectura desde Power Fx / Power Automate

### Power Fx (Canvas App)

Cargar al inicio en una colección y referenciar via lookup:

```powerfx
// App.OnStart
ClearCollect(colParametros, pas_parametros);

// Cuando se necesita un valor:
Set(gblUmbralComite, LookUp(colParametros, pas_clave = "UmbralEscalamientoComite_USD").pas_valor_numero);
Set(gblColorPrimario, LookUp(colParametros, pas_clave = "BrandingPrimaryColor").pas_valor_texto);
```

### Power Automate

Acción **List rows** con filter:

```
table: pas_parametros
filter: pas_clave eq 'UmbralEscalamientoComite_USD'
```

Output: `first(body('List_rows')['value'])?['pas_valor_numero']`

> **Buena práctica**: en flows críticos (los que disparan correos o cambian estados), cachear los parámetros al inicio del flow (un Scope "Load Parámetros") en lugar de hacer una llamada por cada uso.

## Cuándo agregar un nuevo parámetro

Reglas de oro:

1. **Si un número, texto, fecha o booleano puede cambiar después de Go-Live → es parámetro**
2. **Si está limitado a un dominio cerrado de < 10 valores → mejor un Choice global, no parámetro**
3. **Si el cliente lo modificará vía UI → parámetro + visible en M11**

### Proceso

1. Agregar la definición a `scripts/setup/06-seed-parametros.ps1` (incluir `Descripcion` clara)
2. Re-ejecutar el script: idempotente, solo agregará los nuevos
3. Documentar aquí (tabla de parámetros)
4. Si el flow/canvas consumidor existe, actualizarlo para leer del parámetro en lugar de hardcoded
5. Validar que M11 (cuando exista) renderice el nuevo parámetro automáticamente (`pas_tipo` lo dirige al input correcto)

## Cuándo NO crear un parámetro

| Caso | Mejor alternativa |
|---|---|
| Tenant URL, Connection ID, App Registration secret | **Environment Variable** (ver [`entrega-cliente.md`](entrega-cliente.md)) |
| Lista de valores enumerados (estados, prioridades) | **Choice global** (en `02-create-choice-sets.ps1`) |
| Datos de catálogo (departamentos, sistemas) | **Tabla de configuración** propia (ver `pas_departamento`, `pas_sistema`) |
| Constantes inmutables (formato de fecha, encoding) | **App.Formulas** named formula |

## Idempotencia y override manual

El script `06-seed-parametros.ps1` por default **NO sobreescribe** valores existentes. Esto es intencional: una vez que el Admin ajusta `TarifaHoraPMO` a 28000 vía M11, re-ejecutar el script no debe pisar el cambio.

Si se quiere forzar reset al default (ej. tras corrupción):

```powershell
.\scripts\setup\06-seed-parametros.ps1 -Environment dev -ForceUpdate -WhatIf  # primero dry-run
.\scripts\setup\06-seed-parametros.ps1 -Environment dev -ForceUpdate          # despues real
```

## Validaciones en M11 (cuando se implemente)

Cuando el Admin edite un parámetro:

| Campo | Validación |
|---|---|
| `pas_clave` | Inmutable después de crear (read-only en edición) |
| `pas_tipo` | Inmutable después de crear (cambio de tipo requiere borrar y recrear) |
| `pas_valor_numero` | Si `pas_clave` empieza con "Horas..." → > 0. Si "Umbral..." → > 0. Si "Dias..." → > 0 |
| `pas_valor_texto` | Si `pas_clave` empieza con "BrandingColor" → matchea `^#[0-9A-Fa-f]{6}$` |
| `pas_valor_texto` | Si `pas_clave` termina con "Url" → matchea URL válida |

## Referencias

- Tabla en modelo: [`data-model.md#pas_parametro`](data-model.md)
- Choices: [`02-create-choice-sets.ps1`](../../scripts/setup/02-create-choice-sets.ps1) (`pas_parametro_tipo`)
- Script de seed: [`06-seed-parametros.ps1`](../../scripts/setup/06-seed-parametros.ps1)
- Issue: [#35](https://github.com/rcrala/gestor-iniciativas/issues/35)
- EPIC: [#27](https://github.com/rcrala/gestor-iniciativas/issues/27)
- C4 y C6 del cliente: [`docs/01-Requeriments/analisis-requerimiento-cliente.md`](../01-Requeriments/analisis-requerimiento-cliente.md)
