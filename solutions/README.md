# Solutions de Power Platform

Este directorio contiene los Solutions de Power Platform desempaquetados (formato source-controlled).

## Estructura

```
solutions/
├── innova-core/        # Tablas, columnas, relaciones, roles de seguridad
├── innova-flows/       # Power Automate cloud flows
├── innova-canvas/      # Canvas Apps (YAML desempaquetado)
└── innova-reports/     # Power BI artifacts
```

## Workflow

### Exportar desde DEV

```powershell
pac solution export `
    --name innova-core `
    --path ./exported/innova-core.zip
pac solution unpack `
    --zipfile ./exported/innova-core.zip `
    --folder ./solutions/innova-core `
    --packagetype Unmanaged
```

### Empaquetar para QA o PROD

```powershell
pac solution pack `
    --folder ./solutions/innova-core `
    --zipfile ./out/innova-core.zip `
    --packagetype Managed
```

### Importar a otro ambiente

```powershell
pac auth select --name innova-qa
pac solution import --path ./out/innova-core.zip
```

## Reglas

- NUNCA editar el `solution.xml` a mano (usar PAC CLI o el maker portal)
- SIEMPRE exportar y unpack después de cambios en DEV
- Commits atómicos: un commit = un feature funcional
- Etiquetar versions: `git tag innova-core-v1.0.0`
- `innova-core` es prerrequisito de las demás solutions; instalarla primero
