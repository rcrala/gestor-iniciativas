# cmpINNOVA_ValidationSummary

> **Tipo**: UI Container (Component)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Banner agrupador de **errores de validación de un formulario**, que se muestra arriba o abajo del form **antes** del Submit. Centraliza la UX de "qué te falta" en un solo lugar visible, en vez de tener mensajes de error dispersos por cada field.

## Dónde se usa

- **M2 Solicitante**: validar título, descripción, empresa, centro de costo, justificación, beneficios estratégicos antes de "Enviar"
- **M3 PMO Evaluación**: validar campos PMO (complejidad, costo, etc.) antes de cerrar evaluación
- **M4 TI Estimación**: validar horas + supuestos antes de cerrar estimación
- **M5/M7 Jefatura**: validar comentario obligatorio si decisión es "Devolver" o "Rechazar"
- **M9/M10 Gerencia/Comité**: validar comentario obligatorio si rechazo
- **M11 Administrador**: cualquier form de catálogo

## Referencia visual del cliente

No aparece explícitamente en los mockups (los mockups muestran estado feliz). Patrón estándar de UX que se asume.

## ASCII wireframe

```
Estado vacío (sin errores):
(no se renderiza)


Estado con errores (1+ errores):
┌────────────────────────────────────────────────────────────┐
│  ⚠️  Antes de enviar, completá:                            │  ← header rojo claro
├────────────────────────────────────────────────────────────┤
│  • Título de la iniciativa es requerido                    │
│  • Descripción de la iniciativa es requerida               │
│  • Justificación es requerida                              │
│  • Centro de costo es requerido                            │
└────────────────────────────────────────────────────────────┘
   ↑ Border rojo + fill rojo claro (#FEF2F2)
   Border-radius 8px
```

Alto: **calculado por cantidad de errores** (header 40 + N filas 24 + padding 16).
Width: **fill** del padre.

## Input properties (`pp*`)

| Property | Tipo | Default | Required | Descripción |
|---|---|---|---|---|
| `ppErrores` | Table | `[]` | sí | Tabla de errores con shape `{titulo: text, mensaje: text}`. La pantalla padre la calcula con `Table(If(condicion1, {titulo:..., mensaje:...}, Blank()), ...)` y pasa al componente |
| `ppTema` | Record | (default tema) | sí | Tema visual |
| `ppTituloHeader` | Text | `"Antes de enviar, completá:"` | no | Texto del banner. Si querés cambiar a "Hay errores en este formulario" o "Datos faltantes", usar este input |
| `ppMostrarIconoError` | Boolean | `true` | no | Mostrar ⚠️ al lado del título |

## Output properties (`oo*`)

| Property | Tipo | Disparado cuando... | Descripción |
|---|---|---|---|
| `ooHayErrores` | Boolean | (reactivo) | `true` si `ppErrores` tiene 1+ filas. La pantalla puede usar este output para deshabilitar el botón Submit |
| `ooCantidadErrores` | Number | (reactivo) | `CountRows(Self.ppErrores)` |
| `ooOnSelectError` | Behavior | Click en una fila de error | Output reactivo con el `titulo` del error clickeado. La pantalla puede usar esto para hacer `Set(locFieldFocus, titulo_seleccionado)` y dar focus al campo problemático |

## Power Fx por propiedad clave

### Container principal (visible condicional)

```powerquery
// Visible
Self.ooHayErrores

// Fill
ColorValue("#FEF2F2")   // rojo muy claro

// BorderColor
ColorValue("#FCA5A5")

// BorderThickness
1

// RadiusTopLeft/TopRight/BottomLeft/BottomRight
8

// Width
Parent.Width - 32   // margin lateral

// Height (calculada)
40 + (Self.ooCantidadErrores * 24) + 16   // header + filas + padding
```

### Header bar (40px alto)

```powerquery
// Y
0

// Height
40

// Fill
ColorValue("#FEE2E2")   // ligeramente más oscuro que el body

// Width
Parent.Width

// BorderColor
Color.Transparent  // sin border separador (el body ya tiene su border)
```

### Ícono ⚠️ (visible condicional)

```powerquery
// Visible
Self.ppMostrarIconoError

// Icon
Icon.Warning

// Color
ColorValue("#DC2626")

// X, Y
16, 10

// Width, Height
20, 20
```

### Label del título

```powerquery
// Text
Self.ppTituloHeader & " (" & Self.ooCantidadErrores & ")"

// Color
ColorValue("#7F1D1D")

// X
If(Parent.ppMostrarIconoError, 44, 16)

// Y
10

// Font
Parent.ppTema.FuentePrincipal

// Size
13

// FontWeight
FontWeight.Semibold
```

### Gallery de errores (lista vertical de líneas con bullet)

```powerquery
// Items
Self.ppErrores

// Layout
Layout.Vertical

// X
0

// Y
40   // después del header

// Height
Parent.ooCantidadErrores * 24

// Width
Parent.Width

// TemplateSize
24
```

### Dentro del template del gallery: bullet + mensaje

