# ADR-0005: Tooling de tests para INNOVA

> **Estado**: Accepted
> **Fecha**: 2026-05-24
> **Issue**: #20 (S0-9)
> **Decisores**: Tech Lead, Arquitecto

## Contexto

INNOVA construye 4 tipos de artefactos sobre Power Platform:

1. **Power Automate flows** — automatizaciones
2. **Power Apps Canvas** — pantallas
3. **Plugins .NET / C#** — lógica server-side de Dataverse
4. **PCF Controls TypeScript + React** — controles personalizados

Necesitamos una estrategia de tests **coherente, mantenible y que corra en CI** para los 4. El tooling oficial de Microsoft para cada uno tiene capacidades muy distintas.

## Decisión

### Por artefacto

| Artefacto | Estrategia | Herramienta |
|---|---|---|
| **Flows** | Test plans manuales documentados en `tests/flows/*.md` con evidencia | Markdown + screenshots + run history link |
| **Canvas** | Test plans manuales documentados en `tests/canvas/*.md` con evidencia | Markdown + screenshots |
| **Plugins .NET** | Tests automatizados | NUnit 4 + FakeXrmEasy (cuando se acople a Dataverse SDK) |
| **PCF Controls** | Tests automatizados | Jest 29 + ts-jest + jsdom + React Testing Library (cuando aplique) |

Estructura: `tests/{smoke,flows,canvas,plugins,pcf}/` con README y sample en cada subcarpeta automatizable.

### Test Studio de Power Apps: NO al inicio

**Decidido NO usar Power Apps Test Studio** para los tests de Canvas, al menos durante el MVP.

Razones:

1. **Frágil ante cambios de UI**: los tests grabados se rompen con cualquier cambio en el control selector (renombrar un control, reordenar pantallas)
2. **Versionado en Git complicado**: el formato `.fx.yaml` que exporta es difícil de revisar en code review
3. **No corre en CI**: requiere un ambiente Power Apps real con conexiones autenticadas; no hay forma estándar de ejecutarlo desde GitHub Actions
4. **Adopción del equipo**: añade una herramienta más (sintaxis Power Fx + selectors) que el equipo debe aprender; los test plans manuales documentados son más universales
5. **ROI bajo en MVP**: el costo de mantener Test Studio supera al costo de actualizar test plans manuales

**Cuándo reconsiderar**:
- Si llegamos a 5+ pantallas estables con regresiones recurrentes que un test automatizado hubiera atrapado
- Si Microsoft mejora la ejecución de Test Studio en CI sin requerir conexiones interactivas
- Como complemento a Playwright contra el frame del Canvas (alternativa viable pero también costosa)

### Tests de flows: por qué manual

Power Automate **no provee tooling oficial para tests automatizados de flows**. Las opciones existentes son:
- **Mocks de connectors**: requiere reescribir el flow con HTTP triggers fakes — duplica trabajo
- **Child flows de prueba**: posible pero complejo de mantener
- **Tests end-to-end disparando triggers reales**: lo que ya hacemos en QA, no necesita más tooling

Decisión pragmática: **test plans manuales bien estructurados**, ejecutados por humanos cuando el flow se modifica significativamente, con evidencia (screenshots, run history link) versionada en el PR.

### Tests de plugins: por qué NUnit

NUnit vs xUnit vs MSTest. Las tres son válidas. Elegimos **NUnit 4** por:

- Sintaxis `[Test]`, `[TestCase]`, `[TestFixture]` muy legible
- `Throws.ArgumentException` / `Throws.TypeOf<...>` para excepciones más expresivo que xUnit
- `TestCase` con argumentos múltiples para data-driven tests sin atributos largos
- Adoption: mayoría de samples de Dataverse plugins en GitHub usan NUnit

### Tests de PCF: por qué Jest

Jest es el standard de facto para tooling React/TypeScript. Alternativas:
- **Vitest**: más moderno y rápido, pero PCF templates oficiales usan Jest
- **Mocha + Chai**: menor adopción

Decisión: alinearse con el ecosistema PCF oficial → **Jest + ts-jest**.

## Consecuencias

### Positivas

- Strategy clara y diferenciada por tipo de artefacto (no forzamos automatización donde no aplica)
- Tests automatizados corren en CI (jobs `test-plugins` y `lint-pcf` extendidos en S0-9)
- Test plans manuales son revisables en PR, versionables, y sirven como documentación funcional
- Equipos nuevos onboardea más rápido (markdown + NUnit + Jest son herramientas conocidas)

### Negativas

- Tests de flows y canvas dependen de discplina humana (riesgo de "se nos olvidó ejecutar")
- Sin Test Studio perdemos regression testing en Canvas — mitigado con test plans estructurados
- Doble esfuerzo si el cliente eventualmente quiere Test Studio (habría que migrar)

### Neutrales

- Pre-commit hook (PR #42) y CI corren los tests automatizados; los manuales requieren disciplina del autor
- ADR revisable cuando el equipo o el cliente pidan automatización adicional

## Alternativas evaluadas

| Alternativa | Razón de rechazo |
|---|---|
| Power Apps Test Studio + flows tests via Postman | Frágil, no CI, costo alto |
| Playwright contra Canvas Apps | Costo de mantener selectors XPath altísimo, Canvas DOM cambia con cada versión |
| xUnit en vez de NUnit | Misma capacidad; NUnit ya está en samples de Dataverse |
| Vitest en vez de Jest | PCF templates oficiales usan Jest, no romper la convención |
| Pester para tests de scripts PowerShell | Considerado, no urgente; los scripts setup/ ya tienen idempotencia self-testing al re-ejecutar. Reconsiderar si surge complejidad |

## Implementación

Concretada en issue #20 (S0-9):

- `tests/_template-test-plan.md` para manual tests
- `tests/plugins/Sample.Tests/` con NUnit ejecutable (15 tests pasando) — replicar estructura para production plugins
- `tests/pcf/sample/` con Jest ejecutable (14 tests pasando) — replicar para production PCF
- CI workflow extendido con jobs que corren ambos samples
- `tests/README.md` con la estrategia completa
- READMEs por subcarpeta (`tests/flows/`, `tests/canvas/`, `tests/smoke/`, `tests/plugins/`, `tests/pcf/`)

## Referencias

- Test framework completo: [`tests/README.md`](../../tests/README.md)
- Plantilla: [`tests/_template-test-plan.md`](../../tests/_template-test-plan.md)
- Sample NUnit: [`tests/plugins/Sample.Tests/`](../../tests/plugins/Sample.Tests/)
- Sample Jest: [`tests/pcf/sample/`](../../tests/pcf/sample/)
- Ejemplo manual flow: [`tests/flows/iniciativa-creada-notificar-pmo-test-plan.md`](../../tests/flows/iniciativa-creada-notificar-pmo-test-plan.md)
- Ejemplo manual canvas: [`tests/canvas/m02-solicitante-test-plan.md`](../../tests/canvas/m02-solicitante-test-plan.md)
