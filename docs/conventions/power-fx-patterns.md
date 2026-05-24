# Power Fx — Patrones canónicos de INNOVA

> **Versión**: 1.0 (issue #18, S0-7)
> **Aplica a**: todas las Canvas Apps de M2-M14
> **Relacionado**: [`power-fx-style.md`](power-fx-style.md) define **convenciones generales** (naming, formato, reglas). Este doc tiene **snippets copy-paste-ready** por escenario.

## Cómo usar este doc

Cada patrón tiene:
- **Contexto**: cuándo aplicarlo
- **Snippet correcto**: el código a usar
- **Anti-patrón**: qué evitar y por qué
- **Dónde se usa en INNOVA** (referencias a módulos/issues si aplica)

Si un patrón nuevo aparece y no está aquí, agregarlo (con PR) antes de propagarlo por la app.

---

## 1. Variable global de usuario y rol

**Contexto**: al cargar la app, conocer quién es el usuario y qué rol INNOVA tiene. Define qué pantallas y acciones se muestran.

**Snippet** (en `App.OnStart`):

```powerfx
// Usuario actual via getCurrentUserId del connector Office365Users (no requiere lookup extra)
Set(gblCurrentUser,
    LookUp(Users, 'Primary Email' = User().Email)
);;
// Rol INNOVA: lee del lookup pas_rol o vía Security Role asignado
// Asume que el lookup ya está sembrado o se obtiene del role
Set(gblUserRole,
    // Primer rol que matchea con prefix INNOVA
    First(
        Filter(gblCurrentUser.Roles, StartsWith(Name, "INNOVA "))
    ).Name
);;
Set(gblIsAdmin, gblUserRole = "INNOVA Administrador");;
Set(gblIsPMO,   gblUserRole = "INNOVA PMO")
```

**Anti-patrón**:

```powerfx
// ❌ Acceder al rol cada vez que se necesita (N llamadas innecesarias)
If(First(LookUp(Users, ...).Roles).Name = "INNOVA Administrador", ...)
```

**Dónde**: `App.OnStart` de toda Canvas App (M2-M14). Usar `gblIsXxx` en `Visible` de botones/secciones.

---

## 2. Variable de contexto (local de pantalla)

**Contexto**: estado efímero específico de UNA pantalla (modo de un form, registro seleccionado en una galería). No debe filtrar a otras pantallas.

**Snippet** (en evento de control):

```powerfx
// OnSelect de un botón "Editar"
UpdateContext({
    locFormMode: "edit",
    locSelectedRecord: ThisItem,
    locShowConfirm: false
})
```

Lectura en otros controles de la misma pantalla:

```powerfx
// Visible del botón "Guardar"
locFormMode = "edit"
```

**Anti-patrón**:

```powerfx
// ❌ Usar Set() (global) para algo que solo importa en una pantalla
Set(gblFormMode, "edit")    // Contamina el estado global
```

**Dónde**: pantallas con formularios (M2 Nueva Solicitud, M3 Evaluación PMO, M8 Cotizaciones, M11 Admin).

---

## 3. Collection filtrada

**Contexto**: snapshot inmutable de datos para una galería, con filtros aplicados. Se recalcula al cambiar filtros.

**Snippet** (al cambiar filtro o al cargar pantalla):

```powerfx
// OnVisible de la pantalla M12 Mis Solicitudes
ClearCollect(colIniciativasMias,
    Filter(
        pas_iniciativas,
        pas_solicitante.systemuserid = User().UserPrincipalName And
        pas_estado <> 'Estado (Iniciativa)'.Cancelada
    )
)
```

Refresh tras un cambio:

```powerfx
// OnSelect de botón "Refrescar"
ClearCollect(colIniciativasMias, ...)
```

**Anti-patrón**:

```powerfx
// ❌ Collect (sin Clear) duplica registros en re-ejecución
Collect(colIniciativasMias, Filter(...))

// ❌ Filtrar sobre Dataverse en cada referencia de Items (cada paint = call)
Gallery1.Items = Filter(pas_iniciativas, ...)    // OK para galería simple, MAL si hay LookUps anidados
```

**Dónde**: M12 Mis Solicitudes, M13 Reportería, dashboard.

---

## 4. Named formulas (`App.Formulas`)

**Contexto**: expresiones que se evalúan muchas veces y deben ser consistentes (cálculos derivados, formato, lookup repetido).

**Snippet** (en `App.Formulas`):

```powerfx
// Parámetros leídos una sola vez, accesibles en toda la app
parametros = pas_parametros;

UmbralComite =
    Value(LookUp(parametros, pas_clave = "UmbralEscalamientoComite_USD").pas_valor_numero);

ColorPrimario =
    LookUp(parametros, pas_clave = "BrandingPrimaryColor").pas_valor_texto;

EsMiembroComite =
    !IsBlank(
        LookUp(pas_miembrocomites,
            pas_titular.systemuserid = User().UserPrincipalName And
            pas_activo = true
        )
    );

FormatoFechaCR(d: DateTime): Text =
    Text(d, "[$-es-CR]dd/mm/yyyy hh:mm");
```

**Anti-patrón**:

```powerfx
// ❌ Repetir el lookup en cada control
Label1.Text = LookUp(parametros, pas_clave = "BrandingPrimaryColor").pas_valor_texto
Label2.Text = LookUp(parametros, pas_clave = "BrandingPrimaryColor").pas_valor_texto

// ❌ Set() en OnStart para algo que se calcula fácil
Set(gblColorPrimario, LookUp(...))    // OK pero ocupa memoria; named formula es lazy
```

**Dónde**: toda la app — define `App.Formulas` antes de empezar pantallas.

---

## 5. `Patch()` con `Defaults(table)` (NUNCA `Collect()` a Dataverse)

**Contexto**: crear o actualizar un registro Dataverse. Es la única forma soportada para tablas.

**Snippet crear**:

```powerfx
// Crear iniciativa al presionar "Guardar como borrador"
Set(varNuevaIniciativa,
    Patch(
        pas_iniciativas,
        Defaults(pas_iniciativas),    // Empieza con valores default
        {
            pas_titulo: txtTitulo.Text,
            pas_descripcion: txtDescripcion.Text,
            pas_empresa: drpEmpresa.Selected,
            pas_estado: 'Estado (Iniciativa)'.Borrador,
            pas_es_multi_empresa: tglMultiEmpresa.Value,
            pas_monto_estimado: { Value: Value(txtMonto.Text), Currency: "CRC" }
        }
    )
);;
If(IsError(varNuevaIniciativa),
    Notify("Error al crear: " & FirstError.Message, NotificationType.Error),
    Notify("Iniciativa creada: " & varNuevaIniciativa.pas_consecutivo, NotificationType.Success)
)
```

**Snippet actualizar**:

```powerfx
// Actualizar un registro existente
Patch(
    pas_iniciativas,
    locSelectedRecord,    // El registro completo, no solo el id
    {
        pas_estado: 'Estado (Iniciativa)'.'Revisión inicial PMO',
        pas_fecha_solicitud: Now()
    }
)
```

**Anti-patrón**:

```powerfx
// ❌ Collect contra Dataverse no funciona (es local-only)
Collect(pas_iniciativas, { pas_titulo: "X" })    // No persiste

// ❌ Patch sin Defaults pierde valores requeridos del sistema
Patch(pas_iniciativas, {}, { pas_titulo: "X" })   // Falla por validaciones

// ❌ Hardcodear el GUID del id en lugar de pasar el record completo
Patch(pas_iniciativas, { pas_iniciativaid: "xxx" }, { ... })   // Frágil
```

**Dónde**: M2 (Patch al guardar/enviar), M3-M11 (Patch en cada transición de estado).

---

## 6. Manejo de errores con `IfError()`

**Contexto**: cualquier operación que pueda fallar (Patch, Connector call, navegación). Sin manejo, el usuario ve un toast genérico de Power Apps.

**Snippet**:

```powerfx
// Manejo explícito de error en Patch
IfError(
    // Operación
    Patch(pas_iniciativas, Defaults(pas_iniciativas), { ... }),
    // Handler
    Notify(
        "No se pudo guardar: " & FirstError.Message,
        NotificationType.Error
    );;
    Trace("Patch failed in M2 Save: " & FirstError.Message, TraceSeverity.Error)
)
```

Patrón compuesto (validar + intentar + notificar):

```powerfx
// OnSelect del botón Enviar
If(IsBlank(txtTitulo.Text),
    Notify("El título es requerido", NotificationType.Warning),

    IfError(
        Patch(pas_iniciativas, locSelectedRecord, { pas_estado: 'Estado (Iniciativa)'.'Revisión inicial PMO' });;
        Navigate(scrConfirmacion, ScreenTransition.Fade),

        Notify("Error: " & FirstError.Message, NotificationType.Error)
    )
)
```

**Anti-patrón**:

```powerfx
// ❌ Asumir que el Patch siempre funciona
Patch(pas_iniciativas, ...);;
Navigate(scrSiguiente)    // Si Patch falla, navega igual con datos inconsistentes
```

**Dónde**: toda operación de escritura, cada submit de form.

---

## 7. Navegación entre pantallas

**Contexto**: moverse entre pantallas pasando contexto (registro seleccionado, modo).

**Snippet**:

```powerfx
// Ir a detalle pasando el registro
Navigate(
    scrIniciativaDetalle,
    ScreenTransition.Fade,
    {
        ctxIniciativa: ThisItem,
        ctxModoLectura: gblUserRole <> "INNOVA Solicitante" And ThisItem.pas_estado <> 'Estado (Iniciativa)'.Borrador
    }
)
```

En la pantalla destino:

```powerfx
// scrIniciativaDetalle.OnVisible
UpdateContext({
    locIniciativa: ctxIniciativa,
    locReadonly: ctxModoLectura
})
```

Regresar:

```powerfx
Back()    // Vuelve a la pantalla anterior
// O específicamente:
Navigate(scrInicio, ScreenTransition.Fade)
```

**Anti-patrón**:

```powerfx
// ❌ Variables globales para pasar contexto puntual
Set(gblIniciativaActual, ThisItem);;
Navigate(scrIniciativaDetalle)    // Contamina el estado global, sobrevive después de la navegación
```

**Dónde**: M2 → M12 (después de crear), M12 → detalle iniciativa, M3/M5/M9/M10 desde tracking.

---

## 8. Formato de fecha CR (es-CR)

**Contexto**: mostrar fechas en formato local Costa Rica (dd/mm/yyyy) y manejar zona horaria UTC vs local correctamente.

**Snippet**:

```powerfx
// Mostrar fecha + hora
Text(ThisItem.pas_fecha_solicitud, "[$-es-CR]dd/mm/yyyy hh:mm")

// Solo fecha
Text(ThisItem.pas_fecha_cotizacion, "[$-es-CR]dd/mm/yyyy")

// Como named formula reutilizable
// (definida en App.Formulas, ver patrón 4)
FormatoFechaCR(ThisItem.pas_fecha_solicitud)
```

**Conversión UTC → local para display**:

```powerfx
// Dataverse guarda en UTC; convertir a hora local CR (-6 sin DST) para mostrar
DateAdd(ThisItem.createdon, -6, TimeUnit.Hours)
```

Mejor: configurar el behavior de la columna como `UserLocal` en Dataverse (ya lo hicimos en S0-4) — Power Apps lo convierte automáticamente.

**Anti-patrón**:

```powerfx
// ❌ Formato hardcoded sin locale (puede salir en inglés según browser)
Text(ThisItem.pas_fecha_solicitud, "dd/mm/yyyy")

// ❌ Hacer aritmética de timezone manual cuando el behavior de la columna ya lo maneja
DateAdd(d, -6, TimeUnit.Hours)    // Doble offset si la columna ya es UserLocal
```

**Dónde**: galerías de Mis Solicitudes (M12), Tracking, Reportería (M13).

---

## 9. Filtros delegables vs no-delegables

**Contexto**: Power Apps tiene un límite de 2000 registros cuando el filtro NO se puede traducir a query de Dataverse. Filtros delegables se ejecutan server-side (sin límite real).

**Snippet delegable** (recomendado):

```powerfx
// ✅ Filter con operadores simples sobre columnas indexadas → DELEGABLE
Filter(pas_iniciativas,
    pas_solicitante.systemuserid = User().UserPrincipalName And
    pas_estado = 'Estado (Iniciativa)'.Borrador
)

// ✅ StartsWith en columna Text → DELEGABLE
Filter(pas_iniciativas, StartsWith(pas_titulo, txtBusqueda.Text))

// ✅ Comparación con valor literal → DELEGABLE
Filter(pas_iniciativas, pas_monto_estimado > 1000000)
```

**Anti-patrón no-delegable**:

```powerfx
// ❌ Funciones que NO delegan en Dataverse
Filter(pas_iniciativas,
    Year(pas_fecha_solicitud) = 2026    // Year() no delega
)

Filter(pas_iniciativas,
    Mid(pas_titulo, 5, 3) = "ABC"        // Mid() no delega
)

Filter(pas_iniciativas,
    pas_titulo in ["A", "B", "C"]        // in con lista no delega
)
```

**Solución cuando necesitas no-delegables**:

```powerfx
// 1) Filtra primero con delegable + LIMITA con un Top
// 2) Después aplica el no-delegable en memoria
ClearCollect(colCandidatos,
    FirstN(
        Filter(pas_iniciativas, pas_anio = 2026),   // delegable
        500                                          // tope explícito
    )
);;
ClearCollect(colFinal,
    Filter(colCandidatos, Mid(pas_titulo, 5, 3) = "ABC")    // sobre collection local
)
```

**Cómo detectar**: Power Apps Studio marca con **icono azul/amarillo** las funciones no-delegables. Revisar siempre.

**Dónde**: TODA pantalla con galería sobre `pas_iniciativas` (puede crecer >2000).

---

## 10. Multi-statement con `;;`

**Contexto**: ejecutar varios statements en un mismo `OnSelect` / `OnVisible` / etc.

**Snippet**:

```powerfx
UpdateContext({ locLoading: true });;
ClearCollect(colDatos,
    Filter(pas_iniciativas, pas_solicitante = User().UserPrincipalName)
);;
UpdateContext({ locLoading: false });;
If(IsEmpty(colDatos),
    Notify("No tienes iniciativas", NotificationType.Information)
)
```

**Anti-patrón**:

```powerfx
// ❌ Power Fx NO acepta ; como separator (es de OTROS lenguajes)
UpdateContext({locLoading: true});
ClearCollect(colDatos, ...);    // Syntax error

// ❌ Anidar todo en un solo If gigante
If(true,
    UpdateContext({locLoading: true}),
    ClearCollect(colDatos, ...),
    UpdateContext({locLoading: false})    // Power Fx no encadena así
)
```

**Regla cultural** (de `power-fx-style.md`): salto de línea **después** de cada `;;` para legibilidad.

---

## 11. Validaciones con `IsBlank()` e `IsEmpty()`

**Contexto**: `IsBlank()` para valores individuales (string, lookup, número); `IsEmpty()` para colecciones/tablas.

**Snippet**:

```powerfx
// Antes de acceder a un campo de un lookup que puede ser null
If(!IsBlank(ThisItem.pas_patrocinador),
    ThisItem.pas_patrocinador.'Full Name',
    "(sin patrocinador)"
)

// Validar campos requeridos en submit
If(
    IsBlank(txtTitulo.Text) Or
    IsBlank(txtDescripcion.Text) Or
    IsBlank(drpEmpresa.Selected) Or
    txtMonto.Text = "" Or
    Value(txtMonto.Text) <= 0,

    Notify("Hay campos requeridos sin llenar", NotificationType.Warning),

    // Submit aquí
    Patch(pas_iniciativas, ...)
)

// IsEmpty para galería vacía
If(IsEmpty(colIniciativasMias),
    Visible: false
)
```

**Diferencia clave**:

```powerfx
IsBlank("")       // true
IsBlank(Blank())  // true
IsEmpty("")       // ERROR - "" no es tabla
IsEmpty([])       // true
IsEmpty(Filter(t, false))  // true si no matchea
```

**Anti-patrón**:

```powerfx
// ❌ Acceder sin validar (puede causar error)
Label1.Text = ThisItem.pas_patrocinador.'Full Name'   // si patrocinador es Blank, falla

// ❌ Usar = "" en lugar de IsBlank() (no detecta Blank() puro)
If(txtTitulo.Text = "", ...)   // Frágil con valores Blank vs ""
```

**Dónde**: toda validación de form, todo display de lookup opcional.

---

## Patrones adicionales útiles en INNOVA

### 12. Lookup de parámetro tipado (Money, Number, Boolean)

```powerfx
// Texto
LookUp(pas_parametros, pas_clave = "BrandingPrimaryColor").pas_valor_texto

// Número (Value() convierte el Decimal a number para comparaciones)
Value(LookUp(pas_parametros, pas_clave = "DiasRecordatorio").pas_valor_numero)

// Booleano
LookUp(pas_parametros, pas_clave = "MultiEmpresaEscalaComite").pas_valor_booleano
```

Mejor envolverlos en named formulas (patrón 4) para evitar el lookup repetido.

### 13. Filtro encadenado con relación N:1 (departamento filtrado por empresa)

```powerfx
// Items del dropdown de departamentos en M2
Filter(
    pas_departamentos,
    pas_empresa.pas_empresaid = drpEmpresa.Selected.pas_empresaid And
    pas_activo = true
)
```

Reset del dropdown hijo al cambiar el padre:

```powerfx
// drpEmpresa.OnChange
Reset(drpDepartamento)
```

### 14. Mostrar/ocultar por rol (sin RBAC violado)

```powerfx
// Visible de un botón "Editar" solo para Solicitante y solo si está en Borrador
gblUserRole = "INNOVA Solicitante" And
locIniciativa.pas_estado = 'Estado (Iniciativa)'.Borrador

// Importante: la seguridad REAL está en Security Roles + Business Rules.
// Esto solo es UX (esconder lo que no aplica). Nunca confiar en Visible para seguridad.
```

### 15. Patch a tabla puente N:M (`pas_iniciativa_sistema`)

```powerfx
// Asociar N sistemas a una iniciativa
ForAll(
    drpSistemas.SelectedItems,    // Multi-select control
    Patch(
        pas_iniciativa_sistemas,
        Defaults(pas_iniciativa_sistemas),
        {
            pas_iniciativa: locIniciativa,
            pas_sistema: ThisRecord,
            pas_nombre: locIniciativa.pas_consecutivo & " - " & ThisRecord.pas_nombre
        }
    )
)
```

Quitar uno:

```powerfx
Remove(pas_iniciativa_sistemas,
    LookUp(pas_iniciativa_sistemas,
        pas_iniciativa = locIniciativa And
        pas_sistema = recASistemaQuitar
    )
)
```

### 16. Tema visual desde `pas_parametro`

```powerfx
// App.Formulas
TemaPrimario = LookUp(pas_parametros, pas_clave = "BrandingPrimaryColor").pas_valor_texto;
TemaSecundario = LookUp(pas_parametros, pas_clave = "BrandingSecondaryColor").pas_valor_texto;

// Uso en un Button.Fill
ColorValue(TemaPrimario)
```

Permite que el cliente cambie branding vía M11 sin redeploy.

---

## Cuándo NO usar Power Fx (escalar a flow o plugin)

| Necesidad | Mejor herramienta |
|---|---|
| Cálculo que debe disparar al crear/editar registro independiente de UI | **Power Automate flow** (trigger `When row is added/modified`) |
| Generar consecutivo con lock anti-race | **Power Automate flow con Concurrency=1** (ver [`numeracion-consecutivos.md`](../architecture/numeracion-consecutivos.md)) |
| Validación que requiere lock pesado a nivel DB | **Plugin C# pre-validate** |
| Llamar a API externa con autenticación compleja (OAuth, etc.) | **Plugin C# o Custom Connector** |
| Enviar correos masivos | **Power Automate flow** con loop apply-to-each |
| Lógica que debe correr aunque la app esté cerrada | **Flow** (lo Power Fx solo corre con UI activa) |

---

## App de referencia ejecutable

> **Estado**: diferida hasta M2.

El issue #18 contempla una mini-app `INNOVA - Ejemplo Patrones` con cada snippet ejecutable. Decisión: **construirla como parte de M2** (primera Canvas App real) — M2 se vuelve la app de referencia "viva" en lugar de tener un placeholder paralelo que se desactualiza.

Cuando M2 se construya:
1. Cada pantalla con un patrón usado tiene un comentario `// PATRÓN N (ver docs/conventions/power-fx-patterns.md#N)`
2. Issue follow-up reabre la parte ejecutable de #18 y la marca como cubierta por M2

## Referencias

- Convenciones generales: [`power-fx-style.md`](power-fx-style.md)
- Naming Dataverse (columnas que aparecen en estos snippets): [`dataverse-naming.md`](dataverse-naming.md)
- Modelo de datos: [`docs/architecture/data-model.md`](../architecture/data-model.md)
- Parámetros operacionales (patrón 4, 12, 16): [`docs/architecture/parametros.md`](../architecture/parametros.md)
- Algoritmo consecutivo (patrón "cuándo no Power Fx"): [`docs/architecture/numeracion-consecutivos.md`](../architecture/numeracion-consecutivos.md)
- Workflow de tests para Canvas: [`tests/canvas/`](../../tests/canvas/)
