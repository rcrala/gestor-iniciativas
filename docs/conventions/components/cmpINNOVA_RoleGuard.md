# cmpINNOVA_RoleGuard

> **Tipo**: Functional Helper (Component sin UI propia)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Componente **sin UI propia** que evalúa si el usuario actual puede ver/interactuar con un bloque de contenido, basándose en su rol. Emite un Boolean output `ooPermitido` que el maker conecta a la propiedad `Visible` (o `DisplayMode`) de cualquier control de la pantalla.

> **¿Por qué un componente y no Power Fx inline?** Para centralizar la lógica de roles y permitir cambios futuros (ej. agregar un rol nuevo "Auditor") sin tener que buscar y modificar `If(gblRolUsuario = "PMO", ...)` en 50 lugares. Cambias el componente, el componente lo aplica en todas las apps que lo usan.

## Dónde se usa

Cualquier pantalla con campos/secciones que solo ciertos roles deben ver. Ejemplos:

- **M3 PMO Evaluación**: campos de costo/complejidad solo visibles si rol = PMO o Administrador
- **M5 Jefatura**: la sección "Decisión" solo visible si rol = Jefatura o Administrador
- **M9 Gerencia**: similar, los botones de Aprobar/Rechazar solo si Gerencia
- **M11 Administrador**: muchos catálogos donde solo Administrador edita
- **M12 Mis Solicitudes**: filtro "Solo mis solicitudes" siempre visible, pero filtro "Todas las solicitudes" solo para PMO/Admin
- **M13 Reportes/Dashboard**: visible solo a roles autorizados (matriz en `cmpINNOVA_NavBar`)

## Diferencia con `cmpINNOVA_NavBar`

- `cmpINNOVA_NavBar` controla **navegación** entre módulos (qué pantallas ve el usuario en el sidebar)
- `cmpINNOVA_RoleGuard` controla **visibilidad de elementos** **dentro** de una pantalla (qué campos/secciones/botones ve)

Ambos coexisten: el NavBar evita que un Solicitante vaya a M3 PMO, pero si por alguna razón llegara, el RoleGuard previene que vea/edite los campos sensibles.

## Componente sin renderizado visual

Este componente NO dibuja nada en pantalla. Es invisible. Su único output útil es `ooPermitido`. La pantalla padre lo usa así:

```powerquery
// Cualquier control que solo deba ver el PMO:
SomeContainerPMO.Visible = cmpINNOVA_RoleGuard_1.ooPermitido
```

El maker en Studio puede ubicar el componente en cualquier esquina invisible de la pantalla (típicamente `Width=1, Height=1, X=-100`).

## Input properties (`pp*`)

| Property | Tipo | Default | Required | Descripción |
|---|---|---|---|---|
| `ppRolUsuarioActual` | Text | `""` | sí | Rol del usuario actualmente logueado. Origen: variable global `gblRolUsuario` calculada en `App.OnStart` |
| `ppRolesPermitidos` | Table | `[]` | sí | Tabla de roles permitidos. Shape: `Table({rol: "PMO"}, {rol: "Administrador"})`. Si el `ppRolUsuarioActual` está en la tabla → `ooPermitido=true` |
| `ppPolitica` | Text | `"AllowList"` | no | `"AllowList"` (default): permite si está en `ppRolesPermitidos`. `"DenyList"`: bloquea si está. `"AllowAll"`: siempre true (útil para deshabilitar guard temporalmente). `"DenyAll"`: siempre false |

## Output properties (`oo*`)

| Property | Tipo | Reactivo | Descripción |
|---|---|---|---|
| `ooPermitido` | Boolean | sí | `true` si el rol actual está autorizado según la política. La pantalla lo conecta a `Visible` o `DisplayMode` de los controles a proteger |
| `ooRazonBloqueo` | Text | sí | Si `ooPermitido=false`, descripción legible de por qué (útil para mostrar mensaje "Solo accesible a roles PMO, Administrador"). Si `ooPermitido=true`, blank |

## Power Fx por propiedad clave

### Output `ooPermitido`

```powerquery
// Self.ooPermitido
Switch(
    Self.ppPolitica,
    "AllowAll", true,
    "DenyAll", false,
    "AllowList", !IsBlank(Self.ppRolUsuarioActual) And LookUp(Self.ppRolesPermitidos, rol = Self.ppRolUsuarioActual).rol = Self.ppRolUsuarioActual,
    "DenyList", IsBlank(Self.ppRolUsuarioActual) Or IsBlank(LookUp(Self.ppRolesPermitidos, rol = Self.ppRolUsuarioActual).rol),
    false  // política desconocida: por seguridad, denegar
)
```

### Output `ooRazonBloqueo`

```powerquery
// Self.ooRazonBloqueo
If(
    Self.ooPermitido,
    "",
    Switch(
        Self.ppPolitica,
        "AllowList", "Solo accesible a roles: " & Concat(Self.ppRolesPermitidos, rol, ", "),
        "DenyList", "Bloqueado para tu rol: " & Self.ppRolUsuarioActual,
        "DenyAll", "Funcionalidad temporalmente deshabilitada",
        "Acceso no autorizado"
    )
)
```

## Ejemplo de instanciación

### En M3 PMO Evaluación (proteger la sección de "Evaluación PMO" que solo PMO/Admin pueden ver)

```powerquery
// cmpINNOVA_RoleGuard_PMO.ppRolUsuarioActual = gblRolUsuario
// cmpINNOVA_RoleGuard_PMO.ppRolesPermitidos = Table({rol: "PMO"}, {rol: "Administrador"})
// cmpINNOVA_RoleGuard_PMO.ppPolitica = "AllowList"
```

