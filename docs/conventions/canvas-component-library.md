# Canvas Component Library — INNOVA

> **Versión**: 1.0 (issue #59 / S1-03)
> **Fecha**: 2026-05-25
> **Estado**: Spec lista para implementación manual en Power Apps Studio
> **Decisores**: Tech Lead, equipo de desarrollo Canvas

## Para qué sirve este documento

Define la **Component Library de INNOVA**: el conjunto de componentes Canvas reusables que se ensamblan en cada pantalla M0-M14 para garantizar:

- **Consistencia visual** — todas las pantallas comparten header, sidebar, badges, botones idénticos
- **Single source of truth** — cambiar el branding (logo, colores) o un comportamiento (validación de rol) se hace en **un solo lugar**
- **Velocidad de construcción** — el maker arma una pantalla nueva arrastrando componentes en lugar de re-implementar UI desde cero
- **Reducción de defectos** — patrones probados (Power Fx validado) en vez de copy-paste con drift

## ⚠️ Limitación importante del repo

`pac canvas pack/unpack` está **deprecado por Microsoft** (2026, ver ADR-pendiente y [docs/00-Migration/](../00-Migration/) si aplica). El reemplazo oficial **Power Platform Git Integration** GA solo soporta Azure DevOps Repos hoy; **GitHub support entra a Preview en jun 2026** (sin fecha GA). Hasta entonces:

- El repo **NO versiona los `.pa.yaml`** de la Component Library como source-of-truth
- **Power Apps Studio es source of truth** para los componentes
- Este documento + los specs en [`components/`](./components/) son los **planos constructivos** que el maker sigue al armar la library en Studio
- Para versionar visualmente cambios, descargar la library con `pac canvas download` y commitear el diff como referencia (read-only)

## Estructura del entregable

```
docs/conventions/
├── canvas-component-library.md          ← este archivo (overview)
└── components/                          ← un md por componente
    ├── cmpINNOVA_HeaderRol.md
    ├── cmpINNOVA_NavBar.md
    ├── cmpINNOVA_StatusBadge.md
    ├── cmpINNOVA_FormSection.md
    ├── cmpINNOVA_CollaboratorsTable.md
    ├── cmpINNOVA_DocumentUploader.md
    ├── cmpINNOVA_ValidationSummary.md
    ├── cmpINNOVA_ActionBar.md
    └── cmpINNOVA_RoleGuard.md
```

Cada spec de componente incluye:
- **Propósito** y dónde se usa
- **Input properties** (tipo + default + descripción)
- **Output properties** (qué emite hacia la pantalla que lo hospeda)
- **ASCII wireframe** del componente
- **Power Fx por propiedad clave** (OnSelect, OnVisible, Items, etc.) copy-paste-ready
- **Ejemplo de instanciación** en una pantalla real

## Naming convention

### Library
- Nombre formal: `INNOVA - Component Library`
- Nombre interno (SchemaName): `INNOVA_ComponentLibrary`
- Solution donde vive: `innova_components` (nuevo, separado de `innova_core` para que las apps que solo importen la library no traigan todo el modelo)

### Componentes individuales
Formato: `cmpINNOVA_<NombrePascalCase>`

- Prefijo `cmp` = es un Component (vs Screen `scr` o Helper `hlp`)
- `INNOVA_` para evitar colisión con componentes de otras solutions Pasquí
- `NombrePascalCase` descriptivo en inglés o nombre técnico claro

Ejemplos válidos:
- ✅ `cmpINNOVA_HeaderRol`
- ✅ `cmpINNOVA_StatusBadge`
- ✅ `cmpINNOVA_CollaboratorsTable`

Ejemplos inválidos:
- ❌ `HeaderRol` (sin prefijo)
- ❌ `cmp_header_rol` (no PascalCase)
- ❌ `cmpHeader` (sin namespace INNOVA)

### Properties de componentes
Formato: `pp<NombrePascalCase>` para input, `oo<NombrePascalCase>` para output.

- `pp` = "parameter property" (input que recibe del padre)
- `oo` = "output" (valor que emite hacia el padre, accessible via `cmpInstance.oo<X>`)

Ejemplos:
- Input: `ppRolUsuario` (string que recibe el rol), `ppMostrarLogo` (boolean)
- Output: `ooOnSelectAprobar` (Behavior emit cuando se aprueba), `ooFilaSeleccionada` (Record output)

## Cómo crear la Component Library en Power Apps Studio

### Pre-requisitos
- Acceso al environment DEV de INNOVA con permiso para crear solutions
- Solution `innova_components` creada (si no existe, crearla primero):
  ```powershell
  pac solution init --publisher-name Pasqui --publisher-prefix pas --outputDirectory .work/innova-components-init
  # Importar el .zip resultante al environment como nueva solution unmanaged "innova_components"
  ```

### Paso a paso

1. **Crear la Component Library**
   - https://make.powerapps.com → **Solutions** → `innova_components` → **New** → **App** → **Component library**
   - Name: `INNOVA - Component Library`
   - Save

2. **Crear cada componente** (repetir 9 veces, una por componente)
   - En la Component Library abierta: panel izquierdo → **Components** → **+ New component**
   - Renombrar al name canónico: `cmpINNOVA_HeaderRol` (etc.)
   - Configurar **Custom properties** (input y output) según la spec del componente en [`components/`](./components/)
   - Diseñar el contenido (controles, layout, Power Fx) siguiendo el wireframe + snippets de la spec
   - **Save** + **Publish to Library**

3. **Re-publicar después de cambios**
   - Cada vez que modifiques un componente: **Save** + **Publish to Library** explícitamente
   - Sin Publish, las apps que consumen la library NO ven el cambio

### Después de armar la library: versionarla (read-only)

Para que el equipo vea los cambios en el repo (aunque no edite YAML manualmente):

```powershell
# Descargar la library actual
pac canvas download --name "INNOVA - Component Library" --extract-to-directory ".work/canvas-download"

# Reemplazar la carpeta versionada (si decidimos versionarla en futuro PR)
# Por ahora la library NO se versiona — solo cuando GitHub Git Integration entre a GA
```

## Cómo importar la Component Library en una app

### En una app nueva

1. Abrir/crear la Canvas App en https://make.powerapps.com
2. Panel izquierdo → **Components** → **Import components**
3. Tab **From another app** → seleccionar **INNOVA - Component Library** → seleccionar componentes a importar (recomendado: importar todos)
4. **Import**

### En una app existente

Mismo proceso. Si la library tiene cambios desde el último import, aparece un banner "There are updates available for the components used in this app" → click **Refresh**.

### Usar un componente en una pantalla

1. En el screen target: panel izquierdo → **Insert** → **Custom** → seleccionar el componente (ej. `cmpINNOVA_HeaderRol`)
2. Configurar las input properties (`pp*`) en el panel derecho de propiedades
3. Para reaccionar a outputs: en cualquier control de la pantalla referenciar `cmpINNOVA_HeaderRol_1.ooOnSelectLogo` (o similar)

## Theme parametrizable (lee de `pas_parametro`)

El branding del cliente (logo, colores corporativos, tipografía) **no se hardcodea** en los componentes. En su lugar:

1. **Seed parámetros de tema** en `pas_parametro` (ver [seed-data.ps1](../../scripts/setup/06-seed-parametros.ps1), claves `BrandColorPrimary`, `BrandColorAccent`, `BrandLogoUrl`, etc.)
2. **En App.OnStart** de cada app que use la library:
   ```powerquery
   Set(gblTema, {
       ColorPrimario: LookUp(pas_parametros, pas_clave = "BrandColorPrimary").pas_valor_texto,
       ColorAcento:   LookUp(pas_parametros, pas_clave = "BrandColorAccent").pas_valor_texto,
       LogoUrl:       LookUp(pas_parametros, pas_clave = "BrandLogoUrl").pas_valor_texto,
       FuentePrincipal: "Segoe UI"
   });;
   ```
3. **En cada componente** que use tema, pasarle el record `gblTema` como input property `ppTema`:
   ```powerquery
   // Ejemplo en una pantalla:
   cmpINNOVA_HeaderRol.ppTema = gblTema
   ```
4. **Dentro del componente**, leer las props del tema:
   ```powerquery
   // Fill del rectángulo header:
   Self.Fill = ColorValue(Self.ppTema.ColorPrimario)
   ```

Para cambiar branding del cliente: editar las filas de `pas_parametro` (vía M11 Admin) → re-abrir las apps → cambio aplica sin tocar código.

## Governance

### Versioning de la library

- La library tiene **una sola versión activa** en DEV
- Cambios breaking (rename de input property, cambio de tipo, eliminar output) requieren:
  - Coordinación con consumidores (todas las apps M2-M14 que ya importaron)
  - Mejor crear `cmpINNOVA_<Nombre>V2` en paralelo y migrar gradualmente, después deprecar V1
- Cambios no-breaking (agregar input opcional, mejorar visual interno) van directo: edit + Publish

### Documentación

- Spec en [`components/<nombre>.md`](./components/) es la fuente de verdad **del contrato** del componente
- Si cambia el contrato (input/output), **primero** se actualiza el md, **después** el componente en Studio
- PR que modifica un componente debe modificar también su spec md (revisión incluye ambos)

### Quién puede modificar la library

- Solo el Tech Lead Canvas y desarrolladores con rol `INNOVA Administrador` en DEV
- Modificaciones en QA o PROD están **prohibidas** — siempre se modifica en DEV y se exporta vía solution

### Patrones técnicos seguidos

Todos los componentes respetan:
- [`docs/conventions/power-fx-style.md`](./power-fx-style.md) — multi-statement `;;`, naming PascalCase, `IfError`, etc.
- [`docs/conventions/power-fx-patterns.md`](./power-fx-patterns.md) — 16 patrones canónicos referenciados donde apliquen
- UI labels en **español** (los componentes que muestran texto al usuario usan español)
- Code (property names, formulas) en **inglés/técnico** según la convención general del proyecto

## Roadmap de la library

| Versión | Scope | Status | Issue |
|---|---|---|---|
| **v1.0** | 9 componentes base (este PR) | En implementación | #59 |
| v1.1 | `cmpINNOVA_KpiCard` (para M0 home + M12 tracking) | Planificado | TBD |
| v1.2 | `cmpINNOVA_TimelineEstados` (para M12 panel lateral) | Planificado | TBD |
| v1.3 | `cmpINNOVA_VoteCommitee` (para M10 Comité) | Planificado | TBD |
| v2.0 | Migración a `.pa.yaml` cuando GitHub Git Integration salga GA | Diferido | TBD |

## Referencias

- Conjunto de componentes individuales: [`components/`](./components/)
- Ensamble en pantalla M2 Solicitante: [`../plan/modulos/m02-pantalla-solicitante-mockup.md`](../plan/modulos/m02-pantalla-solicitante-mockup.md)
- Mockups del cliente (design language): [`../01-Requeriments/media/`](../01-Requeriments/media/)
- Patrones Power Fx: [`./power-fx-patterns.md`](./power-fx-patterns.md)
- Convenciones Power Fx generales: [`./power-fx-style.md`](./power-fx-style.md)
- Modelo de datos (v1.6): [`../architecture/data-model.md`](../architecture/data-model.md)
