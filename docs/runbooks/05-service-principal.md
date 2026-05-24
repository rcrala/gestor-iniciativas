# Runbook: Service Principal de INNOVA (DEV/QA)

> **Audiencia**: desarrollador del equipo INNOVA con acceso a Azure Portal del tenant Grupo Pasquí y rol de System Administrator en el environment Power Platform correspondiente.
> **Tiempo estimado**: 20-30 min para setup inicial; 5 min para rotación.

## Contexto

INNOVA usa un **Service Principal** (SP) por environment para que scripts y CI/CD se autentiquen contra Power Platform sin depender de la cuenta humana de ningún desarrollador. Esto desbloquea:

- ALM no-interactivo (`pac solution import` desde GitHub Actions)
- Flows con Connection References que no se rompen cuando un desarrollador deja la empresa
- Auditoría limpia (los cambios de CI quedan firmados como `INNOVA-SP-<env>`, no como un usuario)

**PROD vive en el tenant del cliente**, donde el cliente crea su propio SP siguiendo [`04-deploy-release-cliente.md`](04-deploy-release-cliente.md). Este runbook cubre solo DEV y QA en el tenant Grupo Pasquí.

## Setup inicial (una sola vez por environment)

### 1. App Registration en Entra ID

En https://portal.azure.com → **Microsoft Entra ID → App registrations → + New registration**:

- **Name**: `INNOVA-SP-DEV` (o `INNOVA-SP-QA`)
- **Supported account types**: `Single tenant`
- **Redirect URI**: dejar vacío

Después de **Register**, en la pantalla Overview capturar:
- Application (client) ID
- Directory (tenant) ID

### 2. API Permissions

Dentro de la app → **API permissions → + Add a permission → Microsoft APIs → Dynamics CRM → Delegated → `user_impersonation` → Add**.

Luego clic **Grant admin consent for <tenant>** → confirmar. El estado debe quedar verde "Granted".

> Si **Dynamics CRM** no aparece en el filtro, escribir `Dataverse` (nombre alternativo) o pegar el App ID `00000007-0000-0000-c000-000000000000` en el filtro de "APIs my organization uses".

### 3. Client Secret

**Certificates & secrets → + New client secret**:
- **Description**: `INNOVA SP <ENV> - 24m`
- **Expires**: 24 months

**CRÍTICO**: copiar la columna **Value** inmediatamente. Solo se ve UNA vez. Si se pierde, generar otro. Anotar también la fecha de expiración para rotar a tiempo.

### 4. Application User en Power Platform

En https://admin.powerplatform.microsoft.com → seleccionar environment → **Settings → Users + permissions → Application users → + New app user**:

- **App**: buscar y seleccionar `INNOVA-SP-<ENV>`
- **Business unit**: la raíz del environment (nombre tipo `org<8chars>`)
- **Security roles**: `System Administrator`

> En DEV usamos `System Administrator` para que el SP pueda hacer ALM completo (crear/modificar tablas, importar solutions, etc.). En PROD del cliente se restringe (ver runbook 04).

### 5. Almacenar credenciales localmente

En tu máquina, dentro del repo:

```powershell
Copy-Item .env.dev.template .env.dev
```

Editar `.env.dev` (gitignored — el `.gitignore` lo cubre vía `.env.*`) y rellenar las 4 variables:

```env
INNOVA_TENANT_ID=<tenant id capturado en paso 1>
INNOVA_SP_CLIENT_ID=<application client id capturado en paso 1>
INNOVA_SP_CLIENT_SECRET=<value capturado en paso 3>
INNOVA_DEV_URL=https://org93905a7d.crm.dynamics.com
```

### 6. Configurar perfil `pac auth`

```powershell
pwsh ./scripts/setup/auth-sp.ps1 -Environment dev
```

Esto:
1. Lee `.env.dev`
2. Crea perfil `innova-sp-dev` con `pac auth create --applicationId ... --clientSecret ...`
3. Selecciona el perfil
4. Valida con `pac org who`

Si todo va bien, el output termina con `Listo. Perfil 'innova-sp-dev' activo y validado`.

## Compartir con otros desarrolladores del equipo

