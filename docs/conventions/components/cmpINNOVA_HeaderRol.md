# cmpINNOVA_HeaderRol

> **Tipo**: UI Container (Component)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Banner superior fijo de la app que muestra **logo INNOVA, nombre del módulo actual, nombre del usuario logueado, rol activo, empresa actual y menú de usuario**. Es el "anclaje" visual constante en todas las pantallas — el usuario sabe en todo momento dónde está y como quién.

## Dónde se usa

Toda pantalla M0-M14 (Inicio, Solicitudes, Mis solicitudes, Catálogos, Reportes, Dashboard, Configuración). Es uno de los 2 componentes (junto con `cmpINNOVA_NavBar`) presentes en literalmente todas las pantallas.

## Referencia visual del cliente

Ver [docs/01-Requeriments/media/image2.png](../../01-Requeriments/media/image2.png) (M0 Home) — el header azul corporativo con logo + buscador + user en derecha es el patrón replicado en todas las demás pantallas (image3 a image14).

## ASCII wireframe

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  [LOGO]  Mis solicitudes                              🔍 [______]  👤 Juan ▼ │
└──────────────────────────────────────────────────────────────────────────────┘
   ↑       ↑                                            ↑          ↑
   logo    ppTituloModulo (variable por pantalla)       buscador   menú usuario
   tema    (fijo el rest)                               opcional   (rol + logout)
```

Alto: **64 px** fijo. Width: **fill horizontal** del Parent.

## Input properties (`pp*`)

| Property | Tipo | Default | Required | Descripción |
|---|---|---|---|---|
| `ppTema` | Record | `{ColorPrimario: "#1B3A6B", ColorAcento: "#F39C12", LogoUrl: "", FuentePrincipal: "Segoe UI"}` | sí | Tema visual leído de `pas_parametro` (ver overview, sección Theme parametrizable) |
| `ppTituloModulo` | Text | `""` | sí | Título que cambia por pantalla. Ejemplos: "Mis solicitudes", "Nueva Solicitud de Iniciativa", "Dashboard de Iniciativas" |
| `ppUsuarioNombre` | Text | `User().FullName` | no | Si no se pasa, lee el FullName del usuario logueado. Override útil para testing |
| `ppRolUsuario` | Text | `""` | sí | Rol activo del usuario. Valores válidos: `"Solicitante"`, `"PMO"`, `"TI"`, `"Jefatura"`, `"Gerencia"`, `"Comite"`, `"Administrador"`. Origen: variable global `gblRolUsuario` calculada en `App.OnStart` |
| `ppEmpresaActual` | Text | `""` | no | Empresa del Solicitante o empresa seleccionada en filtro multi-empresa. Si está vacío no muestra. Origen: `gblEmpresaActual.pas_nombre_corto` |
| `ppMostrarBuscador` | Boolean | `false` | no | Si true, muestra input de búsqueda al centro-derecha. Útil para M12 Tracking y M13 Reportes |
| `ppBuscadorPlaceholder` | Text | `"Buscar..."` | no | Placeholder del buscador cuando está visible |

## Output properties (`oo*`)

| Property | Tipo | Disparado cuando... | Descripción |
|---|---|---|---|
| `ooOnSelectLogo` | Behavior | El usuario hace click en el logo | Típicamente: navegar a M0 Home. La pantalla hospedante hace `Navigate(scrInicio, ScreenTransition.None)` |
| `ooOnSelectUsuario` | Behavior | El usuario hace click en su nombre / menú derecha | Típicamente: abrir popup de menú con "Cerrar sesión", "Cambiar empresa" (si aplica), "Ayuda" |
| `ooTextoBusqueda` | Text | El usuario escribe en el buscador (solo si `ppMostrarBuscador=true`) | Output reactivo: la pantalla hospedante lo lee para filtrar la galería visible |
| `ooOnSubmitBusqueda` | Behavior | El usuario presiona Enter en el buscador | Útil si la búsqueda es costosa y solo se ejecuta al submit (vs filtrado en vivo) |

## Power Fx por propiedad clave

### Rectángulo de fondo del header
```powerquery
// Fill
ColorValue(Self.ppTema.ColorPrimario)

// Height
64

// Width
Parent.Width

// X, Y
0, 0
```

### Logo (Image control)
```powerquery
// Image
If(IsBlank(Self.ppTema.LogoUrl), SampleImage, Self.ppTema.LogoUrl)

