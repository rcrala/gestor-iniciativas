# cmpINNOVA_FormSection

> **Tipo**: UI Container (Component)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Contenedor visual con **título + icono + estado de validación + slot para fields**, que agrupa lógicamente un conjunto de controles en un formulario. Renderiza secciones como "Información general", "Información de la iniciativa", "Colaboradores" — el patrón visual repetido en M2/M3/M4/M5/M6/M7/M9/M11.

> **Limitación importante de Power Apps**: los Custom Components NO soportan "slots" verdaderos como en React/Vue. Este componente es un **contenedor visual con título** que el maker ubica detrás de los controles reales del form. Los fields NO viven adentro del componente — el componente provee el "marco" y el maker pone los controles encima alineados visualmente. Workaround pragmático mientras Power Apps añade verdadero slot support.

## Dónde se usa

- **M2 Solicitante**: 3 secciones — "Información general", "Información de la iniciativa", "Colaboradores"
- **M3 PMO**: "Resumen Iniciativa", "Evaluación PMO", "Resumen de Costos"
- **M4 TI**: "Resumen Iniciativa", "Evaluación TI", "Resumen de Costos"
- **M5/M7 Jefatura**: "Resumen Iniciativa", "Colaboradores", "Resumen Costos"
- **M6 PMO Ejecución**: "Resumen Iniciativa", "Documentación de Ejecución", "Tiempo Real Invertido"
- **M9/M10 Gerencia/Comité**: "Resumen Iniciativa", "Resumen Cotización Ganadora"
- **M11 Administrador**: cada catálogo en su sección

## Referencia visual del cliente

[image4.png](../../01-Requeriments/media/image4.png) M2 (3 secciones), [image5.png](../../01-Requeriments/media/image5.png) M3 (2 secciones lado a lado), [image8.png](../../01-Requeriments/media/image8.png) M6 (3 secciones).

## ASCII wireframe

```
┌──────────────────────────────────────────────────────────────┐
│  📋  Información de la iniciativa              [✓ Completa]  │  ← header del componente
├──────────────────────────────────────────────────────────────┤   (40px alto)
│                                                              │
│   ← área "slot" donde el maker ubica los fields manualmente →│
│   (el componente provee solo el border + título; los         │
│   controles del form viven en el screen, posicionados        │
│   encima de este componente con padding 16px interior)       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
   ↑ Border 1px sólido gris claro
   Border-radius 8px
   Background blanco
   Shadow sutil opcional
```

## Input properties (`pp*`)

| Property | Tipo | Default | Required | Descripción |
|---|---|---|---|---|
| `ppTitulo` | Text | `"Sección"` | sí | Título visible arriba a la izquierda. Ej: "Información de la iniciativa" |
| `ppIcono` | Text | `""` | no | Nombre del ícono Power Apps (ej: "DocumentSet", "PersonGroup"). Si vacío, no muestra ícono |
| `ppEstadoValidacion` | Text | `"Pendiente"` | no | Pill mini a la derecha del título. Valores válidos: `"Pendiente"` (gris), `"Completa"` (verde con ✓), `"Error"` (rojo con !), `"Oculta"` (no muestra pill) |
| `ppTema` | Record | (default tema) | sí | Tema visual (mismo Record que otros componentes) |
| `ppAlto` | Number | `200` | sí | Alto en px del container. El maker calcula este alto según cuántos fields va a meter dentro |
| `ppAncho` | Number | `0` | no | Ancho en px. Si 0, usa `Parent.Width - 32` (16px margen cada lado) |
| `ppPadding` | Number | `16` | no | Padding interno donde el maker ubicará los fields. Útil para que el maker calcule offsets |

## Output properties (`oo*`)

