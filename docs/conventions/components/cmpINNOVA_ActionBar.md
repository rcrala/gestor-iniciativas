# cmpINNOVA_ActionBar

> **Tipo**: UI Container (Component)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Barra de botones de acción **fija al pie de la pantalla** con layout consistente (primario verde a la izquierda, secundarios al centro, terciario "Salir" gris a la derecha). Renderiza solo los botones que la pantalla necesita (vía `pp*` booleanos) — el componente esconde los que no aplican.

## Dónde se usa

- **M2 Solicitante**: Enviar / Guardar borrador / Cancelar
- **M3 PMO**: Enviar (a TI o Jefatura) / Guardar / Salir
- **M4 TI**: Enviar (a Jefatura) / Guardar / Salir
- **M5 Jefatura Estimación**: Aprobar / Devolver / Rechazar / Salir
- **M6 PMO Ejecución**: Cerrar Ejecución / Guardar / Salir
- **M7 Jefatura Validación**: Aprobar / Devolver / Rechazar / Salir
- **M8 PMO Cotizaciones**: Marcar Ganadora / Guardar / Salir
- **M9 Gerencia**: Aprobar / Rechazar / Salir
- **M10 Comité**: Aprobar / Rechazar / Salir (con N votos)
- **M11 Administrador**: Guardar / Eliminar / Salir

## Referencia visual del cliente

Todos los mockups del cliente muestran este patrón en la parte inferior de cada pantalla operativa. Ejemplos: [image4.png](../../01-Requeriments/media/image4.png) M2 (Enviar verde + Salir gris), [image7.png](../../01-Requeriments/media/image7.png) M5 (Aprobar verde + Devolver naranja + Rechazar rojo + Salir gris), [image11.png](../../01-Requeriments/media/image11.png) M9 (Aprobar + Rechazar + Salir).

## ASCII wireframe

```
Estado completo (todos los botones visibles):
┌──────────────────────────────────────────────────────────────────────────────┐
│ [ ✓ Aprobar ]  [ ↩ Devolver ]  [ ✗ Rechazar ]  [ 💾 Guardar ]  [ Salir ]    │
└──────────────────────────────────────────────────────────────────────────────┘
   ↑ verde         ↑ naranja      ↑ rojo          ↑ gris claro    ↑ gris oscuro

Estado simplificado (M2 Solicitante):
┌──────────────────────────────────────────────────────────────────────────────┐
│ [ ↗ Enviar ]  [ 💾 Guardar borrador ]                          [ Salir ]    │
└──────────────────────────────────────────────────────────────────────────────┘

Estado minimal (read-only):
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                  [ Salir ]   │
└──────────────────────────────────────────────────────────────────────────────┘
```

Alto: **64 px** fijo. Width: **fill** del padre. Position: **bottom fixed** del screen.

## Input properties (`pp*`)

### Visibilidad de cada botón

| Property | Tipo | Default | Descripción |
|---|---|---|---|
| `ppMostrarSubmit` | Boolean | `false` | Mostrar botón primario "Enviar" / "Submit". Texto custom via `ppTextoSubmit` |
| `ppMostrarAprobar` | Boolean | `false` | Mostrar "Aprobar" (verde) |
| `ppMostrarDevolver` | Boolean | `false` | Mostrar "Devolver" (naranja) |
| `ppMostrarRechazar` | Boolean | `false` | Mostrar "Rechazar" (rojo) |
| `ppMostrarGuardar` | Boolean | `true` | Mostrar "Guardar" / "Guardar borrador" |
| `ppMostrarEliminar` | Boolean | `false` | Mostrar "Eliminar" (rojo, para M11 admin) |
| `ppMostrarSalir` | Boolean | `true` | Mostrar "Salir" (gris) — generalmente siempre true |

### Estado de cada botón