Después, en la pantalla:
```powerquery
// Container de la sección "Evaluación PMO":
ContainerEvaluacionPMO.Visible = cmpINNOVA_RoleGuard_PMO.ooPermitido

// Si querés mostrar mensaje cuando NO está permitido:
LabelAccessDenied.Visible = !cmpINNOVA_RoleGuard_PMO.ooPermitido
LabelAccessDenied.Text = cmpINNOVA_RoleGuard_PMO.ooRazonBloqueo
```

### En M11 Administrador (proteger todo el screen)

Si el screen completo es solo para Admin:
```powerquery
// En OnVisible del screen:
If(
    !cmpINNOVA_RoleGuard_Admin.ooPermitido,
    Notify("Solo accesible a administradores", NotificationType.Error);; Navigate(scrInicio),
    // OK, proceder
    Set(locScreenReady, true)
)

// Y todos los controles del screen:
Container.Visible = cmpINNOVA_RoleGuard_Admin.ooPermitido And locScreenReady
```

### En M5 Jefatura (botones de decisión solo para Jefatura)

```powerquery
// Múltiples RoleGuards en la misma pantalla — uno por cada bloque protegido:

// Guard 1: editar campos de la iniciativa (Jefatura puede leer, no editar)
// cmpINNOVA_RoleGuard_EditIniciativa.ppRolesPermitidos = Table({rol: "Solicitante"}, {rol: "Administrador"})

// Guard 2: decidir aprobación
// cmpINNOVA_RoleGuard_Decidir.ppRolesPermitidos = Table({rol: "Jefatura"}, {rol: "Administrador"})

// Aplicación:
InputDescripcion.DisplayMode = If(cmpINNOVA_RoleGuard_EditIniciativa.ooPermitido, DisplayMode.Edit, DisplayMode.View)
cmpINNOVA_ActionBar_1.ppMostrarAprobar = cmpINNOVA_RoleGuard_Decidir.ooPermitido
```

### En M12 Mis Solicitudes (filtro "Todas las solicitudes" solo PMO/Admin)

```powerquery
// cmpINNOVA_RoleGuard_VerTodas.ppRolesPermitidos = Table({rol: "PMO"}, {rol: "Administrador"})

// Toggle de UI:
ToggleTodasLasSolicitudes.Visible = cmpINNOVA_RoleGuard_VerTodas.ooPermitido

// Y el filtro de la gallery:
GalleryMisSolicitudes.Items =
    If(
        ToggleTodasLasSolicitudes.Visible And ToggleTodasLasSolicitudes.Value,
        // PMO/Admin ven todo
        pas_iniciativas,
        // Resto solo lo suyo
        Filter(pas_iniciativas, pas_solicitante.userid = User().UserId)
    )
```

## Reglas de uso

- **NUNCA poner permisos sensibles solo en este componente** — es UI guard, no security real. Los permisos REALES están en:
  - **Security Roles de Dataverse** (Read/Write/Create/Delete por tabla por rol) — ver [`docs/architecture/security-roles.md`](../../architecture/security-roles.md)
  - **Plugins C#** que validan reglas de negocio (ej. `IniciativaEstadoTransitionPlugin` enforça transiciones permitidas)
  - **Business Rules** y **Flows** que validan al servidor

  Si solo confiás en `cmpINNOVA_RoleGuard`, un usuario con conocimiento técnico puede modificar el `Visible` directamente o llamar a Dataverse API saltándose la UI. El RoleGuard es **UX**, no **seguridad**.

- **Un RoleGuard por bloque protegido**: no reusar un solo guard para varios bloques con políticas distintas. Crear `cmpINNOVA_RoleGuard_X` por cada concern (edit iniciativa, decidir, ver todas, etc.)
- **Naming descriptivo**: `cmpINNOVA_RoleGuard_EditIniciativa` mejor que `cmpINNOVA_RoleGuard_1` (más legible al revisar el screen)
- **Política `"DenyAll"` para feature flags temporales**: útil para esconder una feature en desarrollo sin tener que comentar código:
  ```powerquery
  // cmpINNOVA_RoleGuard_NuevaFeature.ppPolitica = "DenyAll"   // OFF por ahora
  // cmpINNOVA_RoleGuard_NuevaFeature.ppPolitica = "AllowAll"  // ON cuando lista
  ```

## Cambios breaking que requerirían V2

- Cambiar shape de `ppRolesPermitidos` (de Table con field `rol` a otra estructura)
- Eliminar política `AllowAll` o `DenyAll`
- Cambiar el tipo de `ooPermitido` (improbable, pero…)

Cambios no-breaking OK en V1:
- Agregar políticas nuevas (ej. `"RequireAllRoles"` para casos donde el usuario necesita N roles simultáneos)
- Agregar `ppLogarBloqueos` para enviar telemetría cuando un usuario es bloqueado (útil para auditoría)
- Agregar `ppDelegarA` con un user identity para "actúa en nombre de"

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Roles y matriz de permisos: [`../../architecture/security-roles.md`](../../architecture/security-roles.md)
- Patrón #1 (Variable global de usuario y rol): [`../power-fx-patterns.md`](../power-fx-patterns.md)
- Patrón #14 (Mostrar/ocultar por rol): [`../power-fx-patterns.md`](../power-fx-patterns.md)
- Plugin enforcer (transiciones): [`plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs`](../../../plugins/Pasqui.Innova.Plugins/Iniciativa/IniciativaEstadoTransitionPlugin.cs)
