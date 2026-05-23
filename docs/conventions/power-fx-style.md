# Estilo de Power Fx

## Naming de variables

| Tipo | Prefix | Ejemplo |
|---|---|---|
| Variable global | `gbl` | `gblUserRole`, `gblCurrentEmpresa` |
| Variable de contexto (local de pantalla) | `loc` | `locFormMode`, `locSelectedRecord` |
| Collection | `col` | `colIniciativasFiltered`, `colCotizaciones` |
| Variable temporal | `var` | `varTempCalculation` |

## Formato

- Indentación: 4 espacios, NUNCA tabs
- Una declaración por línea cuando favorece legibilidad
- Salto de línea después de `;;` en multi-statements
- Espacios alrededor de operadores: `If(x = 1, ...)` no `If(x=1, ...)`

## Estructura de fórmulas

### Buena

```powerfx
Set(gblCurrentUser,
    LookUp(Users,
        'Primary Email' = User().Email
    )
);;
Set(gblUserRole,
    First(gblCurrentUser.Roles).Name
)
```

### Mala

```powerfx
Set(gblCurrentUser,LookUp(Users,'Primary Email'=User().Email));;Set(gblUserRole,First(gblCurrentUser.Roles).Name)
```

## Reglas

1. **Nunca chaining con `;`** — Power Fx usa `;;` para multi-statements
2. **Patch para actualizar registros de Dataverse** — no usar `UpdateContext` sobre records
3. **IsBlank antes de acceder** — siempre validar `If(!IsBlank(rec), rec.Campo, "default")`
4. **Named formulas** — para expresiones reutilizables, usar `App.Formulas`
5. **No hardcodear GUIDs** — usar lookups por nombre o variables globales
6. **Sin nested If profundo** — usar `Switch` si hay 3+ ramas

## App.OnStart

Solo poner aquí:

- Carga del usuario actual y su rol
- Carga de parámetros del sistema (umbrales, montos)
- Inicialización del tema visual
- NUNCA: carga de listas grandes de datos (usar pantallas o `Concurrent`)

## Pantallas

- Cada pantalla tiene `OnVisible` que prepara su estado
- Usar `Notify()` para feedback al usuario
- Usar `Navigate()` con `ScreenTransition.Fade` para movimiento entre pantallas
- Usar `Back()` para retroceder

## Performance

- Filtrar solo con funciones delegables sobre tablas grandes
- Usar `LoadData` / `SaveData` SOLO para datos locales (cache offline)
- Limitar collections a 2.000 registros máximo (soft limit de Power Apps)
- `Concurrent()` para cargas iniciales paralelas
