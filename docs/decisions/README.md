# Architecture Decision Records (ADRs)

Registramos aquí decisiones arquitectónicas significativas que afectan el sistema a largo plazo.

## Lista de ADRs

- [ADR-0001](0001-stack-power-platform.md) — Stack tecnológico Microsoft Power Platform _(superseded by ADR-0006, propuesto)_
- [ADR-0002](0002-adopcion-claude-code.md) — Adopción de Claude Code para desarrollo
- [ADR-0003](0003-arquitectura-multi-empresa.md) — Arquitectura multi-empresa con Business Units
- [ADR-0004](0004-entrega-cliente.md) — Estrategia de entrega al cliente
- [ADR-0005](0005-tooling-de-tests.md) — Tooling de tests
- [ADR-0006](0006-stack-react-dotnet-deployable-saas.md) — Stack pro-code React + .NET, desplegable en cliente y evolución a SaaS

## Cómo escribir un nuevo ADR

1. Copiar `_template.md` con el siguiente número correlativo
2. Nombrar el archivo `NNNN-titulo-corto.md` en kebab-case
3. Llenar el template
4. PR para revisión del equipo
5. Una vez aceptado, actualizar este README

## Cuándo escribir un ADR

- Decisiones que afectan múltiples módulos
- Decisiones que son costosas de revertir
- Decisiones con alternativas serias consideradas
- Cualquier decisión que un nuevo miembro del equipo necesitaría entender
