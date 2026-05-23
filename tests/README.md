# Tests

Planes de prueba y casos de prueba automatizados de INNOVA.

## Estructura

```
tests/
├── unit/              # Pruebas unitarias de plug-ins y PCF
├── integration/       # Pruebas de integración de flows
├── e2e/               # Pruebas end-to-end (Playwright)
├── smoke/             # Smoke tests post-deployment
└── manual/            # Casos de prueba manual (UAT, exploratorias)
```

## Cobertura objetivo

| Tipo | Objetivo |
|---|---|
| Unit (plug-ins, PCF) | ≥ 80% líneas |
| Integration (flows) | Happy path + 2 error paths por flow |
| E2E | Cada rol completa su pantalla principal |
| Smoke post-deploy | Login + crear iniciativa + ver dashboard |

## Tooling

- Plug-ins: xUnit + FakeXrmEasy
- PCF: Jest + React Testing Library
- E2E: Playwright con TypeScript
- Manual: documentos Markdown con checklists