| Property | Tipo | Default | Descripción |
|---|---|---|---|
| `ppSubmitDisabled` | Boolean | `false` | Si true, deshabilita el botón Submit. Útil para conectar con `cmpINNOVA_ValidationSummary.ooHayErrores` |
| `ppAprobarDisabled` | Boolean | `false` | |
| `ppDevolverDisabled` | Boolean | `false` | |
| `ppRechazarDisabled` | Boolean | `false` | |
| `ppGuardarDisabled` | Boolean | `false` | |
| `ppEliminarDisabled` | Boolean | `false` | |
| `ppMostrarSpinner` | Boolean | `false` | Si true, muestra spinner sobre la barra (operación en curso) y deshabilita todos los botones |

### Texto custom de los botones

| Property | Tipo | Default | Descripción |
|---|---|---|---|
| `ppTextoSubmit` | Text | `"Enviar"` | Customizar a "Enviar a PMO", "Enviar a Comité", etc. |
| `ppTextoGuardar` | Text | `"Guardar borrador"` | |
| `ppTextoSalir` | Text | `"Salir"` | |

### Tema

| Property | Tipo | Default | Descripción |
|---|---|---|---|
| `ppTema` | Record | (default tema) | Tema visual |

## Output properties (`oo*`)

| Property | Tipo | Disparado cuando... | Descripción |
|---|---|---|---|
| `ooOnSelectSubmit` | Behavior | Click en "Enviar" / Submit | La pantalla hace SubmitForm / Patch + Navigate |
| `ooOnSelectAprobar` | Behavior | Click en "Aprobar" | La pantalla actualiza `pas_estado` con la transición correspondiente |
| `ooOnSelectDevolver` | Behavior | Click en "Devolver" | Idem |
| `ooOnSelectRechazar` | Behavior | Click en "Rechazar" | Idem |
| `ooOnSelectGuardar` | Behavior | Click en "Guardar" | Patch sin cambio de estado |
| `ooOnSelectEliminar` | Behavior | Click en "Eliminar" | Confirm dialog + Remove (M11 admin only) |
| `ooOnSelectSalir` | Behavior | Click en "Salir" | Si hay cambios pendientes: confirm dialog. Sino: `Back()` o `Navigate(scrInicio)` |

## Power Fx por propiedad clave

### Container barra inferior

```powerquery
// Fill
ColorValue("#FFFFFF")

// Height
64

// Width
Parent.Width

// X, Y
0, Parent.Height - 64   // pegado al pie de la pantalla

// BorderColor
ColorValue("#E2E8F0")

// BorderThickness
1, 0, 0, 0   // solo borde superior
```

### Botón Submit / Aprobar (verde, primario, a la izquierda)

```powerquery
// Visible
Self.ppMostrarSubmit Or Self.ppMostrarAprobar

// Text
If(Self.ppMostrarSubmit, Self.ppTextoSubmit, "Aprobar")

// Fill
If(
    Self.ppMostrarSpinner Or
        (Self.ppMostrarSubmit And Self.ppSubmitDisabled) Or
        (Self.ppMostrarAprobar And Self.ppAprobarDisabled),
    ColorValue("#10B981") & "40",   // verde alpha low (disabled visual)
    ColorValue("#10B981")            // verde fuerte
)

// DisabledColor
Self.Fill

// DisplayMode
If(
    Self.ppMostrarSpinner,
    DisplayMode.Disabled,
    If(Self.ppMostrarSubmit, !Self.ppSubmitDisabled, !Self.ppAprobarDisabled)
)

// Color (texto)
ColorValue("#FFFFFF")

// X, Y
16, 12

// Width, Height
160, 40

// OnSelect
If(
    Self.ppMostrarSubmit,
    Self.ooOnSelectSubmit(),
    Self.ooOnSelectAprobar()
)
```

### Botón Devolver (naranja)

```powerquery
// Visible
Self.ppMostrarDevolver

// Text
"↩ Devolver"

// Fill
ColorValue("#F59E0B")   // naranja

// DisplayMode
If(Self.ppMostrarSpinner Or Self.ppDevolverDisabled, DisplayMode.Disabled, DisplayMode.Edit)

// X (a la derecha del primario, con gap 8)
PrevButtonAprobar.X + PrevButtonAprobar.Width + 8

// Y, Width, Height
12, 130, 40

// OnSelect
Self.ooOnSelectDevolver()
```

### Botón Rechazar (rojo)

