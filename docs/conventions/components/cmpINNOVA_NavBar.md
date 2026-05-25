# cmpINNOVA_NavBar

> **Tipo**: UI Container (Component)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Sidebar vertical fijo a la izquierda con **íconos de navegación a los módulos principales**. Cada ícono lleva al usuario a un screen específico de la app. Resalta el ícono activo (la pantalla actual). Aplica filtrado por rol — un Solicitante no ve íconos de PMO ni Comité.

## Dónde se usa

Toda pantalla M0-M14. Junto con `cmpINNOVA_HeaderRol`, es el segundo componente presente en literalmente todas las pantallas.

## Referencia visual del cliente

Ver cualquier mockup (todos comparten el sidebar): [image2.png](../../01-Requeriments/media/image2.png) (M0 Home), [image3.png](../../01-Requeriments/media/image3.png) (M12 Mis Solicitudes), [image4.png](../../01-Requeriments/media/image4.png) (M2 Solicitante). 8 íconos verticales con etiqueta debajo (Inicio / Solicitudes / Mis solicitudes / Catálogos / Reportes / Dashboard / Configuración).

## ASCII wireframe

```
┌──────┐
│ [▣]  │  ← logo/marca
│ INI  │
├──────┤
│ [🏠] │  ← Inicio (M0)
│Inicio│
├──────┤
│ [📥] │  ← Solicitudes (M3 PMO bandeja, visible solo a PMO/TI/Jefatura)
│Solic.│
├──────┤
│ [📋] │  ← Mis solicitudes (M12, visible a TODOS)
│ Mis  │
├──────┤
│ [📚] │  ← Catálogos (M11 Admin, visible solo a Administrador)
│Catál.│
├──────┤
│ [📊] │  ← Reportes (M13, visible PMO/Admin/Gerencia)
│Repor.│
├──────┤
│ [📈] │  ← Dashboard (M13, visible PMO/Admin/Gerencia)
│Dashb.│
├──────┤
│ [⚙️] │  ← Configuración (visible solo Administrador)
│Conf. │
└──────┘
```

Width: **80 px** fijo. Height: **Parent.Height - Header.Height** (fill vertical bajo el header).

Cada ítem: **icon 24x24** centrado horizontalmente + **label 11px** debajo. Alto del ítem: **64 px**.

## Input properties (`pp*`)

| Property | Tipo | Default | Required | Descripción |
|---|---|---|---|---|
| `ppTema` | Record | `{ColorPrimario: "#1B3A6B", ColorAcento: "#F39C12", FuenteSecundaria: "Segoe UI"}` | sí | Tema visual (mismo Record que `cmpINNOVA_HeaderRol.ppTema`) |
| `ppRolUsuario` | Text | `""` | sí | Rol activo del usuario. Determina qué íconos son visibles. Mismos valores que `cmpINNOVA_HeaderRol.ppRolUsuario` |
| `ppPantallaActiva` | Text | `""` | sí | Nombre del screen actualmente visible. Valores: `"Inicio"`, `"Solicitudes"`, `"MisSolicitudes"`, `"Catalogos"`, `"Reportes"`, `"Dashboard"`, `"Configuracion"`. El componente resalta el ítem cuyo nombre coincide |

## Output properties (`oo*`)

| Property | Tipo | Disparado cuando... | Descripción |
|---|---|---|---|
| `ooOnSelectInicio` | Behavior | Click en ícono Inicio | La pantalla hace `Navigate(scrInicio, ScreenTransition.None)` |
| `ooOnSelectSolicitudes` | Behavior | Click en Solicitudes (PMO bandeja) | `Navigate(scrPmoBandeja, ScreenTransition.None)` |
| `ooOnSelectMisSolicitudes` | Behavior | Click en Mis solicitudes | `Navigate(scrMisSolicitudes, ScreenTransition.None)` |
| `ooOnSelectCatalogos` | Behavior | Click en Catálogos | `Navigate(scrCatalogos, ScreenTransition.None)` |
| `ooOnSelectReportes` | Behavior | Click en Reportes | `Navigate(scrReportes, ScreenTransition.None)` |
| `ooOnSelectDashboard` | Behavior | Click en Dashboard | `Navigate(scrDashboard, ScreenTransition.None)` |
| `ooOnSelectConfiguracion` | Behavior | Click en Configuración | `Navigate(scrConfiguracion, ScreenTransition.None)` |

## Matriz de visibilidad por rol

| Ícono | Solicitante | PMO | TI | Jefatura | Gerencia | Comité | Administrador |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Inicio | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Solicitudes (bandeja) | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Mis solicitudes | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Catálogos | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Reportes | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Dashboard | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Configuración | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

