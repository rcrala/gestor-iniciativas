# Fixes Pendientes — Component Library v1

> **Contexto**: validación de los 5 componentes implementados en `innova_components` (RoleGuard, StatusBadge, HeaderRol, NavBar, FormSection) hecha el 2026-05-26 a partir del export del solution. Este documento lista los ajustes a aplicar en Power Apps Studio antes de continuar con ValidationSummary y los componentes restantes.

## Resumen ejecutivo

| Componente | Estado | Acción requerida |
|---|---|---|
| cmpINNOVA_RoleGuard | OK | Ninguna |
| cmpINNOVA_HeaderRol | OK | Ninguna |
| cmpINNOVA_StatusBadge | Funcional sin pill shape | Fix #3 |
| cmpINNOVA_NavBar | Iconos no semánticos + chicos | Fix #1 y #2 |
| cmpINNOVA_FormSection | Sin esquinas redondeadas + texto sin estilo | Fix #4 y #5 |

**Total estimado**: 15-20 min en Studio.

## Nota técnica importante

El control clásico `Rectangle@2.3.0` **no expone propiedades** `RadiusTopLeft`, `RadiusTopRight`, `RadiusBottomLeft`, `RadiusBottomRight`. Para esquinas redondeadas hay que usar el control moderno **Container** (Insert → Layout → Container). Esto aplica a Fix #3 y #4.

---

## Fix #1 — cmpINNOVA_NavBar: Remapear iconos

### Problema

La fórmula actual de `IconItem.Icon` usa iconos que no representan semánticamente las pantallas:

```powerquery
Switch(ThisItem.IconoTipo, 1, Icon.Home, 2, Icon.Mail, 3, Icon.AddLibrary, 4, Icon.Airplane, 5, Icon.Bell, 6, Icon.Alarm, 7, Icon.Settings, Icon.Document)
```

- `Icon.Airplane` para "Catálogos" no tiene sentido
- `Icon.Bell` para "Reportes" sugiere notificaciones, no reportes
- `Icon.Alarm` para "Dashboard" sugiere alarmas, no análisis

### Fix

Reemplazar la fórmula `IconItem.Icon` por:

```powerquery
Switch(
    ThisItem.IconoTipo,
    1, Icon.Home,
    2, Icon.Mail,
    3, Icon.Document,
    4, Icon.AddLibrary,
    5, Icon.Bell,
    6, Icon.Alarm,
    7, Icon.Settings,
    Icon.Document
)
```

### Nuevo mapping resultante

| IconoTipo | Pantalla | Icono | Justificación |
|---|---|---|---|
| 1 | Inicio | `Icon.Home` | Casa = inicio |
| 2 | Solicitudes (PMO bandeja) | `Icon.Mail` | Sobre = bandeja entrada |
| 3 | Mis solicitudes | `Icon.Document` | Documento = mis solicitudes |
| 4 | Catálogos | `Icon.AddLibrary` | Library = catálogo de items |
| 5 | Reportes | `Icon.Bell` | (Provisional, ver mejora) |
| 6 | Dashboard | `Icon.Alarm` | (Provisional, ver mejora) |
| 7 | Configuración | `Icon.Settings` | Engranaje = config |

### Mejora opcional (Reportes/Dashboard)

En la formula bar tipear `Icon.` y verificar si existen alguno de estos. Si sí, sustituir:

- `Icon.BarChart` → para **Reportes** (índice 5)
- `Icon.Trending` o `Icon.LineWeight` → para **Dashboard** (índice 6)
- `Icon.GraphCustom` → alternativa para cualquiera de los dos

Si encontrás `Icon.BarChart` y `Icon.Trending`, la fórmula queda:

```powerquery
Switch(
    ThisItem.IconoTipo,
    1, Icon.Home,
    2, Icon.Mail,
    3, Icon.Document,
    4, Icon.AddLibrary,
    5, Icon.BarChart,
    6, Icon.Trending,
    7, Icon.Settings,
    Icon.Document
)
```

### Validación

- Solicitante (rol) ve 2 iconos: Home + Document
- Administrador ve 7 iconos en orden vertical

---

## Fix #2 — cmpINNOVA_NavBar: Ícono muy pequeño

### Problema

`IconItem.Width = 12` hace que el ícono se vea diminuto en un sidebar de 80px.

### Fix

Dentro del template del `GalleryNav`, seleccionar `IconItem` y cambiar:

