# M2 — Pantalla Solicitante — Mockup ensamblado con Component Library v1

> **Issue**: #59 (S1-03) — relacionado con M2 (issue de módulo original)
> **Versión**: 1.0
> **Estado**: Plano constructivo para implementación manual en Power Apps Studio
> **Modelo de datos referencia**: v1.6 ([`../../architecture/data-model.md`](../../architecture/data-model.md))

## Para qué sirve este documento

Es el **plano constructivo** que muestra cómo se ensamblan los 9 componentes de la [Canvas Component Library v1](../../conventions/canvas-component-library.md) para construir la pantalla M2 Solicitante en Power Apps Studio.

Cuando el maker abra Studio para implementar M2:
1. Tener este documento abierto al lado
2. Tener el [mockup del cliente image4.png](../../01-Requeriments/media/image4.png) abierto en otra pestaña
3. Crear los controles según el wireframe ASCII de abajo + el mockup visual
4. Configurar las input properties (`pp*`) de cada componente según los snippets Power Fx aquí

## Mockup del cliente de referencia

[`docs/01-Requeriments/media/image4.png`](../../01-Requeriments/media/image4.png) — "Nueva Solicitud de Iniciativa"

Layout principal del cliente:
- **Header azul** con logo INNOVA + título "Nueva Solicitud de Iniciativa" + búsqueda + user (derecha)
- **Sidebar de íconos** a la izquierda
- **Body** con 3 bloques verticales:
  1. Información general (Nombre del solicitante, Empresa, Departamento, Numero de solicitud)
  2. Información de la iniciativa (Nombre del patrocinador, Prioridad para negocio, Clasificación)
  3. Tabla dinámica de Colaboradores (Nombre, Puesto, Horas)
- **ActionBar inferior** con Enviar (verde) + Salir (gris)

## Wireframe ASCII ensamblado

