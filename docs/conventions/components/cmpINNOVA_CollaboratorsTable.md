# cmpINNOVA_CollaboratorsTable

> **Tipo**: Functional Container (Component)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Tabla **dinámica** add/remove con N filas para registrar colaboradores que invierten tiempo en el proceso actual de una iniciativa. Persiste contra la tabla Dataverse **`pas_colaboradorcosto`** (creada en issue #30 / G3 / PR #58).

## Dónde se usa

- **M2 Solicitante**: bloque "Colaboradores que invierten tiempo en el proceso actual" del formulario de nueva iniciativa (visible siempre)
- **M3 PMO** (read-only): para referencia visual del PMO al calcular `pas_iniciativa.pas_costo_actual_proceso`
- **M5/M7 Jefatura** (read-only): para referencia al revisar la iniciativa

## Referencia visual del cliente

[image4.png](../../01-Requeriments/media/image4.png) M2 — la tabla muestra columnas Nombre / Puesto / Horas mensuales con botón "+" para agregar fila y "🗑" en cada fila para remover.

## ASCII wireframe

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  Nombre del colaborador │ Puesto del colaborador │ Horas mensuales │ Acción     │
├─────────────────────────┼────────────────────────┼─────────────────┼────────────┤
│ Andrea Vargas           │ Analista financiera    │           20.00 │  🗑        │
│ Carlos Méndez           │ Asistente              │           10.50 │  🗑        │
│ [______________]        │ [____________]         │ [______]        │  🗑        │  ← fila editable nueva
├─────────────────────────┴────────────────────────┴─────────────────┴────────────┤
│                                                              [+ Agregar fila]   │
└──────────────────────────────────────────────────────────────────────────────────┘
   ↑ Bordes sutiles
   Header row con background gris claro
   Total mensual abajo (opcional): "Total: 30.5 hrs/mes" alineado a la derecha
```

Alto: **calculado dinámicamente** por cantidad de filas (header 40 + filas 36 cada una + footer 48).
Width: **fill** del padre (`Parent.Width - margin`).

## Input properties (`pp*`)

| Property | Tipo | Default | Required | Descripción |
|---|---|---|---|---|
| `ppIniciativaId` | GUID | (blank) | sí | ID de la `pas_iniciativa` padre. Determina contra qué iniciativa se filtran y persisten las filas. En M2 puede ser blank antes del primer Save de la iniciativa, en cuyo caso el componente trabaja en modo "collection local" hasta que se persista |
| `ppModoSoloLectura` | Boolean | `false` | no | Si true: oculta inputs editables y botón "+", muestra solo lectura. Para M3/M5/M7 |
| `ppTema` | Record | (default tema) | sí | Tema visual estándar |
| `ppMostrarTotal` | Boolean | `true` | no | Mostrar fila de "Total: X hrs/mes" abajo. Útil para que PMO vea el agregado |
| `ppMaxFilas` | Number | `20` | no | Límite duro de filas para evitar abuso (no hay caso real con >20 colaboradores) |

## Output properties (`oo*`)

| Property | Tipo | Disparado cuando... | Descripción |
|---|---|---|---|
| `ooTotalHorasMensuales` | Number | (reactivo) | Suma de `pas_horas_mensuales` de todas las filas activas. La pantalla puede usarlo como referencia al setear `pas_iniciativa.pas_costo_actual_proceso` |
| `ooCantidadColaboradores` | Number | (reactivo) | Conteo de filas activas. Útil para mostrar "3 colaboradores registrados" |
| `ooColeccionLocal` | Table | (reactivo) | Si `ppIniciativaId` es blank (modo pre-save), output de la collection local con las filas. La pantalla la persiste con un loop `ForAll(...Patch(...))` al guardar la iniciativa |
| `ooOnSelectAgregarFila` | Behavior | Click en "+ Agregar fila" | Opcional: la pantalla puede capturar para logging o validación pre-add |

## Comportamiento dual: persistido vs local

El componente opera en **2 modos** según `ppIniciativaId`:

### Modo persistido (`ppIniciativaId` no blank)
- Cada fila se hace `Patch(pas_colaboradorcostos, ...)` inmediatamente al perder foco
- Eliminar fila → `Remove(pas_colaboradorcostos, ...)`
- La gallery interna lee `Filter(pas_colaboradorcostos, pas_iniciativa.pas_iniciativaid = Self.ppIniciativaId && pas_activo = true)`

### Modo local (`ppIniciativaId` blank)
- Las filas viven en una `Collection()` local del componente: `colColaboradoresLocal`
- Al editar, modifica la collection
- Al `+ Agregar fila`, hace `Collect(colColaboradoresLocal, {pas_nombre_colaborador: "", ...})`
- El componente expone `ooColeccionLocal` para que el screen padre, al hacer el primer Save de la iniciativa, persista todo:
  ```powerquery
  // En la pantalla, al Submit del formulario de iniciativa:
  Set(varIniciativaNueva, Patch(pas_iniciativas, Defaults(pas_iniciativas), {...campos del form}));;
  ForAll(
      cmpINNOVA_CollaboratorsTable_1.ooColeccionLocal,
      Patch(
          pas_colaboradorcostos,
          Defaults(pas_colaboradorcostos),
          {
              pas_nombre_colaborador: ThisRecord.pas_nombre_colaborador,
              pas_puesto: ThisRecord.pas_puesto,
              pas_horas_mensuales: ThisRecord.pas_horas_mensuales,
              pas_descripcion_aporte: ThisRecord.pas_descripcion_aporte,
              pas_iniciativa: varIniciativaNueva,   // ya tiene ID después del primer Patch
              pas_activo: true
          }
      )
  )
  ```

## Power Fx por propiedad clave

### OnReset del componente (inicialización)

```powerquery
// Cuando el componente se monta o resetea
If(
    !IsBlank(Self.ppIniciativaId),
    // Modo persistido: nada local, todo lee de Dataverse
    ClearCollect(colColaboradoresLocal, []),
    // Modo local: inicializa con 1 fila vacía
    ClearCollect(colColaboradoresLocal, { pas_nombre_colaborador: "", pas_puesto: "", pas_horas_mensuales: 0, pas_descripcion_aporte: "" })
)
```

### Gallery (lista de filas)

```powerquery
// Items
If(
    !IsBlank(Self.ppIniciativaId),
    Filter(
        pas_colaboradorcostos,
        pas_iniciativa.pas_iniciativaid = Self.ppIniciativaId && pas_activo = true
    ),
    colColaboradoresLocal
)
```

### TextInput "Nombre del colaborador" (dentro de cada item del gallery)

```powerquery
// Default
ThisItem.pas_nombre_colaborador

// OnChange (modo persistido)
If(
    !IsBlank(Parent.ppIniciativaId),
    Patch(
        pas_colaboradorcostos,
        ThisItem,
        { pas_nombre_colaborador: Self.Text }
    ),
    // Modo local: actualizar collection
    UpdateIf(
        colColaboradoresLocal,
        ThisRecord.pas_nombre_colaborador = ThisItem.pas_nombre_colaborador
            && ThisRecord.pas_puesto = ThisItem.pas_puesto,
        { pas_nombre_colaborador: Self.Text }
    )
)
```

(Mismo patrón para `pas_puesto` TextInput y `pas_horas_mensuales` Number Input)

### Botón "🗑 eliminar" por fila

```powerquery
// OnSelect
If(
    !IsBlank(Parent.ppIniciativaId),
    // Soft delete en Dataverse
    Patch(
        pas_colaboradorcostos,
        ThisItem,
        { pas_activo: false }
    ),
    // Local: remover de collection
    Remove(colColaboradoresLocal, ThisItem)
)

// Visible
!Parent.ppModoSoloLectura
```

### Botón "+ Agregar fila" (footer)

```powerquery
// OnSelect
If(
    CountRows(colColaboradoresLocal) + CountRows(GalleryColaboradores.AllItems) >= Self.ppMaxFilas,
    Notify($"Máximo {Self.ppMaxFilas} colaboradores", NotificationType.Warning),
    If(
        !IsBlank(Self.ppIniciativaId),
        Patch(
            pas_colaboradorcostos,
            Defaults(pas_colaboradorcostos),
            {
                pas_nombre_colaborador: "",
                pas_puesto: "",
                pas_horas_mensuales: 0,
                pas_iniciativa: LookUp(pas_iniciativas, pas_iniciativaid = Self.ppIniciativaId),
                pas_activo: true
            }
        ),
        Collect(colColaboradoresLocal, { pas_nombre_colaborador: "", pas_puesto: "", pas_horas_mensuales: 0, pas_descripcion_aporte: "" })
    )
);;
Self.ooOnSelectAgregarFila()

// Visible
!Self.ppModoSoloLectura
```

### Output reactivo: total de horas

```powerquery
// ooTotalHorasMensuales
If(
    !IsBlank(Self.ppIniciativaId),
    Sum(
        Filter(pas_colaboradorcostos, pas_iniciativa.pas_iniciativaid = Self.ppIniciativaId && pas_activo = true),
        pas_horas_mensuales
    ),
    Sum(colColaboradoresLocal, pas_horas_mensuales)
)

// ooCantidadColaboradores
If(
    !IsBlank(Self.ppIniciativaId),
    CountRows(Filter(pas_colaboradorcostos, pas_iniciativa.pas_iniciativaid = Self.ppIniciativaId && pas_activo = true)),
    CountRows(colColaboradoresLocal)
)

// ooColeccionLocal
colColaboradoresLocal
```

## Ejemplo de instanciación

### M2 Solicitante (nueva iniciativa, antes del primer Save)

```powerquery
// cmpINNOVA_CollaboratorsTable_1.ppIniciativaId = Blank()  // no hay iniciativa todavía
// cmpINNOVA_CollaboratorsTable_1.ppModoSoloLectura = false
// cmpINNOVA_CollaboratorsTable_1.ppTema = gblTema
// cmpINNOVA_CollaboratorsTable_1.ppMostrarTotal = true
// cmpINNOVA_CollaboratorsTable_1.ppMaxFilas = 20
```

Al Submit de la iniciativa, el screen padre persiste tanto la iniciativa como las filas (ver código snippet en sección "Modo local" arriba).

### M2 Solicitante (editando borrador existente)

```powerquery
// cmpINNOVA_CollaboratorsTable_1.ppIniciativaId = LookUp(pas_iniciativas, pas_consecutivo = "COA-2026-001").pas_iniciativaid
// (resto igual)
```

### M3 PMO (read-only para referencia)

```powerquery
// cmpINNOVA_CollaboratorsTable_2.ppIniciativaId = gblIniciativaEnEvaluacion.pas_iniciativaid
// cmpINNOVA_CollaboratorsTable_2.ppModoSoloLectura = true
// cmpINNOVA_CollaboratorsTable_2.ppTema = gblTema
// Notar que ppMostrarTotal=true por default → PMO ve el total como referencia
// para capturar pas_iniciativa.pas_costo_actual_proceso
```

## Reglas de uso

- **`ppIniciativaId` blank solo en M2 borrador nuevo**: en cualquier otra pantalla siempre pasar el ID real
- **Persistir `ooColeccionLocal` al Submit** del form padre — si el usuario abandona el screen sin Save, las filas locales se pierden (comportamiento esperado: no creamos colaboradores huérfanos sin iniciativa)
- **`ppModoSoloLectura=true` en cualquier pantalla que NO sea M2** del solicitante editando — PMO/Jefatura no editan estas filas, son del solicitante
- **No usar como editor de horas reales trabajadas** (ese es `pas_horatrabajo`, otra tabla con flow). Este componente es exclusivo para `pas_colaboradorcosto`

## Cambios breaking que requerirían V2

- Cambiar `ppIniciativaId` de GUID a string (forzaría re-cablear)
- Eliminar el modo local (M2 borrador nuevo se rompería)
- Cambiar shape del output `ooColeccionLocal` (las pantallas que persisten al Submit fallarían)

Cambios no-breaking OK directo en V1:
- Agregar columnas opcionales (ej. `pas_descripcion_aporte` ya está en el modelo pero no muestra columna por default — agregar input `ppMostrarDescripcion` para activarla)
- Mejorar paginación si llegan a haber muchas filas
- Agregar validación de horas máximas por colaborador (ej. <= 200 hrs/mes)

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Mockup: [`../../01-Requeriments/media/image4.png`](../../01-Requeriments/media/image4.png)
- Tabla Dataverse: [`../../architecture/data-model.md`](../../architecture/data-model.md) sección `pas_colaboradorcosto`
- Issue #30 (creación de la tabla): https://github.com/rcrala/gestor-iniciativas/issues/30
- Patrón #5 (Patch con Defaults): [`../power-fx-patterns.md`](../power-fx-patterns.md)
- Patrón #15 (Patch a tabla N:1): [`../power-fx-patterns.md`](../power-fx-patterns.md)
