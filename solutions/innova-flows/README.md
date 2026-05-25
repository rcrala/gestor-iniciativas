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

Ver `docs/conventions/power-automate-style.md` para el estilo de flows.
