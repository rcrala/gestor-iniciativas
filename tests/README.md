# Tests INNOVA

Estrategia y herramientas de prueba para los 4 tipos de artefacto del stack Power Platform.

## Estructura

```
tests/
├── _template-test-plan.md     # Plantilla para test plans manuales
├── smoke/                     # Smoke tests post-deployment (markdown)
├── flows/                     # Test plans de Power Automate flows (markdown)
├── canvas/                    # Test plans de Power Apps Canvas (markdown)
├── plugins/                   # Tests automatizados .NET (NUnit)
│   └── _sample/              # Sample project que valida la cadena de build
└── pcf/                       # Tests automatizados TypeScript (Jest)
    └── _sample/              # Sample project que valida la cadena de build
```

## Filosofía por tipo de artefacto

| Artefacto | Tipo de test | Tooling | Por qué |
|---|---|---|---|
| **Power Automate flow** | Manual documentado | Markdown + screenshots | No hay tooling oficial para tests automatizados de flows |
| **Power Apps Canvas** | Manual documentado | Markdown + screenshots | Test Studio existe pero su ROI es bajo (ver decisión abajo); manual es más reproducible |
| **Plugin .NET / C#** | Automatizado | NUnit + FakeXrmEasy (cuando aplique) | Stack maduro, código testable como cualquier .NET library |
| **PCF Control TypeScript** | Automatizado | Jest + React Testing Library | Stack web estándar, componentes React testables |

## Decisión: Test Studio de Power Apps

**No usamos Test Studio al inicio**. Razones:

1. **Frágil**: los tests grabados se rompen con cualquier cambio menor en el control selector
2. **Versionable mal**: el formato `.fx.yaml` de tests es difícil de revisar en PR
3. **No corre en CI**: requiere ambiente Power Apps real con conexiones autenticadas
4. **ROI bajo en MVP**: el costo de mantenerlos supera al de mantener test plans manuales bien estructurados

**Cuándo reconsiderar**: si llegamos a 5+ pantallas estables con regresiones recurrentes, evaluar Test Studio o Playwright contra el frame del Canvas.

Decisión completa: [`docs/decisions/0005-tooling-de-tests.md`](../docs/decisions/0005-tooling-de-tests.md)

## Convenciones para test plans manuales

Cada test plan vive en su propia carpeta (`tests/flows/`, `tests/canvas/`, `tests/smoke/`) como `.md` siguiendo [`_template-test-plan.md`](./_template-test-plan.md).

Naming: `<nombre-artefacto>-test-plan.md`. Ejemplos:
- `tests/flows/iniciativa-creada-notificar-pmo-test-plan.md`
- `tests/canvas/m02-solicitante-test-plan.md`
- `tests/smoke/deploy-qa-post-deploy-test-plan.md`

Cada ejecución actualiza el campo "Última ejecución" en el header del plan. La **evidencia** (screenshots, logs) va a `tests/_evidence/` con prefijo de fecha.

## Tests automatizados

### Plugins .NET

```powershell
# Desde la raíz del repo
dotnet test tests/plugins/_sample/Sample.Tests.csproj
```

Estructura sample esperada (replicar para cada nuevo plugin de producción):

```
plugins/<NombreReal>/
├── <NombreReal>.csproj            # Plugin de producción
└── <NombreReal>.cs
plugins/<NombreReal>.Tests/
├── <NombreReal>.Tests.csproj      # Test project NUnit
└── <NombreReal>Tests.cs
```

Cobertura objetivo: ≥ 80% líneas para plugins críticos (consecutivo, validaciones de monto, voto del Comité).

### PCF Controls

```powershell
# Desde la raíz del repo
cd tests/pcf/_sample
npm install
npm test
```

Estructura sample esperada:

```
pcf/<NombreControl>/
├── package.json
├── tsconfig.json
├── ControlManifest.Input.xml
└── <NombreControl>/index.ts

pcf/<NombreControl>/__tests__/
└── <NombreControl>.test.ts
```

## CI

`.github/workflows/ci.yml` ejecuta automáticamente `dotnet test` sobre todo `**/*.csproj` (incluido el sample) y `npm test` sobre todo `**/package.json` (incluido el sample) — ver jobs `test-plugins` y `lint-pcf`.

Si los samples están y compilan/pasan tests, los jobs son verdes incluso sin código de producción.

## Cobertura objetivo

| Tipo | Objetivo MVP | Cuándo |
|---|---|---|
| Plugins NUnit | ≥ 80% líneas en lógica de negocio | Por plugin antes de merge |
| PCF Jest | ≥ 70% líneas en componentes | Por control antes de merge |
| Flows manual | Happy path + 2 error paths documentados | Por flow antes de merge a main |
| Canvas manual | Cada pantalla principal cubierta | Antes de demo al stakeholder |
| Smoke post-deploy | Login + crear iniciativa + ver dashboard | Cada deploy a QA y PROD |

## Evidencia y trazabilidad

- Cada PR que toque un flow/canvas debe incluir el link al test plan ejecutado + resultado
- Issues bloqueados por bug en test deben referenciar #NN del test plan
- Test plans son "código vivo": se actualizan cuando el comportamiento cambia

## Cuándo agregar un nuevo tipo de test

Si surge una categoría nueva (ej. tests de Power BI reports, tests de seguridad/roles), agregarla aquí:

1. Crear subcarpeta `tests/<categoria>/`
2. Documentar tooling y filosofía en esta sección
3. Agregar README en la subcarpeta
4. Actualizar CI si el tipo es automatizable

## Referencias

- Plantilla: [`_template-test-plan.md`](./_template-test-plan.md)
- Runbook que sirve como referencia para test plans manuales: [`docs/runbooks/08-historia-piloto-notificacion-pmo.md`](../docs/runbooks/08-historia-piloto-notificacion-pmo.md)
- ADR sobre tooling: [`docs/decisions/0005-tooling-de-tests.md`](../docs/decisions/0005-tooling-de-tests.md)