```
                     ┌─────────────────────────────────────────────────────────────────────┐
                     │ cmpINNOVA_HeaderRol                                                 │
                     │ [LOGO] Nueva Solicitud de Iniciativa     🔍 [...]  👤 Juan ▼        │
                     └─────────────────────────────────────────────────────────────────────┘
        ┌──┐         ┌─────────────────────────────────────────────────────────────────────┐
        │🏠│         │                                                                     │
        │  │         │ cmpINNOVA_ValidationSummary  (visible solo si ooHayErrores)         │
        │📥│         │ ┌─────────────────────────────────────────────────────────────────┐ │
        │  │         │ │ ⚠️ Antes de enviar, completá: (4)                               │ │
        │📋│  ← Nav  │ │ • Título de la iniciativa es requerido                          │ │
        │  │         │ │ • Descripción es requerida                                      │ │
        │📊│         │ │ • Justificación es requerida                                    │ │
        │  │         │ │ • Al menos una clasificación es requerida                       │ │
        │📈│         │ └─────────────────────────────────────────────────────────────────┘ │
        │  │         │                                                                     │
        │⚙️│         │ ┌────── cmpINNOVA_FormSection (ppTitulo="Información general") ──┐ │
        └──┘         │ │ 📋 Información general                            [Completa]   │ │
                     │ ├─────────────────────────────────────────────────────────────────┤ │
                     │ │ Nombre del solicitante: [Juan Pérez               ] (read-only) │ │
                     │ │ Empresa:                [▼ COA - Empresa A         ]            │ │
                     │ │ Departamento:           [▼ Finanzas (filtrado por empresa)]    │ │
                     │ │ Número de solicitud:    [COA-2026-001] (auto-generado)         │ │
                     │ │ Fecha de solicitud:     [25/05/2026]  (auto)                   │ │
                     │ └─────────────────────────────────────────────────────────────────┘ │
                     │                                                                     │
                     │ ┌─── cmpINNOVA_FormSection (ppTitulo="Información de la iniciativa")│
                     │ │ 📋 Información de la iniciativa                   [Pendiente]   │ │
                     │ ├─────────────────────────────────────────────────────────────────┤ │
                     │ │ Patrocinador:           [▼ Dropdown lookup systemuser]         │ │
                     │ │ Título:                 [______________________________]       │ │
                     │ │ Descripción:            [_________________________________     │ │
                     │ │                          ___________________________________]  │ │
                     │ │ Justificación:          [_______________________________  ←#31 │ │
                     │ │                          (pas_justificacion, Memo)]            │ │
                     │ │ Beneficios estratégicos:[_______________________________  ←#31 │ │
                     │ │                          (pas_beneficios_estrategicos)]        │ │
                     │ │ Prioridad para negocio: [▼ P1 Crítica | P2 Alta | P3 Media]   │ │
                     │ │ Clasificación (multi):  [☑ Regulatoria  ☐ Operativa           │ │
                     │ │                          ☑ Estratégica  ☐ Tecnología]  ←#32   │ │
                     │ │ Centro de costo:        [▼ CC-001 Adminstración]              │ │
                     │ │ ¿Requiere integración?  [☐] (gatilla multi-select sistemas)#31 │ │
                     │ │ [si checked → ] Sistemas: [☑ SAP ☐ Salesforce ☐ Custom]       │ │
                     │ │ Monto estimado:         [₡ ____________]                       │ │
                     │ │ Ahorro anual estimado:  [₡ ____________]                       │ │
                     │ │ ROI %:                  [auto-calc por plugin C#]              │ │
                     │ └─────────────────────────────────────────────────────────────────┘ │
                     │                                                                     │
                     │ ┌─── cmpINNOVA_CollaboratorsTable ───────────────────────────────┐ │
                     │ │ Colaboradores que invierten tiempo en el proceso actual        │ │
                     │ ├─────────────────────────────────────────────────────────────────┤ │
                     │ │ Nombre │ Puesto │ Horas/mes │ Acc │                            │ │
                     │ │ Andrea │ Analis │      20.0 │ 🗑  │                            │ │
                     │ │ Carlos │ Asist. │      10.5 │ 🗑  │                            │ │
                     │ │ [____] │ [____] │ [______]  │ 🗑  │                            │ │
                     │ │                                       [+ Agregar fila]          │ │
                     │ │                                       Total: 30.5 hrs/mes       │ │
                     │ └─────────────────────────────────────────────────────────────────┘ │
                     │                                                                     │
                     │ ┌─── cmpINNOVA_DocumentUploader ─────────────────────────────────┐ │
                     │ │ 📎 Documentos adjuntos                       [+ Subir archivo] │ │
                     │ ├─────────────────────────────────────────────────────────────────┤ │
                     │ │ (sin adjuntos todavía — M2-H3)                                  │ │
                     │ └─────────────────────────────────────────────────────────────────┘ │
                     │                                                                     │
                     ├─────────────────────────────────────────────────────────────────────┤
                     │ cmpINNOVA_ActionBar                                                 │
                     │ [✓ Enviar a PMO] [💾 Guardar borrador]                  [Salir]    │
                     └─────────────────────────────────────────────────────────────────────┘

        cmpINNOVA_NavBar    +    cmpINNOVA_RoleGuard (invisible, valida visibilidad)
```

## Componentes usados y configuración