```powerquery
// Visible
Self.ppMostrarRechazar

// Text
"✗ Rechazar"

// Fill
ColorValue("#DC2626")   // rojo

// X (a la derecha de Devolver)
PrevButtonDevolver.X + PrevButtonDevolver.Width + 8

// Demás props: similares al patrón
```

### Botón Guardar (gris claro)

```powerquery
// Visible
Self.ppMostrarGuardar

// Text
Self.ppTextoGuardar

// Fill
ColorValue("#F1F5F9")   // gris muy claro

// Color (texto)
ColorValue("#0F172A")   // negro

// BorderColor
ColorValue("#CBD5E1")

// BorderThickness
1

// X (a la derecha del último botón visible o después de un gap más grande)
PrevButtonRechazar.X + PrevButtonRechazar.Width + 24

// OnSelect
Self.ooOnSelectGuardar()
```

### Botón Eliminar (rojo, M11 admin)

```powerquery
// Visible
Self.ppMostrarEliminar

// Similar a Rechazar pero typically al lado de Guardar
```

### Botón Salir (gris, a la derecha)

```powerquery
// Visible
Self.ppMostrarSalir

// Text
Self.ppTextoSalir

// Fill
Color.Transparent

// Color
ColorValue("#64748B")   // gris oscuro

// X (alineado a la derecha del container)
Parent.Width - Self.Width - 16

// Y
12

// Width
100

// Height
40

// OnSelect
Self.ooOnSelectSalir()
```

### Spinner overlay (cuando `ppMostrarSpinner=true`)

```powerquery
// Visible (rectángulo semi-transparente que cubre la barra)
Self.ppMostrarSpinner

// Fill
ColorValue("#FFFFFF") & "C0"   // alpha 75%

// Width
Parent.Width

// Height
64

// Y, X
0, 0

// Spinner control centrado:
// Visible: igual al rectángulo
// X: Parent.Width / 2 - 16
// Y: 16
```

## Ejemplo de instanciación

### M2 Solicitante

```powerquery
// cmpINNOVA_ActionBar_1.ppTema = gblTema
// cmpINNOVA_ActionBar_1.ppMostrarSubmit = true
// cmpINNOVA_ActionBar_1.ppTextoSubmit = "Enviar a PMO"
// cmpINNOVA_ActionBar_1.ppMostrarGuardar = true
// cmpINNOVA_ActionBar_1.ppTextoGuardar = "Guardar borrador"
// cmpINNOVA_ActionBar_1.ppMostrarSalir = true
// cmpINNOVA_ActionBar_1.ppSubmitDisabled = cmpINNOVA_ValidationSummary_1.ooHayErrores
// cmpINNOVA_ActionBar_1.ppMostrarSpinner = locSavingInProgress

// cmpINNOVA_ActionBar_1.ooOnSelectSubmit = (
//     UpdateContext({locSavingInProgress: true});;
//     Patch(pas_iniciativas, Defaults(pas_iniciativas), {
//         pas_titulo: InputTitulo.Text,
//         // ... resto de campos
//         pas_estado: 100000001   // Revisión inicial PMO
//     });;
//     // Persistir colaboradores locales:
//     ForAll(cmpINNOVA_CollaboratorsTable_1.ooColeccionLocal, Patch(pas_colaboradorcostos, Defaults(...), {...}));;
//     UpdateContext({locSavingInProgress: false});;
//     Notify("Iniciativa enviada al PMO", NotificationType.Success);;
//     Navigate(scrInicio, ScreenTransition.Fade)
// )

// cmpINNOVA_ActionBar_1.ooOnSelectGuardar = (
//     Patch(pas_iniciativas, Defaults(pas_iniciativas), {...campos..., pas_estado: 100000000});;  // Borrador
//     Notify("Borrador guardado", NotificationType.Success)
// )

// cmpINNOVA_ActionBar_1.ooOnSelectSalir = (
//     If(
//         locFormularioConCambios,
//         Notify("Tenés cambios sin guardar. Guardá antes de salir.", NotificationType.Warning),
//         Navigate(scrInicio)
//     )
// )
```