| Propiedad | Valor actual | Valor nuevo |
|---|---|---|
| `Width` | `12` | `24` |
| `Height` | `24` | `24` (verificar) |

### Validación

El ícono debe ocupar visualmente un cuadrado de 24x24 px centrado horizontalmente en cada celda del gallery.

---

## Fix #3 — cmpINNOVA_StatusBadge: Agregar forma de pill

### Problema

El componente no tiene forma de pill (esquinas redondeadas). El control raíz del componente Canvas no expone `Radius*`. Falta un Container moderno de fondo.

### Fix

1. Abrir el componente `cmpINNOVA_StatusBadge` en Studio.
2. **Insert → Layout → Container** (el "Container" simple, NO "Horizontal/Vertical container").
3. Renombrar el nuevo Container a `CardFondo`.
4. Click derecho sobre `CardFondo` → **Reorder → Send to back** (debe quedar primero en el árbol, antes que `Dot` y `EstadoLabel`).
5. Setear estas propiedades en `CardFondo`:

| Propiedad | Valor |
|---|---|
| `X` | `0` |
| `Y` | `0` |
| `Width` | `Parent.Width` |
| `Height` | `Parent.Height` |
| `Fill` | (copiar la fórmula `With(...)` que está en el componente raíz, ver abajo) |
| `BorderThickness` | `0` |
| `RadiusTopLeft` | `If(Parent.ppCompacto, 12, 16)` |
| `RadiusTopRight` | `If(Parent.ppCompacto, 12, 16)` |
| `RadiusBottomLeft` | `If(Parent.ppCompacto, 12, 16)` |
| `RadiusBottomRight` | `If(Parent.ppCompacto, 12, 16)` |

> Si el Container moderno solo expone `BorderRadius` como propiedad única (sin las 4 separadas), usar: `BorderRadius = If(Parent.ppCompacto, 12, 16)`.

6. La fórmula `Fill` del Container es la misma que ya tenés en el componente raíz:

```powerquery
With(
    {
        cat: Switch(
            Parent.ppValorEstado,
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
        "Inicial",           ColorFade(ColorValue("#94A3B8"), 0.85),
        "Evaluacion",        ColorFade(ColorValue("#3B82F6"), 0.85),
        "Estimacion",        ColorFade(ColorValue("#06B6D4"), 0.85),
        "Cotizacion",        ColorFade(ColorValue("#8B5CF6"), 0.85),
        "Aprobacion",        ColorFade(ColorValue("#6366F1"), 0.85),
        "Comite",            ColorFade(ColorValue("#A855F7"), 0.85),
        "TerminalAprobado",  ColorFade(ColorValue("#16A34A"), 0.85),
        "TerminalRechazo",   ColorFade(ColorValue("#DC2626"), 0.85),
        "TerminalCancelado", ColorFade(ColorValue("#64748B"), 0.85),
        ColorFade(ColorValue("#94A3B8"), 0.85)
    )
)
```

(En la fórmula del Container, cambiar todos los `Self.ppValorEstado` por `Parent.ppValorEstado`.)

7. Después, cambiar el `Fill` del componente raíz a `Color.Transparent` (ya no necesita color, lo da el Container).

### Validación

Probar con `ppValorEstado = 100000014` (Aprobada) y `ppCompacto = false`. Debe verse un pill verde claro con esquinas redondeadas (radio 16), con el dot verde a la izquierda y el texto "Aprobada".

---

## Fix #4 — cmpINNOVA_FormSection: Esquinas redondeadas

### Problema

Los Rectangle clásicos `CardFondo`, `HeaderBar` y `PillFondo` no soportan `Radius*`. El componente se ve con esquinas cuadradas.

### Fix

Reemplazar los 3 Rectangle por Containers modernos.

#### Paso 4.1 — CardFondo

1. Borrar el `CardFondo` Rectangle actual.
2. **Insert → Layout → Container**, renombrar a `CardFondo`.
3. **Reorder → Send to back** (debe ser el primer hijo).
4. Setear:

| Propiedad | Valor |
|---|---|
| `X` | `0` |
| `Y` | `0` |
| `Width` | `Parent.Width` |
| `Height` | `Parent.Height` |
| `Fill` | `ColorValue("#FFFFFF")` |
| `BorderColor` | `ColorValue("#E2E8F0")` |
| `BorderThickness` | `1` |
| `BorderStyle` | `BorderStyle.Solid` |
| `RadiusTopLeft` | `8` |
| `RadiusTopRight` | `8` |
| `RadiusBottomLeft` | `8` |
| `RadiusBottomRight` | `8` |
| `DropShadow` | `DropShadow.None` |