```powerquery
// Bullet (label con "•")
// Text: "•"
// X: 24
// Y: 4
// Color: ColorValue("#7F1D1D")

// Mensaje (label con el error)
// Text: ThisItem.mensaje
// X: 40
// Y: 4
// Color: ColorValue("#7F1D1D")
// Size: 12
// FontWeight: FontWeight.Normal

// OnSelect (toda la fila)
Parent.ooOnSelectError(ThisItem.titulo)
```

### Outputs reactivos

```powerquery
// ooHayErrores
CountRows(Self.ppErrores) > 0

// ooCantidadErrores
CountRows(Self.ppErrores)
```

## Ejemplo de instanciación

### En M2 Solicitante (form con validaciones)

```powerquery
// En la pantalla, una variable que calcula los errores:
// Set(locErroresValidacion, ...)  o como App.Formulas:

// Definimos una fórmula con name "ErroresValidacionM2" en App.Formulas:
ErroresValidacionM2 =
    Filter(
        Table(
            { titulo: "Titulo", mensaje: "Título de la iniciativa es requerido", valido: !IsBlank(InputTitulo.Text) },
            { titulo: "Descripcion", mensaje: "Descripción de la iniciativa es requerida", valido: !IsBlank(InputDescripcion.Text) },
            { titulo: "Justificacion", mensaje: "Justificación es requerida", valido: !IsBlank(InputJustificacion.Text) },
            { titulo: "Beneficios", mensaje: "Beneficios estratégicos esperados son requeridos", valido: !IsBlank(InputBeneficios.Text) },
            { titulo: "Empresa", mensaje: "Empresa es requerida", valido: !IsBlank(DropdownEmpresa.Selected) },
            { titulo: "CentroCosto", mensaje: "Centro de costo es requerido", valido: !IsBlank(DropdownCentroCosto.Selected) },
            { titulo: "Clasificacion", mensaje: "Al menos una clasificación es requerida", valido: CountRows(ChoicesGroupClasificacion.SelectedItems) > 0 }
        ),
        valido = false   // solo errores
    );

// Después, en el componente:
// cmpINNOVA_ValidationSummary_1.ppErrores = ErroresValidacionM2
// cmpINNOVA_ValidationSummary_1.ppTema = gblTema
// cmpINNOVA_ValidationSummary_1.ppMostrarIconoError = true
// cmpINNOVA_ValidationSummary_1.ooOnSelectError = (
//     Set(locFieldFocus, /* el titulo recibido */)
//     // Si tenés un mapeo titulo→Control, podés:
//     // SetFocus(Switch(locFieldFocus, "Titulo", InputTitulo, "Descripcion", InputDescripcion, ...))
// )

// Y el botón Submit:
// cmpINNOVA_ActionBar_1.ppSubmitDisabled = cmpINNOVA_ValidationSummary_1.ooHayErrores
```

### Para validar lógica más compleja

```powerquery
// Validación condicional (ROI mínimo si hay monto):
Table(
    { titulo: "ROI", mensaje: "Si hay monto estimado, debe haber ahorro estimado para calcular ROI", valido:
        IsBlank(InputMontoEstimado.Value) Or !IsBlank(InputAhorroAnual.Value) }
)

// Validación cross-field (fechas):
Table(
    { titulo: "FechaTerminacion", mensaje: "Fecha de terminación no puede ser anterior a fecha inicio", valido:
        IsBlank(DatePickerInicio.SelectedDate) Or
        IsBlank(DatePickerTerminacion.SelectedDate) Or
        DatePickerTerminacion.SelectedDate >= DatePickerInicio.SelectedDate }
)
```

## Reglas de uso

- **Calcular `ppErrores` reactivamente** — preferir App.Formulas (named formula) sobre setear variable manual, para que el banner se actualice en tiempo real conforme el usuario escribe
- **Solo errores bloqueantes en `ppErrores`** — para warnings/avisos usar otro componente o un Notify; el ValidationSummary es para "no podés submit hasta arreglar esto"
- **Ubicarlo arriba del Submit button** — convención UX: el usuario lee de arriba a abajo, ve los errores, scrollea hacia arriba para arreglar, vuelve y submit
- **El componente NO sabe del Submit** — solo presenta errores; la pantalla decide qué hacer con `ooHayErrores` (deshabilitar Submit, mostrar Notify, etc.)
- **Mensajes en español, claros y accionables** — "Email inválido" es accionable; "Validación falló" no lo es

## Cambios breaking que requerirían V2

- Cambiar shape de `ppErrores` (agregar campos required o cambiar tipos)
- Cambiar `ooOnSelectError` para no recibir el `titulo` clickeado

Cambios no-breaking OK en V1:
- Agregar `ppEstilo` con variantes (success/warning además de error)
- Agregar animación al aparecer/desaparecer
- Agregar input `ppMaxErroresVisibles` con paginación

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Patrón #11 (Validaciones con IsBlank/IsEmpty): [`../power-fx-patterns.md`](../power-fx-patterns.md)
- Patrón #4 (Named formulas / App.Formulas): [`../power-fx-patterns.md`](../power-fx-patterns.md)
- Business Rules sobre `pas_iniciativa`: [`../../architecture/data-model.md`](../../architecture/data-model.md) (sección Reglas de negocio)