### M5 Jefatura Estimación

```powerquery
// cmpINNOVA_ActionBar_2.ppMostrarAprobar = true
// cmpINNOVA_ActionBar_2.ppMostrarDevolver = true
// cmpINNOVA_ActionBar_2.ppMostrarRechazar = true
// cmpINNOVA_ActionBar_2.ppMostrarGuardar = false  // jefatura no "guarda", solo decide
// cmpINNOVA_ActionBar_2.ppDevolverDisabled = IsBlank(InputComentario.Text)   // comentario obligatorio (BR-5)
// cmpINNOVA_ActionBar_2.ppRechazarDisabled = IsBlank(InputComentario.Text)

// cmpINNOVA_ActionBar_2.ooOnSelectAprobar = (
//     Patch(pas_iniciativas, gblIniciativaEnRevision, {
//         pas_decision_jefatura: 1,   // Aprobar
//         pas_estado: 100000004,       // Estimación Aprobada por Jefatura
//         pas_fecha_decision_jefatura: Now()
//     });;
//     Navigate(scrInicio)
// )
// cmpINNOVA_ActionBar_2.ooOnSelectDevolver = (
//     Patch(..., { pas_decision_jefatura: 2, pas_estado: 100000005, pas_decision_jefatura_comentario: InputComentario.Text, ... });;
//     ...
// )
// cmpINNOVA_ActionBar_2.ooOnSelectRechazar = (
//     Patch(..., { pas_decision_jefatura: 3, pas_estado: 100000006, ... });;
//     ...
// )
```

### M9 Gerencia (sin Devolver, solo Aprobar/Rechazar — BR-cliente)

```powerquery
// cmpINNOVA_ActionBar_3.ppMostrarAprobar = true
// cmpINNOVA_ActionBar_3.ppMostrarRechazar = true
// cmpINNOVA_ActionBar_3.ppMostrarDevolver = false   // Gerencia no devuelve, solo aprueba/rechaza
// cmpINNOVA_ActionBar_3.ppMostrarGuardar = false
```

## Reglas de uso

- **Ubicarlo siempre fijo al pie**: `Y = Parent.Height - 64` con Lock
- **Conectar `ppSubmitDisabled` con `cmpINNOVA_ValidationSummary.ooHayErrores`** — patrón consistente en todos los forms
- **Usar `ppMostrarSpinner=true` durante el Patch** — el componente bloquea todos los botones, evita doble-Submit (problema común)
- **Confirmar antes de Eliminar** (M11): no usar `ooOnSelectEliminar` directamente; primero abrir un confirm dialog (`UpdateContext({locShowConfirmDelete: true})`), confirm dispara el Remove real
- **El componente NO valida** — la validación es responsabilidad del padre (vía `cmpINNOVA_ValidationSummary`). Si el padre olvida pasar `ppSubmitDisabled`, el usuario puede submit con form inválido (responsabilidad del maker)

## Cambios breaking que requerirían V2

- Renombrar properties `ooOnSelect*` (apps que las usaban se rompen)
- Cambiar layout (orden de botones) — apps que esperan visual específico fallan en revisión UX
- Eliminar botones (un botón removido = apps que lo invocaban se rompen silenciosamente)

Cambios no-breaking OK en V1:
- Agregar botones nuevos opcionales (ej. `ppMostrarExportar` para M11/M13)
- Mejorar visual (hover states, animaciones)
- Agregar `ppLayoutCompacto` para pantallas mobile/responsive

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Mockups con ActionBar: [`../../01-Requeriments/media/image4.png`](../../01-Requeriments/media/image4.png) (M2), [`image7.png`](../../01-Requeriments/media/image7.png) (M5), [`image11.png`](../../01-Requeriments/media/image11.png) (M9)
- Business Rules (BR-5 comentario obligatorio): [`../../architecture/data-model.md`](../../architecture/data-model.md)
- Máquina de estados (qué transición dispara cada botón): [`../../architecture/estados-iniciativa.md`](../../architecture/estados-iniciativa.md)
- Plugin enforcer de transiciones: [`plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs`](../../../plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs)