#### Paso 4.2 — HeaderBar

1. Borrar el `HeaderBar` Rectangle actual.
2. **Insert → Layout → Container**, renombrar a `HeaderBar`.
3. Setear:

| Propiedad | Valor |
|---|---|
| `X` | `0` |
| `Y` | `0` |
| `Width` | `Parent.Width` |
| `Height` | `40` |
| `Fill` | `ColorValue("#F8FAFC")` |
| `BorderThickness` | `0` |
| `RadiusTopLeft` | `8` |
| `RadiusTopRight` | `8` |
| `RadiusBottomLeft` | `0` |
| `RadiusBottomRight` | `0` |

#### Paso 4.3 — PillFondo

1. Borrar el `PillFondo` Rectangle actual.
2. **Insert → Layout → Container**, renombrar a `PillFondo`.
3. Setear:

| Propiedad | Valor |
|---|---|
| `X` | `Parent.Width - Self.Width - 16` |
| `Y` | `10` |
| `Width` | `100` |
| `Height` | `20` |
| `Visible` | `Parent.ppEstadoValidacion <> "Oculta"` |
| `Fill` | `Switch(Parent.ppEstadoValidacion, "Completa", ColorFade(ColorValue("#10B981"), 0.85), "Error", ColorFade(ColorValue("#EF4444"), 0.85), "Pendiente", ColorFade(ColorValue("#94A3B8"), 0.85), Color.Transparent)` |
| `BorderThickness` | `0` |
| `RadiusTopLeft` | `10` |
| `RadiusTopRight` | `10` |
| `RadiusBottomLeft` | `10` |
| `RadiusBottomRight` | `10` |

### Validación

- Card blanco con borde gris claro y esquinas redondeadas (radio 8)
- Header gris claro arriba con esquinas superiores redondeadas
- Pill verde/rojo/gris a la derecha del header con esquinas totalmente redondeadas

---

## Fix #5 — cmpINNOVA_FormSection: Estilo del TituloLabel

### Problema

Al `TituloLabel` le faltan propiedades de estilo (Color, FontWeight, VerticalAlign). El título se ve negro y sin peso.

### Fix

Seleccionar `TituloLabel` y agregar/actualizar:

| Propiedad | Valor |
|---|---|
| `Color` | `ColorValue(Parent.ppTema.ColorPrimario)` |
| `FontWeight` | `FontWeight.Semibold` |
| `VerticalAlign` | `VerticalAlign.Middle` |
| `PaddingLeft` | `0` |

### Validación

El título debe verse en azul corporativo (`#1B3A6B`), semi-bold, alineado verticalmente al centro de la barra del header.

---

## Checklist de aplicación

Marcar conforme se complete cada fix.

- [ ] Fix #1 — NavBar: remapear iconos (fórmula `IconItem.Icon`)
- [ ] Fix #1 opcional — Buscar `Icon.BarChart` y `Icon.Trending` para mejorar Reportes/Dashboard
- [ ] Fix #2 — NavBar: cambiar `IconItem.Width` de 12 a 24
- [ ] Fix #3 — StatusBadge: agregar `CardFondo` Container con radius
- [ ] Fix #3 — StatusBadge: cambiar Fill del componente raíz a `Color.Transparent`
- [ ] Fix #4.1 — FormSection: reemplazar `CardFondo` Rectangle por Container
- [ ] Fix #4.2 — FormSection: reemplazar `HeaderBar` Rectangle por Container
- [ ] Fix #4.3 — FormSection: reemplazar `PillFondo` Rectangle por Container
- [ ] Fix #5 — FormSection: completar estilo de `TituloLabel`
- [ ] **Save + Publish** la Component Library tras todos los fixes

## Siguiente paso

Una vez aplicados los fixes y publicada la versión nueva de la librería, continuamos con:

1. `cmpINNOVA_ValidationSummary` (banner de errores)
2. `cmpINNOVA_ActionBar` (botonera Submit/Aprobar/Devolver/Rechazar/Salir)
3. `cmpINNOVA_CollaboratorsTable` (tabla colaboradores con costo)
4. `cmpINNOVA_DocumentUploader` (upload SharePoint vía flow)
5. Crear app `INNOVA - M2 Solicitante` y ensamblar pantalla
