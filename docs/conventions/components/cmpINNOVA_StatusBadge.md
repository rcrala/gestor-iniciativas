# cmpINNOVA_StatusBadge

> **Tipo**: UI Atom (Component)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Pill/badge visual que renderiza un valor del choice `pas_iniciativa_estado` con **color por categoría** y label legible. Garantiza que el estado de una iniciativa se vea idéntico en M2, M3, M5, M7, M9, M11, M12, M13 — sin que cada pantalla tenga que reimplementar el mapeo estado→color.

## Dónde se usa

- **M2 Solicitante**: estado actual del borrador (siempre "Borrador") y vista de iniciativas anteriores
- **M3 PMO Evaluación**: estado actual + posibles próximos
- **M5/M7 Jefatura**: estado pre-decisión
- **M9/M10 Gerencia/Comité**: estado pre-voto
- **M11 Administrador**: vistas administrativas
- **M12 Mis Solicitudes**: badges en cada fila de la tabla
- **M13 Reportes**: columnas de tabla y filtros

## Referencia visual del cliente

Ver [docs/01-Requeriments/media/image3.png](../../01-Requeriments/media/image3.png) (M12 Mis solicitudes) — la tabla muestra columnas de estado con badges coloreados ("En Evaluación PMO" naranja, "Aprobada" verde, "Rechazada" rojo, etc.). Patrón replicado en M11/M13.

## ASCII wireframe

```
Tamaño regular (default):
┌────────────────────────────┐
│  ● Revisión inicial PMO    │
└────────────────────────────┘
     ↑      ↑
   dot     label (alineado vertical centro)
   (color  Auto-width o fixed según ppAnchoFijo
   por
   categ.)

Tamaño small (ppCompacto=true, para tablas densas):
┌──────────┐
│ Aprobada │
└──────────┘
```

Border-radius: **12 px** (pill shape). Padding interno: **8 px horizontal, 4 px vertical**.

## Input properties (`pp*`)

| Property | Tipo | Default | Required | Descripción |
|---|---|---|---|---|
| `ppValorEstado` | Number | `100000000` (Borrador) | sí | Valor numérico del choice `pas_iniciativa_estado` (100000000-100000016). Lo lee directamente del campo `pas_iniciativa.pas_estado` |
| `ppCompacto` | Boolean | `false` | no | Si true, label se trunca y tamaño se reduce a ~24px alto. Útil para tablas densas (M12, M13) |
| `ppAnchoFijo` | Number | `0` | no | Si > 0, el badge tiene ese ancho fijo en px (útil para alineación en columnas de tabla). Si 0, ajusta al contenido |
| `ppMostrarDot` | Boolean | `true` | no | Muestra el punto coloreado a la izquierda del label. Se puede ocultar si se quiere usar el color solo en el fill |

## Output properties (`oo*`)

| Property | Tipo | Disparado cuando... | Descripción |
|---|---|---|---|
| `ooOnSelect` | Behavior | Click en el badge | Opcional: la pantalla hospedante puede abrir un panel con el detalle de qué significa ese estado, o navegar al detalle de la iniciativa |

## Mapping estado → label → categoría → color

El componente tiene **internamente** este lookup table (no es input para no exponerlo al maker):