// X, Y
16, 12

// Width, Height
120, 40

// OnSelect
Self.ooOnSelectLogo()
```

### Título del módulo (Label)
```powerquery
// Text
Self.ppTituloModulo

// Color
ColorValue("#FFFFFF")

// Font
Self.ppTema.FuentePrincipal

// Size
20

// FontWeight
FontWeight.Semibold

// X
160  // a la derecha del logo, con gap
```

### Container de búsqueda (visible condicional)
```powerquery
// Visible
Self.ppMostrarBuscador

// Children: icono 🔍 + TextInput con placeholder = Self.ppBuscadorPlaceholder
// El TextInput tiene Default = "" y OnChange actualiza la variable global del buscador
```

### Nombre del usuario + chevron (derecha)
```powerquery
// Text
Coalesce(Self.ppUsuarioNombre, User().FullName)

// X
Parent.Width - Self.Width - 16

// OnSelect
Self.ooOnSelectUsuario()
```

### Pill del rol (debajo del nombre del usuario)
```powerquery
// Text
Concatenate(
    Self.ppRolUsuario,
    If(IsBlank(Self.ppEmpresaActual), "", Concatenate(" • ", Self.ppEmpresaActual))
)

// Color
ColorValue("#FFFFFF")

// Size
11

// FontWeight
FontWeight.Light

// Visible
!IsBlank(Self.ppRolUsuario)
```

## Ejemplo de instanciación

En `scrMisSolicitudes.OnVisible`:
```powerquery
// Asegurar que gblRolUsuario y gblEmpresaActual ya están seteadas en App.OnStart
// Set(gblRolUsuario, "Solicitante");; Set(gblEmpresaActual, LookUp(...));;
```

En el screen, el control hospedante:
```powerquery
// cmpINNOVA_HeaderRol_1.ppTema
gblTema

// cmpINNOVA_HeaderRol_1.ppTituloModulo
"Mis solicitudes"

// cmpINNOVA_HeaderRol_1.ppRolUsuario
gblRolUsuario

// cmpINNOVA_HeaderRol_1.ppEmpresaActual
gblEmpresaActual.pas_nombre_corto

// cmpINNOVA_HeaderRol_1.ppMostrarBuscador
true   // M12 sí usa buscador

// cmpINNOVA_HeaderRol_1.ppBuscadorPlaceholder
"Buscar por consecutivo, título o solicitante..."
```

Y en un control reactivo al buscador:
```powerquery
// Items de la gallery filtrada por búsqueda:
Filter(
    pas_iniciativas,
    StartsWith(pas_consecutivo, cmpINNOVA_HeaderRol_1.ooTextoBusqueda)
    Or StartsWith(pas_titulo, cmpINNOVA_HeaderRol_1.ooTextoBusqueda)
)
```

## Reglas de uso

- **Siempre fijo al top**: usar `Y=0` y bloquearlo con Lock en el editor para que ningún maker lo mueva por accidente
- **Width=Parent.Width**: ocupar todo el ancho de la pantalla, no hay diseño "narrow header"
- **Nunca dejar `ppTema` blanco**: si `gblTema` no está seteado en `App.OnStart`, el componente usa el default hardcoded pero se ve genérico (sin logo del cliente)
- **No agregar lógica de negocio**: el componente solo emite outputs; la pantalla decide qué hacer (`ooOnSelectLogo` → la pantalla decide si navega o no)

## Cambios breaking que requerirían V2

- Cambiar tipo de `ppTema` de Record a string (forzaría re-cablear todas las apps)
- Eliminar `ooOnSelectLogo` (apps que esperaban ese behavior fallarían)

Cambios no-breaking OK directo en V1:
- Agregar nuevos `pp*` opcionales con default sensible
- Mejorar visual interno (animaciones, hover states) sin cambiar API
- Agregar nuevos `oo*` que las apps existentes simplemente ignoran

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Mockup cliente: [`../../01-Requeriments/media/image2.png`](../../01-Requeriments/media/image2.png) (y similares en image3-image14, todas comparten este header)
- Theme parametrizable: ver sección "Theme" en el overview
- Patrón #1 (Variable global de usuario y rol): [`../power-fx-patterns.md`](../power-fx-patterns.md)