| # | Componente | Instancia (name en Studio) | Notas |
|---|---|---|---|
| 1 | `cmpINNOVA_HeaderRol` | `cmpINNOVA_HeaderRol_1` | `ppTituloModulo = "Nueva Solicitud de Iniciativa"`, `ppMostrarBuscador = false` |
| 2 | `cmpINNOVA_NavBar` | `cmpINNOVA_NavBar_1` | `ppPantallaActiva = "MisSolicitudes"` (este screen pertenece a la sección Mis Solicitudes) |
| 3 | `cmpINNOVA_ValidationSummary` | `cmpINNOVA_ValidationSummary_1` | `ppErrores = ErroresValidacionM2` (App.Formula) |
| 4 | `cmpINNOVA_FormSection` (x2) | `cmpINNOVA_FormSection_General`, `cmpINNOVA_FormSection_Iniciativa` | `ppTitulo` diferente cada uno, `ppEstadoValidacion` reactivo |
| 5 | `cmpINNOVA_CollaboratorsTable` | `cmpINNOVA_CollaboratorsTable_1` | `ppIniciativaId = If(IsBlank(varIniciativa), Blank(), varIniciativa.pas_iniciativaid)` — modo local antes del primer Save |
| 6 | `cmpINNOVA_DocumentUploader` | `cmpINNOVA_DocumentUploader_1` | Modo local hasta primer Save. M2-H3 |
| 7 | `cmpINNOVA_ActionBar` | `cmpINNOVA_ActionBar_1` | `ppMostrarSubmit + ppMostrarGuardar + ppMostrarSalir = true` |
| 8 | `cmpINNOVA_RoleGuard` | `cmpINNOVA_RoleGuard_Solicitante` | `ppRolesPermitidos = Table({rol:"Solicitante"}, {rol:"Administrador"})` — bloquea edición si no es Solicitante (o Admin) |

> Nota: `cmpINNOVA_StatusBadge` NO se usa en este screen (es para M3-M12 donde se ve la iniciativa en lista o read-only). En M2 al crear, el estado siempre es "Borrador" y se muestra implícitamente sin badge.

## Variables globales necesarias (en `App.OnStart`)

```powerquery
// Tema visual (lee de pas_parametro)
Set(gblTema, {
    ColorPrimario:   LookUp(pas_parametros, pas_clave = "BrandColorPrimary", "#1B3A6B").pas_valor_texto,
    ColorAcento:     LookUp(pas_parametros, pas_clave = "BrandColorAccent",  "#F39C12").pas_valor_texto,
    LogoUrl:         LookUp(pas_parametros, pas_clave = "BrandLogoUrl",      "").pas_valor_texto,
    FuentePrincipal: "Segoe UI"
});;

// Rol del usuario (calculado vía membership en security roles)
// Patrón #1 de docs/conventions/power-fx-patterns.md
Set(gblRolUsuario,
    With(
        { rolesUsuario: Office365Users.UserProfileV2(User().Email).roles },  // o equivalente con Microsoft Graph
        Coalesce(
            If(IsType(rolesUsuario, "INNOVA Administrador"), "Administrador"),
            If(IsType(rolesUsuario, "INNOVA Gerencia"),       "Gerencia"),
            If(IsType(rolesUsuario, "INNOVA PMO"),            "PMO"),
            If(IsType(rolesUsuario, "INNOVA TI"),             "TI"),
            If(IsType(rolesUsuario, "INNOVA Jefatura"),       "Jefatura"),
            If(IsType(rolesUsuario, "INNOVA Comite"),         "Comite"),
            "Solicitante"  // default — todo usuario logueado mínimo es Solicitante
        )
    )
);;

// Empresa actual del usuario (lookup en pas_empresa por su BU)
Set(gblEmpresaActual,
    LookUp(
        pas_empresas,
        pas_business_unit.businessunitid = User().UserId  // ajustar: lookup real al BU del usuario
    )
);;
```

## App.Formulas

Definidas en **App.Formulas** (named formulas) — más performante que variables porque se evalúan reactivamente sin re-trigger manual.