| Property | Tipo | Disparado cuando... | Descripción |
|---|---|---|---|
| `ooOnSelectHeader` | Behavior | Click en el título de la sección | Opcional: la pantalla puede usarlo para colapsar/expandir (pero el toggle real lo maneja la pantalla, no el componente — keep it simple) |
| `ooContentTopX` | Number | (siempre disponible) | Output reactivo: la X interior donde el maker debe ubicar el primer field (= X del componente + ppPadding) |
| `ooContentTopY` | Number | (siempre disponible) | Output reactivo: la Y interior donde el maker debe ubicar el primer field (= Y del componente + altura header (40) + ppPadding) |
| `ooContentWidth` | Number | (siempre disponible) | Ancho disponible para fields dentro = ppAncho - 2*ppPadding |

## Power Fx por propiedad clave

### Container principal (rectángulo con border)

```powerquery
// Fill
ColorValue("#FFFFFF")

// BorderColor
ColorValue("#E2E8F0")

// BorderThickness
1

// RadiusTopLeft, TopRight, BottomLeft, BottomRight
8, 8, 8, 8

// Width
If(Self.ppAncho > 0, Self.ppAncho, Parent.Width - 32)

// Height
Self.ppAlto

// DropShadow (si Power Apps version soporta)
DropShadow.Light
```

### Header bar (área superior 40px)

```powerquery
// Fill
ColorValue("#F8FAFC")   // muy clarito

// Height
40

// Y
0

// X
0

// Width
Parent.Width

// BorderColor inferior (separador del header con el body)
ColorValue("#E2E8F0")

// BorderThickness
0, 0, 0, 1   // solo borde inferior
```

### Ícono (Image en header, visible condicional)

```powerquery
// Visible
!IsBlank(Self.ppIcono)

// Image
Switch(
    Self.ppIcono,
    "DocumentSet", Icon.DocumentSet,
    "PersonGroup", Icon.PersonGroup,
    "Money",       Icon.AddDocument,   // sustituir con el ícono real
    "Building",    Icon.Building,
    "Database",    Icon.Database,
    Icon.Document  // default fallback
)

// X, Y
16, 8

// Width, Height
24, 24

// Color
ColorValue(Self.ppTema.ColorPrimario)
```

### Título (label en header)

```powerquery
// Text
Self.ppTitulo

// X
If(IsBlank(Parent.ppIcono), 16, 48)   // si hay ícono, empuja a la derecha

// Y
8

// Font
Self.ppTema.FuentePrincipal

// Size
14

// FontWeight
FontWeight.Semibold

// Color
ColorValue("#1E293B")

// OnSelect
Parent.ooOnSelectHeader()
```

### Pill de estado validación (derecha del header)

```powerquery
// Visible
Self.ppEstadoValidacion <> "Oculta"

// X
Parent.Width - Self.Width - 16

// Y
10

// Width
If(Self.ppEstadoValidacion = "Completa", 90, If(Self.ppEstadoValidacion = "Error", 70, 90))

// Height
20

// Fill (con alpha)
Switch(
    Parent.ppEstadoValidacion,
    "Completa", ColorValue("#10B981") & "20",
    "Error",    ColorValue("#EF4444") & "20",
    "Pendiente", ColorValue("#94A3B8") & "20",
    Color.Transparent
)

// RadiusTop/Bottom Left/Right
10
```

### Texto del pill de estado

```powerquery
// Text
Switch(
    Parent.ppEstadoValidacion,
    "Completa", "✓ Completa",
    "Error",    "! Error",
    "Pendiente", "Pendiente",
    ""
)

// Color (versión oscura del estado)
Switch(
    Parent.ppEstadoValidacion,
    "Completa", ColorValue("#065F46"),
    "Error",    ColorValue("#7F1D1D"),
    "Pendiente", ColorValue("#475569"),
    Color.Transparent
)

// Size
11

// FontWeight
FontWeight.Semibold

// Align
Align.Center
```

### Output properties (helpers para que el maker ubique los fields)

