---
name: Canvas Component INNOVA
description: Build, validate, and fix Canvas Components for the INNOVA Component Library in Power Apps Studio (modern UI). Use when implementing components from specs in docs/conventions/components/, when debugging properties/icons/scoping issues, when validating an exported component library, or when assembling apps from the library. Triggers on "implementar cmp", "componente canvas", "component library", "validar lo construido", "Studio no muestra X propiedad", "icono no existe".
---

## Canvas Component INNOVA — Build & Validate

This skill captures the operational knowledge from building the v1 Component Library (`innova_components` solution) and the gotchas of the modern Power Apps Studio UI. Use it whenever the user is implementing or fixing components in this library, or assembling apps that consume them.

The component specs (one Markdown per component) live in `docs/conventions/components/`. The library overview lives in `docs/conventions/canvas-component-library.md`. Specs are the source of truth; the gotchas below tell you how to translate spec → Studio reality.

---

## Naming & shape conventions

- Component name: `cmpINNOVA_<Name>` (PascalCase, no spaces).
- Input properties: `pp<Nombre>` (e.g. `ppValorEstado`, `ppTema`).
- Output properties: `oo<Nombre>` (e.g. `ooPermitido`, `ooHayErrores`).
- Behavior outputs (`ooOnSelect*`): skip in v1; document as limitation in the spec.
- UI labels in Spanish, code identifiers in English when there's a clean translation.
- Default values in YAML appear with `=` prefix: `Default: ="Borrador"`.

---

## Modern Power Apps Studio UI — terminology map

The modern Studio has renamed dialogs. When the user says "agregar input", clarify which:

| What user often says | What it means in modern Studio |
|---|---|
| "agregar un input" | Could mean (a) an Insert → TextInput control, OR (b) a custom property of type Data + Input. ALWAYS clarify. |
| "custom property" | Power Apps component property. Click "+ New custom property" in the component's Properties panel. |
| Property type | Modern dialog has TWO dropdowns: Property type = **Data** / **Function**, Property definition = **Input** / **Output**. For v1 use Data + Input or Data + Output. Skip Function/Behavior. |

When instructing the user, **never say "add an input named ppX"**. Always say: **"Add a custom property named ppX — Property type Data, Property definition Input, Data type X"**.

---

## The Rectangle vs Container limitation (critical)

`Rectangle@2.3.0` (classic shape) **does not expose** `RadiusTopLeft`, `RadiusTopRight`, `RadiusBottomLeft`, `RadiusBottomRight`. It only has Fill, Border, Size.

**For any rounded-corner background** (cards, pills, badges), use the modern **Container** control:

1. Insert → Layout → **Container** (NOT "Horizontal container" / "Vertical container").
2. Use it as a visual rectangle, NOT as a layout parent. Place siblings at the same level, not inside it.
3. Set `BorderColor`, `BorderThickness`, `BorderStyle`, `DropShadow`, and the 4 Radius properties.
4. If only `BorderRadius` (single property) is exposed, use that.

The component root itself does **not** expose Radius properties either. To make a component look like a pill or rounded card:
- Add a Container `CardFondo` as the first child (Send to back).
- Set component root `Fill = Color.Transparent`.
- Let `CardFondo` carry all the visual styling.

---

## Power Fx — workarounds in components

### Hex alpha doesn't work

`ColorValue("#XXXXXX") & "20"` is **invalid Power Fx**. Use `ColorFade(ColorValue("#XXXXXX"), 0.85)` instead (~85% lighter, ~15% opacity equivalent).

### Gallery scoping inside a component

