# Dataverse Plug-ins (C#)

Plug-ins de servidor para Dataverse, ejecutados en respuesta a eventos del pipeline.

Solo crear un plug-in cuando Power Fx + Power Automate no puedan resolver el caso (típicamente: lógica que debe ejecutarse SIEMPRE incluso cuando el cambio viene desde API, o lógica con performance crítica).

## Stack

- .NET Framework 4.6.2 (requerido por Dataverse)
- C# 7.3
- Pruebas con xUnit + FakeXrmEasy

## Estructura esperada

```
plugins/
├── Pasqui.Innova.Plugins/
│   ├── Pasqui.Innova.Plugins.csproj
│   ├── IniciativaCreatedPlugin.cs
│   ├── Common/
│   └── Properties/
├── Pasqui.Innova.Plugins.Tests/
│   ├── Pasqui.Innova.Plugins.Tests.csproj
│   └── IniciativaCreatedPluginTests.cs
└── Pasqui.Innova.Plugins.sln
```

## Comandos comunes

```powershell
dotnet build
dotnet test
pac plugin push
```

## Convenciones

- Una clase por plug-in
- Heredar de `PluginBase` (a definir en `Common/`)
- Naming: `<Entidad><Evento>Plugin.cs` — ejemplo: `IniciativaCreatedPlugin.cs`
- Logging estructurado vía `ITracingService`
- Sin dependencias externas no aprobadas por el Tech Lead