```powerquery
// ooContentTopX (X interior absoluta donde el maker debe empezar a poner controles)
Self.X + Self.ppPadding

// ooContentTopY (Y interior absoluta donde empezar)
Self.Y + 40 + Self.ppPadding

// ooContentWidth (ancho usable para los fields)
Self.Width - 2 * Self.ppPadding
```

## Cómo el maker lo usa en Studio

Como Power Apps no tiene slots verdaderos, el flujo es:

1. **Poner el componente** en la posición + tamaño deseado en la pantalla:
   ```powerquery
   cmpINNOVA_FormSection_1.X = 32
   cmpINNOVA_FormSection_1.Y = 88   // después del header
   cmpINNOVA_FormSection_1.ppAlto = 240
   cmpINNOVA_FormSection_1.ppTitulo = "Información de la iniciativa"
   cmpINNOVA_FormSection_1.ppIcono = "DocumentSet"
   cmpINNOVA_FormSection_1.ppEstadoValidacion = "Pendiente"
   cmpINNOVA_FormSection_1.ppTema = gblTema
   ```

2. **Ubicar los fields del form** usando los outputs como referencia:
   ```powerquery
   // Primer field (Label "Título de la iniciativa"):
   LabelTitulo.X = cmpINNOVA_FormSection_1.ooContentTopX
   LabelTitulo.Y = cmpINNOVA_FormSection_1.ooContentTopY

   // TextInput a la derecha del label:
   InputTitulo.X = cmpINNOVA_FormSection_1.ooContentTopX + 200
   InputTitulo.Y = cmpINNOVA_FormSection_1.ooContentTopY
   InputTitulo.Width = cmpINNOVA_FormSection_1.ooContentWidth - 200
   ```

3. **Calcular dinámicamente el `ppAlto`** según los fields que metés:
   ```powerquery
   // Si tenés 5 fields de 32px cada uno + 16px de gap entre ellos:
   cmpINNOVA_FormSection_1.ppAlto = 40 + 16 + (5 * 32) + (4 * 16) + 16
                                  //  header  pad-top  fields    gaps   pad-bot
                                  // = 280px
   ```

4. **Actualizar el `ppEstadoValidacion`** reactivamente según los valores de los fields:
   ```powerquery
   cmpINNOVA_FormSection_1.ppEstadoValidacion =
       If(
           !IsBlank(InputTitulo.Text) And !IsBlank(InputDescripcion.Text) And !IsBlank(DropdownEmpresa.Selected),
           "Completa",
           "Pendiente"
       )
   ```

## Reglas de uso

- **El maker calcula `ppAlto` manualmente** según cuántos fields va a meter; si subestima, los fields se ven cortados visualmente (aunque siguen funcionando)
- **No anidar `cmpINNOVA_FormSection` dentro de otro**: el patrón es "screen contiene N secciones", no "sección contiene sub-secciones" (overhead visual)
- **`ppTitulo` debe coincidir con el nombre del mockup del cliente**: para que reviewers comparen lado a lado el screen con el mockup
- **Considerar fixed-position layout**: si la pantalla tiene secciones complejas, calcular X/Y absolutos en lugar de containers — Power Apps no tiene Flexbox

## Cambios breaking que requerirían V2

- Cambiar `ppEstadoValidacion` de string a enum/number (forzaría reemplazar literales)
- Mover los `oo*` helpers a otro nombre (apps que los usaban se romperían)
- Cambiar layout interno (alto del header de 40 a otro valor) — afectaría ubicación de los fields que el maker ya ubicó

Cambios no-breaking OK directo en V1:
- Agregar nuevos `pp*` opcionales (ej. `ppColapsable` para abrir/cerrar)
- Mejorar visuales del header (animaciones, hover)
- Soportar más íconos en el switch

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Mockups con secciones: [`../../01-Requeriments/media/image4.png`](../../01-Requeriments/media/image4.png) (M2 con 3 secciones)
- Power Apps Components docs: https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/create-component