El `Client ID` y `Tenant ID` son públicos (visibles en Entra ID por cualquiera del tenant). El **Client Secret** se comparte por canal seguro:

- **Preferido**: gestor de contraseñas empresarial (1Password, Bitwarden Teams, Azure Key Vault)
- **Aceptable temporal**: archivo cifrado en SharePoint del equipo (con permisos restringidos)
- **NUNCA**: chat, email, Teams en texto plano, commit accidental

Cada desarrollador clona el repo, hace su propio `Copy-Item .env.dev.template .env.dev`, pega los valores, y corre `auth-sp.ps1` localmente.

## GitHub Secrets (para CI/CD)

Cuando se cablee el auto-deploy a QA (sub-tarea diferida de S0-6), las mismas variables van a https://github.com/rcrala/gestor-iniciativas/settings/secrets/actions:

| GitHub Secret | Valor |
|---|---|
| `PAC_DEV_TENANT_ID` | INNOVA_TENANT_ID |
| `PAC_DEV_CLIENT_ID` | INNOVA_SP_CLIENT_ID |
| `PAC_DEV_CLIENT_SECRET` | INNOVA_SP_CLIENT_SECRET |
| `PAC_DEV_URL` | INNOVA_DEV_URL |

Y análogamente `PAC_QA_*` para el SP de QA.

Configurar via CLI:

```powershell
# Requiere gh CLI autenticado
gh secret set PAC_DEV_TENANT_ID --body "<valor>"
gh secret set PAC_DEV_CLIENT_ID --body "<valor>"
gh secret set PAC_DEV_CLIENT_SECRET --body "<valor>"
gh secret set PAC_DEV_URL --body "https://org93905a7d.crm.dynamics.com"
```

El workflow los lee como `${{ secrets.PAC_DEV_CLIENT_SECRET }}`.

## Rotación del secret (cada 24 meses)

1. En Entra ID → app → **Certificates & secrets → + New client secret** (descripción: `INNOVA SP <ENV> - 24m (rotado <fecha>)`)
2. Copiar el nuevo Value
3. Actualizar `.env.dev` local
4. Actualizar GitHub Secret correspondiente (`gh secret set PAC_DEV_CLIENT_SECRET --body "<nuevo>"`)
5. Notificar a los demás desarrolladores que actualicen su `.env.dev`
6. Validar con `pwsh ./scripts/setup/auth-sp.ps1 -Environment dev`
7. Una vez todo migrado al nuevo secret, eliminar el viejo de Entra ID (`Delete` en la lista de secrets)

> Marcar la fecha de expiración del nuevo secret en el calendario del equipo + 23 meses para volver a rotar.

## Diagnóstico

| Error | Causa probable | Solución |
|---|---|---|
| `AADSTS7000215: Invalid client secret` | Secret expirado, mal pegado o tiene espacios | Rellenar de nuevo en `.env.dev`. Si expiró, generar uno nuevo |
| `AADSTS70011: Permission was not consented` | Falta Grant admin consent en API permissions | Volver a paso 2 y dar consent |
| `Caller is not authorized to access this resource` en `pac org who` | Falta Application User en Power Platform | Volver a paso 4 |
| `Caller has Security Role X but needs Y` | Application User existe pero con rol incorrecto | Asignar `System Administrator` (o el requerido) en Admin Center |
| `0x80044150 The user is not assigned to any roles` | SP creado en BU equivocada | Verificar que la BU del Application User sea la raíz `org<8chars>` |
| `pac CLI no encontrado en PATH` | PAC no instalado | `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` |

## Referencias

- Runbook deploy al cliente (PROD): [`04-deploy-release-cliente.md`](04-deploy-release-cliente.md)
- ADR-0004 entrega al cliente: [`../decisions/0004-entrega-cliente.md`](../decisions/0004-entrega-cliente.md)
- Script de configuración: [`scripts/setup/auth-sp.ps1`](../../scripts/setup/auth-sp.ps1)
- Plantilla de credenciales: [`.env.dev.template`](../../.env.dev.template)
- Documentación oficial PAC `auth create`: https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/auth