From inside a Gallery template (a control placed inside the Gallery's first cell), `Parent` refers to the **Gallery**, not the component. Trying to reach `Parent.Parent.ppX` or `Self.Parent.ppX` is unreliable for component properties.

**Pattern**: bake all needed values into the Items table at the Gallery level (where `Self.Parent` correctly = the component), then template controls just read `ThisItem.X`:

```powerquery
// Gallery.Items
With(
    {
        rol: Parent.ppRolUsuario,
        colorAcento: Parent.ppTema.ColorAcento,
        fuente: Parent.ppTema.FuentePrincipal
    },
    Filter(
        Table(
            { Pantalla: "Inicio", IconoTipo: 1, EsVisible: true, EsActivo: false, ColorActivo: colorAcento, Fuente: fuente },
            ...
        ),
        EsVisible
    )
)
```

Template controls then use `ThisItem.ColorActivo`, `ThisItem.Fuente`, etc. No Parent traversal needed.

Alternative: `AddColumns(Self.Parent.ppErrores, "color", colorRojo, "fuente", fuente)`.

### Self.Parent works inside Gallery.Items

In the Gallery's `Items` formula itself, `Self` = the Gallery and `Self.Parent` = the component. So `Self.Parent.ppX` works there (just not in template children).

### Default for Table property

Use `Table({key: ""})` (single empty row) as default for a Table input — empty `Table()` is rejected by Studio in some versions.

```powerquery
Default: |-
  =Table({rol: ""})
```

### Default for Record property

```powerquery
Default: |+
  ={
      ColorPrimario: "#1B3A6B",
      ColorAcento: "#F39C12",
      LogoUrl: "",
      FuentePrincipal: "Segoe UI"
  }
```

---

## Icons — verify before suggesting

Modern Power Apps Studio's `Icon.X` enum varies by Studio version. Names that exist in docs/examples may **not exist** in the user's Studio.

**Confirmed-common icons** (safe defaults): `Icon.Home`, `Icon.Mail`, `Icon.Document`, `Icon.AddLibrary`, `Icon.Settings`, `Icon.Add`, `Icon.Cancel`, `Icon.Check`, `Icon.Search`, `Icon.Warning`, `Icon.Information`, `Icon.Bell`, `Icon.Alarm`, `Icon.Airplane`, `Icon.Database`, `Icon.Folder`.

**Often-missing icons**: `Icon.Person`, `Icon.Library`, `Icon.Note`, `Icon.Trending`, `Icon.BarChart`, `Icon.LineWeight`, `Icon.DocumentPDF`, `Icon.OrderedList`, `Icon.BulletedList`.

**Verification strategy**: ask the user to type `Icon.` + first letter in the formula bar and report what autocomplete shows. Then map semantically:
- Home / Dashboard / Reports → Home, BarChart, Trending, GraphCustom
- Inbox / Tray → Mail
- Library / Catalog → AddLibrary, Library, Folder, Database
- List / Documents → Document, OrderedList, BulletedList
- Settings → Settings

If a semantically-correct icon isn't available, prefer a visually-distinct one over a poorly-matched one. Document the substitution.

---

## Validation workflow — export, unpack, inspect

When the user asks "validar lo construido" or "puedes descargar lo hecho":

1. Confirm auth and environment:
   ```bash
   pac auth list
   pac solution list
   ```
2. Export the component library solution:
   ```bash
   mkdir -p exported
   pac solution export --name innova_components --path ./exported/innova_components.zip --overwrite
   ```
3. Unpack:
   ```bash
   mkdir -p exported/innova_components_unpacked
   pac solution unpack --zipfile ./exported/innova_components.zip --folder ./exported/innova_components_unpacked --packagetype Unmanaged
   ```
4. The `.msapp` inside `CanvasApps/` is a ZIP. Extract manually:
   ```bash
   mkdir -p exported/library_contents
   cd exported/library_contents && unzip -o ../innova_components_unpacked/CanvasApps/<name>_DocumentUri.msapp
   ```
5. Read each `Src/Components/cmpINNOVA_*.pa.yaml` and validate against the spec in `docs/conventions/components/`.

**Note**: `pac canvas pack` / `pac canvas unpack` are **deprecated**. Solution export + manual ZIP extraction is the supported flow.

The `.gitignore` should exclude `exported/` (transient artifact).

### Critical caveat: YAML only contains non-default values

**Power Apps Studio does NOT serialize property values that equal the control's default.** If you set `VerticalAlign = VerticalAlign.Middle` on a Label, the property won't appear in the exported YAML at all — because `VerticalAlign.Middle` IS the Label default.

Therefore: **absence of a property in YAML does NOT mean "not set". It means either "not set" OR "set to default".**

When validating fixes:
- **Property visible in YAML with new value** → applied ✓
- **Property visible in YAML with old value** → not applied ✗
- **Property absent from YAML** → ambiguous. Could be unset, or could be intentionally set to default. Ask the user to confirm visually or via the Studio's properties pane before flagging as "not applied".

Known defaults to watch for (won't appear in YAML when intentionally set to these values):
- `Label.VerticalAlign` → `VerticalAlign.Middle`
- `Label.Align` → `Align.Left`
- `Label.Wrap` → `true`
- `Label.FontWeight` → `FontWeight.Normal`
- `Container.BorderStyle` → `BorderStyle.Solid`
- `Container.DropShadow` → `DropShadow.None`
- `Icon.Visible` → `true`
- Component root `Fill` → varies by Studio version; usually NOT `Color.Transparent`, so transparent IS serialized

When grep-validating, prefer searching for **what should be present** (e.g. `ColorValue\(Parent.ppTema`) over **what should be absent**.

---

## Component composition pattern (what to build)

For a visual component (card, banner, badge):

```
cmpINNOVA_X (root)
├── CardFondo            (Container — fill, border, radius)
├── HeaderBar            (Container — top bar, partial radius)
├── IconoSection         (Icon)
├── TituloLabel          (Label)
├── PillFondo            (Container — small rounded shape)
├── PillTexto            (Label on top of PillFondo)
└── ContentArea          (Gallery / inputs / etc.)
```

Root component: `Fill = Color.Transparent`, `Width`/`Height` = sensible defaults.
Children read theme via `Parent.ppTema.ColorPrimario` etc.

For a logic-only helper (no UI), root: `Width = 50, Height = 50, Fill = Color.Transparent`. Output properties carry the result.

---

## Spec → Studio implementation checklist

When the user asks "implementar cmpINNOVA_X":

1. Read `docs/conventions/components/cmpINNOVA_X.md` end-to-end.
2. In the library, "+ New component" → rename to `cmpINNOVA_X`.
3. Set component root: Width, Height, Fill (transparent if Card).
4. Add input properties (`pp*`): for each, use "+ New custom property" with Data + Input + correct Data type + default.
5. Add output properties (`oo*`): Data + Output + formula. **Skip Behavior** in v1.
6. Insert children in order: first `CardFondo` Container (Send to back), then HeaderBar, then content controls.
7. Apply each property from the spec. For radius, use Container (not Rectangle).
8. Test visual: set the inputs to sensible demo values; verify the component renders correctly in isolation.
9. `Ctrl+S` and **Publish** the library.

---

## Common mistakes to flag immediately

| Symptom | Root cause | Fix |
|---|---|---|
| User added "TextInput" when asked for "input ppX" | Terminology ambiguity | Delete TextInput, use "+ New custom property" |
| Icon error "Icon.X not recognized" | Icon doesn't exist in this Studio | Pick from confirmed list or ask user to verify via autocomplete |
| Component has square corners despite Radius=X in spec | Rectangle@2.3.0 doesn't expose Radius | Replace with Container |
| Component visual color is wrong | Component root Fill not set, or Fill on wrong child | Set `Fill = Color.Transparent` on root, use CardFondo for color |
| Inside Gallery template, `Parent.ppX` returns blank | Parent = Gallery, not component | Bake props into Items via With + AddColumns |
| `ColorValue("#XXX") & "20"` formula error | Hex alpha not supported in Power Fx | Use `ColorFade(ColorValue("#XXX"), 0.85)` |
| User reports "esa propiedad no aparece" | Either using classic Rectangle (no Radius) or property is on Advanced tab | Check Advanced tab first; if still missing, swap to Container |
| Property dialog has Type=Data/Function not Input/Output | Modern Studio split into 2 dropdowns | Property type=Data, Property definition=Input/Output |

---

## Documentation outputs

After fixing issues found in validation, create a fix document at `docs/conventions/components/fixes-componentes-vN.md` with:

- Summary table (component → status → action)
- Numbered fixes with: problem statement, exact properties to change (table format), validation step
- Checklist at the bottom for the user to track application

Optionally convert to Word via pandoc:
```powershell
& "C:\Users\<user>\AppData\Local\Pandoc\pandoc.exe" "docs\conventions\components\fixes-componentes-vN.md" -o "docs\conventions\components\fixes-componentes-vN.docx"
```

---

## Build sequence (when starting from scratch)

Order components from simplest to most complex so the user gains confidence and you can validate the workflow before tackling galleries and forms:

1. **cmpINNOVA_RoleGuard** — no UI, pure logic helper. Tests the custom-property workflow.
2. **cmpINNOVA_StatusBadge** — small visual atom with conditional Fill. Tests color formulas.
3. **cmpINNOVA_HeaderRol** — fixed layout with theme record. Tests `ppTema` pattern.
4. **cmpINNOVA_NavBar** — Gallery with conditional visibility. Tests Gallery scoping pattern.
5. **cmpINNOVA_FormSection** — Container with pill validation. Tests Container/radius pattern.
6. **cmpINNOVA_ValidationSummary** — banner with Gallery of errors. Combines patterns 4+5.
7. **cmpINNOVA_ActionBar** — button row with role-aware visibility. Combines patterns 1+3.
8. **cmpINNOVA_CollaboratorsTable** — editable Gallery with dual persisted/local mode.
9. **cmpINNOVA_DocumentUploader** — flow integration + SharePoint upload.

---

## Output format when reporting to the user

- Short, declarative steps numbered by paste-into-Studio order.
- Property values in tables (one row per property). Never paragraph-form a list of properties.
- Power Fx formulas in fenced code blocks with `powerquery` language hint.
- After each component is built, ask the user to confirm "Listo" before moving to the next. Do NOT batch multiple components in one instruction.
- When recovering from an error, acknowledge the ambiguity (don't blame the user), correct the path, and continue.

---

## Constraints

- Never instruct the user to install or update PAC CLI tools without confirmation.
- Never propose `pac canvas pack/unpack` — deprecated.
- Never commit `.msapp`, `exported/`, or unpacked solution sources without an explicit request — these are large binary artifacts.
- Never rename component properties after they're consumed by apps — that's a breaking change requiring V2.
- When in doubt about a Studio behavior, ask the user to verify in their Studio rather than guessing. The Studio UI varies by region, version, and tenant.