| Value | Label | Categoría visual | Color hex |
|---|---|---|---|
| 100000000 | Borrador | Inicial | `#94A3B8` (gris) |
| 100000001 | Revisión inicial PMO | Evaluación | `#3B82F6` (azul) |
| 100000002 | Estimación Desarrollo | Estimación | `#06B6D4` (cian) |
| 100000003 | Revisión Estimación de la Jefatura | Estimación | `#06B6D4` (cian) |
| 100000004 | Estimación Aprobada por Jefatura | Estimación | `#10B981` (verde claro) |
| 100000005 | Estimación Devuelta por Jefatura | Estimación | `#F59E0B` (amarillo) |
| 100000006 | Estimación Rechazada por Jefatura | Terminal-Rechazo | `#EF4444` (rojo) |
| 100000007 | Revisión Iniciativa Jefatura | Evaluación | `#3B82F6` (azul) |
| 100000008 | Iniciativa Devuelta por Jefatura | Evaluación | `#F59E0B` (amarillo) |
| 100000009 | En Cotización | Cotización | `#8B5CF6` (violeta) |
| 100000010 | Revisión Gerencia de Negocio | Aprobación | `#6366F1` (indigo) |
| 100000011 | Aprobada por Gerencia General de Negocio | Aprobación | `#10B981` (verde claro) |
| 100000012 | Rechazada por Gerencia General de Negocio | Terminal-Rechazo | `#EF4444` (rojo) |
| 100000013 | Revisión Comité de Proyectos | Comité | `#A855F7` (púrpura) |
| 100000014 | Aprobada | Terminal-Aprobado | `#16A34A` (verde fuerte) |
| 100000015 | Rechazo del Comité | Terminal-Rechazo | `#DC2626` (rojo fuerte) |
| 100000016 | Cancelada | Terminal-Cancelado | `#64748B` (gris oscuro) |