```powerquery
// Errores de validación reactivos (se evalúan cada vez que cualquier field cambia)
ErroresValidacionM2 =
    Filter(
        Table(
            { titulo: "Titulo",         mensaje: "Título de la iniciativa es requerido", valido: !IsBlank(InputTitulo.Text) && Len(InputTitulo.Text) >= 5 },
            { titulo: "Descripcion",    mensaje: "Descripción es requerida (mín 20 caracteres)", valido: !IsBlank(InputDescripcion.Text) && Len(InputDescripcion.Text) >= 20 },
            { titulo: "Justificacion",  mensaje: "Justificación de la iniciativa es requerida", valido: !IsBlank(InputJustificacion.Text) },
            { titulo: "Beneficios",     mensaje: "Beneficios estratégicos esperados son requeridos", valido: !IsBlank(InputBeneficios.Text) },
            { titulo: "Patrocinador",   mensaje: "Patrocinador es requerido", valido: !IsBlank(DropdownPatrocinador.Selected) },
            { titulo: "Empresa",        mensaje: "Empresa es requerida", valido: !IsBlank(DropdownEmpresa.Selected) },
            { titulo: "Departamento",   mensaje: "Departamento es requerido", valido: !IsBlank(DropdownDepartamento.Selected) },
            { titulo: "CentroCosto",    mensaje: "Centro de costo es requerido", valido: !IsBlank(DropdownCentroCosto.Selected) },
            { titulo: "Prioridad",      mensaje: "Prioridad es requerida", valido: !IsBlank(DropdownPrioridad.Selected) },
            { titulo: "Clasificacion",  mensaje: "Al menos una clasificación es requerida", valido: CountRows(ChoicesGroupClasificacion.SelectedItems) > 0 },
            { titulo: "ColaboradoresSinNombre", mensaje: "Hay filas de colaboradores sin nombre — completar o eliminar", valido:
                CountRows(Filter(cmpINNOVA_CollaboratorsTable_1.ooColeccionLocal, IsBlank(pas_nombre_colaborador))) = 0 }
        ),
        valido = false
    );

// Es el form editable o solo lectura (basado en RoleGuard + estado)
PuedeEditarFormulario =
    cmpINNOVA_RoleGuard_Solicitante.ooPermitido
    And (IsBlank(varIniciativaActual) Or varIniciativaActual.pas_estado = 100000000);  // solo Borrador
```

## Snippets clave del Submit

### Botón "Enviar a PMO" (transición Borrador → Revisión inicial PMO)

```powerquery
// cmpINNOVA_ActionBar_1.ooOnSelectSubmit =
UpdateContext({locSavingInProgress: true});;

// 1. Crear o actualizar pas_iniciativa
Set(varIniciativaCreada,
    Patch(
        pas_iniciativas,
        Coalesce(varIniciativaActual, Defaults(pas_iniciativas)),
        {
            pas_titulo: InputTitulo.Text,
            pas_descripcion: InputDescripcion.Text,
            pas_justificacion: InputJustificacion.Text,                  // #31 G4
            pas_beneficios_estrategicos: InputBeneficios.Text,            // #31 G4
            pas_requiere_integracion: ToggleRequiereIntegracion.Value,    // #31 G4
            // pas_costo_actual_proceso: NO se setea aquí — lo setea PMO en M3
            pas_patrocinador: DropdownPatrocinador.Selected,
            pas_solicitante: User(),
            pas_empresa: DropdownEmpresa.Selected,
            pas_centrocosto: DropdownCentroCosto.Selected,
            // pas_departamento: lookup nuevo si lo agregamos al modelo en futuro v1.7
            pas_prioridad: DropdownPrioridad.Selected,
            pas_clasificacion: ChoicesGroupClasificacion.SelectedItems,   // #32 G5 multi-select
            pas_monto_estimado: { Value: Value(InputMontoEstimado.Text), Currency: "CRC" },
            pas_ahorro_anual_estimado: { Value: Value(InputAhorroAnual.Text), Currency: "CRC" },
            // pas_roi_porcentaje: lo calcula IniciativaRoiPlugin (C#)
            // pas_consecutivo: lo asigna IniciativaPreCreatePlugin (C#)
            pas_estado: 100000001,                                        // Revisión inicial PMO
            pas_fecha_solicitud: Now()
        }
    )
);;

// 2. Si hay sistemas seleccionados (requiere_integracion=true), persistir bridge pas_iniciativa_sistema
If(
    ToggleRequiereIntegracion.Value,
    ForAll(
        DropdownMultiSistemas.SelectedItems,
        Patch(
            pas_iniciativa_sistemas,
            Defaults(pas_iniciativa_sistemas),
            {
                pas_nombre: Concatenate(varIniciativaCreada.pas_consecutivo, " - ", ThisRecord.pas_nombre),
                pas_iniciativa: varIniciativaCreada,
                pas_sistema: ThisRecord
            }
        )
    )
);;

// 3. Persistir colaboradores locales (de cmpINNOVA_CollaboratorsTable_1)
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
            pas_iniciativa: varIniciativaCreada,
            pas_activo: true
        }
    )
);;

// 4. Persistir documentos pendientes (de cmpINNOVA_DocumentUploader_1)
ForAll(
    cmpINNOVA_DocumentUploader_1.ooColeccionLocal,
    'INNOVA - Documento Adjunto - Mover a SharePoint'.Run(
        varIniciativaCreada.pas_iniciativaid,
        ThisRecord.nombre,
        ThisRecord.base64Content
    )
);;
// El flow hace Patch en pas_documentoadjs internamente

// 5. Flow de notificación PMO se dispara automáticamente al cambio de estado (INNOVA - Iniciativa Creada - Notificar PMO)

UpdateContext({locSavingInProgress: false});;
Notify($"Iniciativa {varIniciativaCreada.pas_consecutivo} enviada al PMO", NotificationType.Success);;
Navigate(scrInicio, ScreenTransition.Fade)
```