Esta matriz se implementa dentro del componente vía Power Fx en la propiedad `Visible` de cada container de ítem.

## Power Fx por propiedad clave

### Rectángulo de fondo del sidebar
```powerquery
// Fill
ColorValue("#FFFFFF")

// Width
80

// Height
Parent.Height - 64   // 64 = altura del header

// X, Y
0, 64   // empieza debajo del header

// BorderColor
ColorValue("#E0E0E0")

// BorderThickness
0, 0, 1, 0   // borde derecho solamente (para separar del contenido)
```

### Container de cada ítem (ejemplo: "Mis solicitudes")
```powerquery
// Visible (siempre visible — todos los roles lo ven)
true

// Para Catálogos (solo Admin):
// Visible
Self.ppRolUsuario = "Administrador"

// Para Reportes/Dashboard (PMO/Gerencia/Admin):
// Visible
Self.ppRolUsuario in ["PMO", "Gerencia", "Administrador"]

// Fill (resaltado si es el activo)
If(
    Self.ppPantallaActiva = "MisSolicitudes",
    ColorValue(Self.ppTema.ColorAcento) & "20",   // 20 = alpha hex (12.5% opacity)
    Color.Transparent
)

// OnSelect
Self.ooOnSelectMisSolicitudes()
```

### Ícono (Image control dentro del ítem)
```powerquery
// Image
// Usar Power Apps modernos icons. Ejemplo para "Mis solicitudes":
Icon.Document   // o el SVG del set de iconos del cliente

// Color (cambia si es el activo)
If(
    Parent.ppPantallaActiva = "MisSolicitudes",
    ColorValue(Parent.ppTema.ColorAcento),
    ColorValue(Parent.ppTema.ColorPrimario)
)

// Width, Height
24, 24
```

### Label del ítem
```powerquery
// Text
"Mis solic."   // truncado para caber en 80px de ancho. Tooltip muestra completo

// Font
Self.ppTema.FuenteSecundaria

// Size
10

// Align
Align.Center

// Color
If(
    Parent.ppPantallaActiva = "MisSolicitudes",
    ColorValue(Parent.ppTema.ColorAcento),
    ColorValue("#444444")
)
```

## Ejemplo de instanciación

En `scrMisSolicitudes`:
```powerquery
// cmpINNOVA_NavBar_1.ppTema = gblTema
// cmpINNOVA_NavBar_1.ppRolUsuario = gblRolUsuario
// cmpINNOVA_NavBar_1.ppPantallaActiva = "MisSolicitudes"
```

En el control hospedante de la navegación (cualquier control dentro de la pantalla):
```powerquery
// Si querés capturar el click de "Inicio" antes de navegar (para confirm dialog, etc.):
cmpINNOVA_NavBar_1.ooOnSelectInicio =
    If(
        gblFormularioConCambiosPendientes,
        Notify("Tenés cambios sin guardar. Guardá antes de salir.", NotificationType.Warning),
        Navigate(scrInicio, ScreenTransition.None)
    )
```

## Reglas de uso

- **Fijo a la izquierda, debajo del header**: usar `X=0, Y=Header.Height` y Lock
- **Width fijo en 80**: nunca expandir; si necesitás menú expandido (con labels largos), eso es otra UX que va en un componente diferente (no implementado en v1)
- **`ppPantallaActiva` debe estar bien seteada** o ningún ítem se resalta — propenso a olvido. Recomendación: en `App.OnStart` setear `Set(gblPantallaActiva, "Inicio")` y actualizarla en cada `Screen.OnVisible` del screen target
- **No alterar la matriz de visibilidad** sin coordinar con security (la lógica de qué ve cada rol es de negocio, no estética)

## Cambios breaking que requerirían V2

- Agregar/quitar íconos del menú (apps que esperan navegación a `scrX` fallarían si quitamos)
- Cambiar la matriz de visibilidad por rol (cambio de UX significativo, mejor V2)

Cambios no-breaking OK directo en V1:
- Cambiar iconografía (mismo número de íconos, mismo orden, distinto símbolo)
- Mejorar hover/active states visuales
- Agregar tooltip al hacer hover

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Mockups con sidebar visible: [`../../01-Requeriments/media/image2.png`](../../01-Requeriments/media/image2.png) (y todas las demás)
- Security roles definidos: [`../../architecture/security-roles.md`](../../architecture/security-roles.md)
- Patrón #14 (Mostrar/ocultar por rol): [`../power-fx-patterns.md`](../power-fx-patterns.md)
