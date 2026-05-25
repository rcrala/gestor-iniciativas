# Dataverse Plug-ins (C#)

Plug-ins de servidor para Dataverse, ejecutados en respuesta a eventos del pipeline.

Solo crear un plug-in cuando Power Fx + Power Automate no puedan resolver el caso (típicamente: lógica que debe ejecutarse SIEMPRE incluso cuando el cambio viene desde API, o lógica con performance crítica).

## Stack

- **Plug-in assembly**: `netstandard2.0` + `Microsoft.CrmSdk.CoreAssemblies` (consumible por Dataverse net46x y tests cross-platform net8.0)
- **Lenguaje**: C# 7.3
- **Strong-name signing**: requerido por Dataverse (`.snk` versionado en repo - es identidad de assembly, no credencial)
- **Tests**: NUnit 4 + fakes manuales para `IOrganizationService` / `ITracingService` (NSubstitute/Castle no puede proxear interfaces del Xrm.Sdk por custom attributes)

## Estructura

```
plugins/
├── Pasqui.Innova.Plugins.sln
├── Pasqui.Innova.Plugins/                       # Assembly de produccion (netstandard2.0)
│   ├── Pasqui.Innova.Plugins.csproj
│   ├── Pasqui.Innova.Plugins.snk                # Strong-name key (regenerable con scripts/plugins/gen-snk.ps1)
│   ├── Common/
│   │   ├── PluginBase.cs                        # Base class con plumbing IServiceProvider -> LocalPluginContext + error wrapping
│   │   └── ConsecutivoFormatter.cs              # Pure logic, sin dependencias Xrm
│   └── Iniciativa/
│       └── IniciativaPreCreatePlugin.cs         # Pre-Create de pas_iniciativa: asigna consecutivo
└── Pasqui.Innova.Plugins.Tests/                 # Tests (net8.0)
    ├── Pasqui.Innova.Plugins.Tests.csproj
    ├── ConsecutivoFormatterTests.cs             # Unit tests del formatter (sin Dataverse)
    ├── IniciativaPreCreatePluginTests.cs        # Tests de logica con fakes
    └── Fakes/
        ├── FakeOrganizationService.cs           # IOrganizationService manual
        └── FakeTracingService.cs                # ITracingService que captura trazas
```

## Comandos comunes

```powershell
# Build + test local
dotnet build plugins/Pasqui.Innova.Plugins -c Release
dotnet test plugins/Pasqui.Innova.Plugins.Tests --nologo

# Registrar en DEV (primer deploy o update de Content)
pwsh ./scripts/plugins/register-plugin.ps1 -Environment dev

# Smoke test end-to-end (crea iniciativa, valida consecutivo, limpia)
pwsh ./scripts/plugins/smoke-test-consecutivo.ps1

# Update incremental despues del primer registro (mas rapido)
pac plugin push --pluginId <pluginassemblyid> --pluginFile plugins/Pasqui.Innova.Plugins/bin/Release/netstandard2.0/Pasqui.Innova.Plugins.dll --type Assembly
```

## Convenciones

- Una clase por plug-in, nombre `<Entidad><Evento>Plugin.cs` (ej: `IniciativaPreCreatePlugin.cs`)
- Heredar de `PluginBase` para tener tracing + error wrapping automatico
- La logica de negocio en metodos `public static` que reciben `Entity`, `IOrganizationService`, `ITracingService` -> testeable sin mockear `IPluginExecutionContext`
- `ExecuteInternal` solo hace filter (mensaje, entidad, target) y delega al metodo estatico
- Logging via `ITracingService.Trace()` con formato (no concat); aparece en Plugin Trace Log si esta habilitado en el environment
- Sin dependencias externas no aprobadas por el Tech Lead

## Registro y deploy

Ver [`scripts/plugins/register-plugin.ps1`](../scripts/plugins/register-plugin.ps1) que:
1. Lee el DLL via reflection (Name, Version, PublicKeyToken)
2. POSTea `PluginAssembly` (sandbox isolation)
3. POSTea `PluginType` por cada clase
4. POSTea `SdkMessageProcessingStep` enlazando type a mensaje/entidad/stage
5. Verifica via GET

Idempotente: si el assembly ya existe (por Name), actualiza Content. Si el step ya existe (por Name), no lo recrea.