Estos valores coinciden 1:1 con los labels documentados en [`docs/architecture/data-model.md`](../../architecture/data-model.md#pas_iniciativa_estado-17-valores) (alineados con cuadro resumen del cliente, issue #33 / G6).

## Power Fx por propiedad clave

### Container (rectángulo del badge)

```powerquery
// Fill
With(
    {
        cat: Switch(
            Self.ppValorEstado,
            100000000, "Inicial",
            100000001, "Evaluacion",
            100000002, "Estimacion",
            100000003, "Estimacion",
            100000004, "Estimacion",
            100000005, "Estimacion",
            100000006, "TerminalRechazo",
            100000007, "Evaluacion",
            100000008, "Evaluacion",
            100000009, "Cotizacion",
            100000010, "Aprobacion",
            100000011, "Aprobacion",
            100000012, "TerminalRechazo",
            100000013, "Comite",
            100000014, "TerminalAprobado",
            100000015, "TerminalRechazo",
            100000016, "TerminalCancelado",
            "Inicial"
        )
    },
    Switch(
        cat,
        "Inicial",          ColorValue("#94A3B8") & "20",   // 20 = 12.5% alpha
        "Evaluacion",       ColorValue("#3B82F6") & "20",
        "Estimacion",       ColorValue("#06B6D4") & "20",
        "Cotizacion",       ColorValue("#8B5CF6") & "20",
        "Aprobacion",       ColorValue("#6366F1") & "20",
        "Comite",           ColorValue("#A855F7") & "20",
        "TerminalAprobado", ColorValue("#16A34A") & "20",
        "TerminalRechazo",  ColorValue("#DC2626") & "20",
        "TerminalCancelado", ColorValue("#64748B") & "20",
        ColorValue("#94A3B8") & "20"
    )
)

// RadiusTopLeft, TopRight, BottomLeft, BottomRight
12, 12, 12, 12

// Height
If(Self.ppCompacto, 24, 32)

// Width
If(
    Self.ppAnchoFijo > 0,
    Self.ppAnchoFijo,
    // auto: label.Width + (16 padding) + (dot ? 16 : 0)
    LabelBadge.Width + 16 + If(Self.ppMostrarDot, 16, 0)
)
```

### Dot (Circle control, visible condicional)

```powerquery
// Visible
Self.ppMostrarDot

// Fill (color "fuerte" del estado, sin alpha)
Switch(
    Parent.ppValorEstado,
    100000000, ColorValue("#94A3B8"),
    100000001, ColorValue("#3B82F6"),
    // ... mismos colores que arriba pero al 100%
    100000014, ColorValue("#16A34A"),
    100000015, ColorValue("#DC2626"),
    100000016, ColorValue("#64748B"),
    ColorValue("#94A3B8")
)

// Width, Height
If(Parent.ppCompacto, 6, 8)
```

### Label (texto del estado)

```powerquery
// Text
Switch(
    Parent.ppValorEstado,
    100000000, "Borrador",
    100000001, "Revisión inicial PMO",
    100000002, "Estimación Desarrollo",
    100000003, "Revisión Estimación de la Jefatura",
    100000004, "Estimación Aprobada por Jefatura",
    100000005, "Estimación Devuelta por Jefatura",
    100000006, "Estimación Rechazada por Jefatura",
    100000007, "Revisión Iniciativa Jefatura",
    100000008, "Iniciativa Devuelta por Jefatura",
    100000009, "En Cotización",
    100000010, "Revisión Gerencia de Negocio",
    100000011, "Aprobada por Gerencia General de Negocio",
    100000012, "Rechazada por Gerencia General de Negocio",
    100000013, "Revisión Comité de Proyectos",
    100000014, "Aprobada",
    100000015, "Rechazo del Comité",
    100000016, "Cancelada",
    "—"
)

// Size
If(Parent.ppCompacto, 11, 12)

// Color (color "fuerte" del estado, igual que el dot)
Switch(
    Parent.ppValorEstado,
    100000000, ColorValue("#475569"),   // texto más oscuro que el dot para legibilidad
    100000001, ColorValue("#1E40AF"),
    // ... versión más oscura del color del estado
    100000014, ColorValue("#14532D"),
    100000015, ColorValue("#7F1D1D"),
    ColorValue("#475569")
)

// FontWeight
FontWeight.Semibold

// PaddingLeft, PaddingRight
0, 0
```

## Ejemplo de instanciación

### En una galería (M12 Mis solicitudes)

```powerquery
// Dentro de gallery item template, sobre el card:
// cmpINNOVA_StatusBadge_1.ppValorEstado = ThisItem.pas_estado
// cmpINNOVA_StatusBadge_1.ppCompacto = true   // tabla densa
// cmpINNOVA_StatusBadge_1.ppAnchoFijo = 180   // alineación de columna
```

### En el form de M3 PMO Evaluación (mostrar el estado actual de la iniciativa)

```powerquery
// cmpINNOVA_StatusBadge_2.ppValorEstado = formIniciativa.LastSubmit.pas_estado
// cmpINNOVA_StatusBadge_2.ppCompacto = false   // tamaño regular
// cmpINNOVA_StatusBadge_2.ppAnchoFijo = 0      // auto-width
```

### Con OnSelect (abrir tooltip de detalle)

```powerquery
// cmpINNOVA_StatusBadge_3.ooOnSelect = UpdateContext({locMostrarTooltipEstado: true})
```

## Reglas de uso

- **No alterar los labels** sin coordinar con el modelo — los labels coinciden con `pas_iniciativa_estado` choice (cliente firmó issue #33). Cambiarlos genera divergencia entre UI y data
- **No agregar valores nuevos sin agregar al choice también**: si negocio quiere un nuevo estado, primero se agrega al choice (script `02-create-choice-sets.ps1`) y al `EstadoTransitionMatrix.cs`, **después** al badge
- **Para tablas grandes** (>20 filas visibles), usar siempre `ppCompacto=true` por rendimiento visual
- **Si el contexto es de bajo color** (M9 print/PDF export), considerar usar `ppMostrarDot=false` y solo el label con fill alpha bajo

## Cambios breaking que requerirían V2

- Cambiar `ppValorEstado` de Number a Text (forzaría re-cablear todas las pantallas)
- Eliminar los terminales del switch (apps con datos en estados removidos mostrarían "—")

Cambios no-breaking OK directo en V1:
- Ajustar paleta de colores manteniendo categorías
- Agregar `pp*` opcionales (ej. `ppMostrarIcono` para sumar un ícono al dot)
- Mejorar accessibility (aria-labels, contrast ratio)

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Mockup con badges: [`../../01-Requeriments/media/image3.png`](../../01-Requeriments/media/image3.png) (M12 tabla)
- Choice de estados: [`../../architecture/data-model.md#pas_iniciativa_estado-17-valores`](../../architecture/data-model.md)
- Máquina de estados (transiciones): [`../../architecture/estados-iniciativa.md`](../../architecture/estados-iniciativa.md)
- Plugin que enforce la matriz: [`plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs`](../../../plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs)
