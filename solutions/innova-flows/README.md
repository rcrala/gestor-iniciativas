# Solution: innova-flows

Contiene los Power Automate Cloud Flows de INNOVA:

- Flows top-level disparados por eventos de Dataverse
- Child flows reutilizables (envío de correo, Teams, log)
- Scheduled flows (recordatorios cada 3 días)

Connection References declaradas aquí. El ambiente destino debe tener las conexiones configuradas con service principal antes de importar.

## Plantilla canonica (S0-8)

**Antes de crear cualquier flow nuevo**, ver [`templates/`](templates/) — contiene la plantilla obligatoria con la estructura de 4 scopes (`Validations`, `Main Logic`, `Notifications`, `Error Handler`) y los `runAfter` exactos.

- JSON: [`templates/flow-canonico-plantilla.json`](templates/flow-canonico-plantilla.json)
- Guia de uso: [`templates/README.md`](templates/README.md)
- Runbook completo: [`../../docs/runbooks/09-flow-template-canonico.md`](../../docs/runbooks/09-flow-template-canonico.md)
- Scripts: [`../../scripts/flows/register-flow-template.ps1`](../../scripts/flows/register-flow-template.ps1), [`../../scripts/flows/test-flow-template.ps1`](../../scripts/flows/test-flow-template.ps1)

## Flows productivos

| Flow | Trigger | Archivo | Issue / Test plan |
|---|---|---|---|
| `INNOVA - Iniciativa Creada - Notificar PMO` | Dataverse Create sobre `pas_iniciativa` | [`flows/INNOVA-iniciativa-creada-notificar-pmo.json`](flows/INNOVA-iniciativa-creada-notificar-pmo.json) | #55 / [`tests/flows/iniciativa-creada-notificar-pmo-test-plan.md`](../../tests/flows/iniciativa-creada-notificar-pmo-test-plan.md) |

Para registrar/redesplegar un flow productivo, usar el script correspondiente en `scripts/flows/register-<flow-slug>.ps1`. Todos siguen el patron idempotente del template.

Ver `docs/conventions/power-automate-style.md` para el estilo de flows.
