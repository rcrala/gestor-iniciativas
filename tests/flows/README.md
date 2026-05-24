# Tests — Power Automate flows

Test plans manuales para cada flow de INNOVA.

## Convención

Cada flow tiene un `.md` con el patrón [`../_template-test-plan.md`](../_template-test-plan.md).

Naming: `<nombre-flow>-test-plan.md`. Ejemplo: `iniciativa-creada-notificar-pmo-test-plan.md`.

## Por qué manual y no automatizado

Power Automate **no tiene tooling oficial para tests automatizados de flows**. Las alternativas (mocks, hand-crafted HTTP triggers, child flows de prueba) introducen complejidad mayor que la del flow original.

Estrategia: test plans estructurados + ejecuciones documentadas + evidencia (run history link, screenshots) en cada PR que toque el flow.

## Cobertura mínima por flow

- Happy path
- Al menos 2 error paths (ej. dato faltante, connector timeout)
- Validación de side-effects (registros creados, correos enviados, estados actualizados)

## Plantillas relacionadas

El runbook [`docs/runbooks/08-historia-piloto-notificacion-pmo.md`](../../docs/runbooks/08-historia-piloto-notificacion-pmo.md) sirve de ejemplo completo de cómo se documenta un flow end-to-end.

## Ejemplo incluido

[`iniciativa-creada-notificar-pmo-test-plan.md`](./iniciativa-creada-notificar-pmo-test-plan.md) — test plan del flow piloto del runbook 08.