### Botón "Guardar borrador" (sin cambio de estado)

```powerquery
// Similar al Submit pero:
// - pas_estado se queda en 100000000 (Borrador)
// - No persiste colaboradores ni docs si la iniciativa es nueva (porque podrían no estar definitivos)
// - No dispara flow de notificación (porque trigger es transición a 100000001)

Set(varIniciativaActual,
    Patch(pas_iniciativas, Coalesce(varIniciativaActual, Defaults(pas_iniciativas)), {
        ...campos...,
        pas_estado: 100000000   // Borrador
    })
);;
Notify("Borrador guardado", NotificationType.Success)
```

### Botón "Salir"

```powerquery
If(
    locFormularioConCambios,
    // Confirm dialog
    UpdateContext({locShowConfirmSalir: true}),
    // Sin cambios
    Navigate(scrInicio, ScreenTransition.Fade)
)
```

## Reglas y validaciones del modelo a respetar

| Regla | Origen | Implementación |
|---|---|---|
| `pas_consecutivo` único formato `COA-2026-001` | BR-1 + Plugin `IniciativaPreCreatePlugin` | El plugin C# lo asigna en Pre-Create; la pantalla no lo setea. Solo lo muestra en read-only **después** del primer Save |
| `pas_estado` solo Borrador (100000000) en Create | Plugin `IniciativaEstadoTransitionPlugin` | El plugin valida que Create solo permite Borrador. M2 nunca crea con otro estado |
| ROI auto-calculado | Plugin `IniciativaRoiPlugin` | Cuando Patch incluye `pas_monto_estimado` + `pas_ahorro_anual_estimado`, el plugin calcula `pas_roi_porcentaje` |
| Departamento filtrado por Empresa | UX | `DropdownDepartamento.Items = Filter(pas_departamentos, pas_empresa = DropdownEmpresa.Selected && pas_activo = true)` |
| Sistemas filtrados por Empresa | UX | `DropdownMultiSistemas.Items = Filter(pas_sistemas, pas_empresa = DropdownEmpresa.Selected && pas_activo = true)` |
| Multi-clasificación 1-N opciones | Modelo v1.6 #32 | `ChoicesGroupClasificacion` con `MultiSelect=true`. Items: `Choices(pas_iniciativa.pas_clasificacion)` |
| Cierre del form solo si rol = Solicitante o Admin | `cmpINNOVA_RoleGuard_Solicitante` | Configurar `ppRolesPermitidos = Table({rol:"Solicitante"}, {rol:"Administrador"})` |

