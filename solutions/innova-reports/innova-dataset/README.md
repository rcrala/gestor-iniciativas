# INNOVA - Dataset Semantico (Power BI TMDL)

Modelo semantico de Power BI para INNOVA en formato **TMDL** (Tabular Model Definition Language) — texto plano, git-friendly, replaza el binario `.pbix` para el modelo de datos.

## Que entrega este folder

- **Modelo estrella** con `iniciativa` como tabla de hechos
- **5 dimensiones**: empresa, centroCosto, estados (lookup), Calendar (date), departamento
- **8 medidas DAX** comunes: total, montos, ahorros, ROI promedio, aprobaciones, tasa
- **Conexion Dataverse** via OData Feed (URL parametrizable por environment)

## Estructura

```
innova-dataset/
├── README.md                                     # esto
├── .gitignore                                    # ignora cache local .pbi/
├── innova-dataset.pbip                           # archivo de proyecto
├── innova-dataset.SemanticModel/
│   ├── definition.pbism                          # metadata del semantic model
│   └── definition/
│       ├── model.tmdl                            # root model definition
│       ├── database.tmdl                         # database settings
│       ├── relationships.tmdl                    # FKs entre tablas
│       ├── cultures/
│       │   └── es-CR.tmdl                        # locale Costa Rica
│       └── tables/
│           ├── iniciativa.tmdl                   # fact table
│           ├── empresa.tmdl                      # dim
│           ├── centroCosto.tmdl                  # dim
│           ├── departamento.tmdl                 # dim
│           ├── estados.tmdl                      # lookup labels de estado
│           └── Calendar.tmdl                     # date dim calculada
└── innova-dataset.Report/
    ├── definition.pbir
    └── definition/
        └── report.json                           # report shell vacio
```

## Como abrir y usar

### Prerrequisitos

- **Power BI Desktop** (gratis, https://powerbi.microsoft.com/desktop/) version **2024-04 o posterior** (soporte nativo de TMDL)
- En `File > Options and settings > Options > Preview features` -> activar **"Power BI Project (.pbip) save format"** y **"Store semantic model using TMDL format"**

### Primera apertura

1. Doble clic en `innova-dataset.pbip`
2. Power BI Desktop carga el modelo + reporte vacio
3. Sera te pedira credenciales para la conexion Dataverse OData. Usar cuenta GTC o el SP

### Refresh de data

Por defecto el modelo usa la URL de DEV (`https://org93905a7d.crm.dynamics.com`). Para cambiar a otro environment, editar `tables/iniciativa.tmdl` (y otras tablas) y buscar la variable `url`. O usar un Power Query parameter (a agregar en iteracion futura).

### Modificar el modelo

Cualquier cambio que hagas en Power BI Desktop (agregar tabla, medida, relacion) se persiste en los `.tmdl` cuando guardas. Git diff te muestra el cambio.

Para cambios via texto plano:
1. Editar el `.tmdl` correspondiente en tu IDE
2. Abrir el `.pbip` en Power BI Desktop -> hace refresh automatico
3. Si hay error de syntax, Power BI Desktop muestra el detalle al abrir

## Limitaciones del MVP

- **Conexion hardcoded a DEV**. Para multi-env (DEV/QA/PROD), refactor a Power Query parameter `EnvironmentUrl`
- **Sin RLS (Row-Level Security)**. Cuando se necesite que cada Solicitante vea solo sus iniciativas (per ADR-0003 / Business Units), agregar `RLS` roles
- **Date dim Calendar es calculada** (no de Dataverse). Cubre 2024-01-01 a 2030-12-31. Si se necesita mas, editar `Calendar.tmdl`
- **Sin visuals**. El `Report` es shell vacio — el equipo de BI agrega visuals una vez el modelo este aprobado por el cliente

## Por que TMDL en vez de .pbix

`.pbix` es binario:
- Imposible de hacer code review
- Conflicts de merge irresolubles
- Diffs ininteligibles

`.pbip` + TMDL es texto:
- Code review en PRs
- Merge conflict normales (resolubles por linea)
- Diffs claros (que medida cambio, que columna se agrego)
- Compatible con todos los workflows git/CI/CD

Microsoft anuncio TMDL como formato recomendado en 2024.

## Referencias

- TMDL official docs: https://learn.microsoft.com/en-us/analysis-services/tmdl/tmdl-overview
- PBIP format: https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview
- Dataverse connector M: https://learn.microsoft.com/en-us/power-query/connectors/dataverse
