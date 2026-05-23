# PCF Controls

Controles custom de Power Apps Component Framework (TypeScript + React).

Solo crear un PCF cuando los controles estándar de Canvas no resuelvan el caso. Por defecto, preferir Canvas controls + Power Fx.

## Estructura esperada

```
pcf/
├── MiControl/
│   ├── ControlManifest.Input.xml
│   ├── index.ts
│   ├── components/
│   ├── tsconfig.json
│   └── package.json
└── package.json   # workspace root
```

## Comandos comunes

```powershell
# Crear un nuevo control
pac pcf init --namespace Pasqui --name MiControl --template field

# Compilar
npm run build

# Test local en el harness
npm start

# Push al ambiente DEV
pac pcf push --publisher-prefix pas
```

## Convenciones

- TypeScript strict mode (sin `any`)
- React functional components con hooks
- Estilos en CSS modules
- Pruebas con Jest + React Testing Library
