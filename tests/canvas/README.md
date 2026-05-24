# Tests — Power Apps Canvas

Test plans manuales por pantalla.

## Convención

Cada pantalla principal (M2-M14) tiene su `.md` siguiendo [`../_template-test-plan.md`](../_template-test-plan.md).

Naming: `m<NN>-<nombre-pantalla>-test-plan.md`. Ejemplo: `m02-solicitante-test-plan.md`.

## Por qué manual

Power Apps Test Studio existe pero su ROI es bajo (ver decisión en [`docs/decisions/0005-tooling-de-tests.md`](../../docs/decisions/0005-tooling-de-tests.md)). Test plans manuales con screenshots son más reproducibles y revisables en PR.

## Cobertura mínima por pantalla

- Happy path completo del rol asignado
- Validación de campos requeridos
- Comportamiento con permisos del rol (intento de acceso a botón/sección no autorizada)
- Comportamiento offline / con error de connector
- Responsive (si aplica): móvil y tablet

## Ejemplo incluido

[`m02-solicitante-test-plan.md`](./m02-solicitante-test-plan.md) — test plan placeholder para la pantalla del Solicitante (M2). Se ejecutará cuando la pantalla se implemente.