## Layout numérico (para posicionar en Studio)

Tomando un screen de **1366x768 px** (resolución base recomendada Power Apps):

| Elemento | X | Y | Width | Height |
|---|---|---|---|---|
| `cmpINNOVA_HeaderRol_1` | 0 | 0 | 1366 | 64 |
| `cmpINNOVA_NavBar_1` | 0 | 64 | 80 | 704 |
| Body scrollable container | 96 | 80 | 1254 | 624 |
| `cmpINNOVA_ValidationSummary_1` (dentro de body) | 0 | 0 | 1254 | dinámico |
| `cmpINNOVA_FormSection_General` | 0 | 100 | 1254 | 200 |
| `cmpINNOVA_FormSection_Iniciativa` | 0 | 320 | 1254 | 450 |
| `cmpINNOVA_CollaboratorsTable_1` | 0 | 790 | 1254 | 250 |
| `cmpINNOVA_DocumentUploader_1` | 0 | 1060 | 1254 | 200 |
| `cmpINNOVA_ActionBar_1` | 0 | 704 | 1366 | 64 |
| `cmpINNOVA_RoleGuard_Solicitante` (invisible) | -100 | -100 | 1 | 1 |

> Nota: el body es scrollable (alto 624) y dentro coloca el formulario que es más alto (~1260). Si no scroll, usar un Container con `VerticalAlign.Start` y `Scrollable=true` que envuelve todos los `cmpINNOVA_FormSection`.

## Checklist de implementación (DoD para el maker)

- [ ] Component Library `INNOVA - Component Library` creada en `innova_components` solution con los 9 componentes
- [ ] App `INNOVA - M2 Solicitante` creada en `innova_canvas` solution
- [ ] Importar Component Library en la app (Insert → Custom → From other apps)
- [ ] Crear screen `scrSolicitanteNueva` siguiendo este layout
- [ ] Configurar todas las input properties (`pp*`) según los snippets de cada componente
- [ ] App.OnStart con las 3 variables globales (`gblTema`, `gblRolUsuario`, `gblEmpresaActual`)
- [ ] App.Formulas con `ErroresValidacionM2` y `PuedeEditarFormulario`
- [ ] Probar los 3 escenarios del test plan ([`tests/canvas/m02-solicitante-test-plan.md`](../../tests/canvas/m02-solicitante-test-plan.md)):
  - Crear iniciativa válida → Submit exitoso → estado=Revisión inicial PMO + correo enviado
  - Form con errores → ValidationSummary visible → Submit deshabilitado
  - Guardar borrador → estado=Borrador → re-abrir y editar
- [ ] Demo al Solicitante piloto (criterio de aceptación del módulo M2)

## Referencias

- Component Library overview: [`../../conventions/canvas-component-library.md`](../../conventions/canvas-component-library.md)
- Specs individuales de los 9 componentes: [`../../conventions/components/`](../../conventions/components/)
- Mockup del cliente: [`../../01-Requeriments/media/image4.png`](../../01-Requeriments/media/image4.png)
- Modelo de datos v1.6: [`../../architecture/data-model.md`](../../architecture/data-model.md)
- Plan original M2: [`./m02-pantalla-solicitante.md`](./m02-pantalla-solicitante.md)
- Test plan M2: [`../../../tests/canvas/m02-solicitante-test-plan.md`](../../../tests/canvas/m02-solicitante-test-plan.md)
- Patrones Power Fx canónicos: [`../../conventions/power-fx-patterns.md`](../../conventions/power-fx-patterns.md)
- Plugin auto-consecutivo: [`plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaPreCreatePlugin.cs`](../../../plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaPreCreatePlugin.cs)
- Plugin auto-ROI: [`plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaRoiPlugin.cs`](../../../plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaRoiPlugin.cs)
- Plugin enforcer de transiciones: [`plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs`](../../../plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs)
