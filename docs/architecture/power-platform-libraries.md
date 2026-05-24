# Librerías y herramientas Power Platform descubiertas para INNOVA

> **Propósito**: Inventario consolidado de las herramientas, CLIs, APIs, módulos PowerShell y assemblies .NET que el proyecto está usando o ha probado. Sirve como referencia para evitar reinventar y para nuevos developers.
> **Última actualización**: 2026-05-24 (post Sprint 0 S0-2/S0-3/S0-4)

---

## 1. CLIs y herramientas externas

### Power Platform CLI (PAC)

**Versión usada**: 2.7.4
**Instalación**: `dotnet tool install --global Microsoft.PowerApps.CLI.Tool` o winget
**Ubicación bundled**: `%LOCALAPPDATA%\Microsoft\PowerAppsCLI\pac.cmd`

**Comandos usados en este proyecto**:

| Comando | Para qué |
|---|---|
| `pac auth create --environment <url>` | Autenticación contra environment |
| `pac auth list` / `pac auth select` | Gestión de perfiles |
| `pac org who` | Confirmar environment activo |
| `pac admin list-roles` | Listar roles de un environment |
| `pac admin create-service-principal` | Crear App User para SP (no usado aún, planeado para S0-5) |
| `pac solution export/unpack/pack/import` | ALM de solutions |
| `pac canvas pack/unpack` | Convertir `.msapp` ↔ YAML |
| `pac pcf init/push` | PCF Controls |
| `pac plugin push` | Dataverse plug-ins .NET |

**Limitaciones encontradas**:
- `pac admin business-unit` **no existe** — para BUs hay que usar Web API directo
- Para crear tablas/columnas/relaciones no hay comando PAC — Web API o maker portal

### Az PowerShell (Az.Accounts)

**Versión usada**: 5.4.0
**Instalación**: `Install-Module Az.Accounts -Scope CurrentUser`
**Comandos clave**:

| Comando | Para qué |
|---|---|
| `Connect-AzAccount -UseDeviceAuthentication -Subscription <id>` | Login interactivo (device code en URL) |
| `Get-AzContext` | Verificar sesión activa |
| `Get-AzAccessToken -ResourceUrl 'https://<env>.crm.dynamics.com/'` | Obtener bearer token para Dataverse Web API |

**Por qué Az.Accounts y no Microsoft.PowerApps.PowerShell o XrmTooling**:
- Maneja sus dependencias .NET (binding redirects) automáticamente
- Soporte de Microsoft, mantenido activamente
- Single module install (50MB user scope, sin admin)
- Compatible con MSAL moderno
- **Alternativas probadas que NO funcionaron**: cargar DLLs bundled de PAC con `Add-Type` falla por `Microsoft.Bcl.AsyncInterfaces` dependency resolution

### GitHub CLI (gh)

**Para qué en INNOVA**:
- `gh issue create/edit/list` — gestión de issues
- `gh pr create/list/view` — pull requests
- `gh label create/delete/list` — gestión de labels del repo
- `gh api` — llamadas REST directas a GitHub API
- `gh auth status` — verificación de autenticación

---

## 2. Dataverse Web API (REST)

**Base URL**: `https://<org>.crm.dynamics.com/api/data/v9.2/`

**Headers estándar** (manejados por nuestra lib `Invoke-DataverseApi`):
```
Authorization: Bearer <token>
OData-MaxVersion: 4.0
OData-Version: 4.0
Accept: application/json
Content-Type: application/json; charset=utf-8
Prefer: return=representation        ← opcional, para que POST devuelva el objeto
MSCRM.SolutionUniqueName: innova_core ← clave para que artefactos queden en la solution correcta
```

### Endpoints usados en S0-2/S0-3/S0-4

| Endpoint | Método | Para qué |
|---|---|---|
| `/WhoAmI` | GET | Verificar identidad y obtener UserId, BusinessUnitId, OrganizationId |
| `/businessunits` | GET / POST | Listar / crear Business Units |
| `/publishers` | GET | Listar publishers (verificar que existe `Pasqui`) |
| `/solutions` | GET | Listar solutions (verificar `innova_core`) |
| `/GlobalOptionSetDefinitions` | GET / POST | Choice sets globales |
| `/EntityDefinitions` | GET / POST / DELETE | Tablas Dataverse |
| `/EntityDefinitions(LogicalName='X')/Attributes` | GET / POST | Columnas de una tabla |
| `/EntityDefinitions(LogicalName='X')/Attributes/Microsoft.Dynamics.CRM.LookupAttributeMetadata` | GET | Filtrar solo lookups |
| `/RelationshipDefinitions` | GET / POST | Relaciones (incl. OneToMany para lookups) |
| `/RelationshipDefinitions/Microsoft.Dynamics.CRM.OneToManyRelationshipMetadata` | GET | Filtrar a OneToMany |
| `/roles` | GET / POST | Security Roles |
| `/roles({id})/Microsoft.Dynamics.CRM.AddPrivilegesRole` | POST | Asignar privilegios a un rol (action) |
| `/privileges` | GET | Lookup de privilegios por nombre |
| `/systemusers` | GET | Lookup de usuarios |

### Naming convention de privilegios

Cada tabla genera 8 privilegios al crearse:
```
prv{Verb}{logical_name}
```

Verbos: `Create`, `Read`, `Write`, `Delete`, `Append`, `AppendTo`, `Assign`, `Share`.

Ejemplo: `prvReadpas_iniciativa`, `prvCreatepas_evaluacionpmo`.

### Quirks descubiertos al integrar

| Quirk | Solución |
|---|---|
| LogicalName se deriva del SchemaName en lowercase | Para preservar underscores en LogicalName, usar SchemaName con underscores también (`pas_Nombre_Corto` → `pas_nombre_corto`) |
| Picklist con global option set inline da error "Only Local can be created" | Usar `GlobalOptionSet@odata.bind` apuntando al MetadataId del choice |
| Decimal MinValue/MaxValue rechazado con "IEEE754Compatible conflict" | Cast `[decimal]` en PowerShell para que ConvertTo-Json emita con decimal point |
| Primary name attribute no se puede cambiar post-creación | Solo recreate de la entidad completa |
| DELETE de entidad con relaciones falla con "X components depend" | Surgical: deletar relaciones primero, o aceptar que algunas cosas son inmutables |
| GlobalOptionSetDefinitions no soporta `$filter` | Traer todo y filtrar client-side |

---

## 3. Librería interna del proyecto

`scripts/setup/lib/dataverse.ps1` encapsula todo lo anterior. Es la primera y por ahora única dependencia interna del proyecto.

### Funciones exportadas

| Función | Para qué |
|---|---|
| `Initialize-DataverseSession` | Verificar Az.Accounts cargado y sesión activa |
| `Get-DataverseToken -Environment <dev/qa>` | Obtener bearer token |
| `Invoke-DataverseApi -Environment <e> -Method <m> -Path <p> [-Body] [-PreferReturn] [-SolutionUniqueName]` | Wrapper genérico Web API |
| `Get-DataverseBusinessUnit -Name <n>` | Buscar BU por nombre |
| `Get-DataverseRootBusinessUnit` | BU raíz del environment |
| `New-LocalizedLabel -Text <t>` | Construir objeto `LocalizedLabel` para metadata |
| `Get-DataverseGlobalOptionSet -Name <n>` | Buscar choice set |
| `Get-DataverseEntity -LogicalName <n>` | Buscar tabla |
| `Get-DataverseAttribute -EntityLogicalName <e> -AttributeLogicalName <a>` | Buscar columna |
| `Get-DataverseRole -Name <n>` | Buscar Security Role |
| `Get-DataversePrivilegeIdByName -PrivilegeName <p>` | Lookup de privilegeid (cacheado) |
| `Add-DataverseRolePrivileges -RoleId <id> -Privileges <array>` | Aplicar privilegios a un rol |

### Patrón de idempotencia

Cada Get-* devuelve `$null` si el artefacto no existe (detectando 404 y variantes). Los scripts hacen check-then-create, así re-correr el script no rompe ni duplica.

---

## 4. DLLs .NET bundled con PAC (NO usadas pero referenciables)

Localización: `%LOCALAPPDATA%\Microsoft\PowerAppsCLI\Microsoft.PowerApps.CLI.<version>\tools\`

**Probé cargarlas con `Add-Type` para evitar instalar Az.Accounts pero fallaron** por binding redirects (Microsoft.Bcl.AsyncInterfaces v10.0.0.7 not resolved). PAC las usa internamente con su propio assembly resolver.

Si en el futuro alguien quiere intentar el approach DLL-loading:

| DLL | Para qué |
|---|---|
| `Microsoft.PowerPlatform.Dataverse.Client.dll` | ServiceClient — wrapper de alto nivel |
| `Microsoft.Xrm.Sdk.dll` | Modelo de datos clásico (Entity, etc.) |
| `Microsoft.Identity.Client.dll` | MSAL para tokens |
| `Microsoft.Graph.dll` | Microsoft Graph para Entra ID operations |
| `Newtonsoft.Json.dll` | JSON serialization |

Workaround si se quiere usar: hacer un loader que registre `AppDomain.CurrentDomain.AssemblyResolve` para resolver dependencias desde el mismo folder.

---

## 5. Herramientas que NO usamos pero existen

Listadas por completitud. Considerar si la complejidad del proyecto crece.

| Herramienta | Para qué | Por qué no la usamos |
|---|---|---|
| **Microsoft.PowerApps.PowerShell** module | Gestión de apps/flows a alto nivel | Funcionalidad limitada vs Web API directo |
| **Microsoft.PowerApps.Administration.PowerShell** module | Operaciones admin (gobernanza, DLP) | No requerimos aún |
| **Microsoft.Xrm.Tooling.CrmConnector.PowerShell** | Conector clásico Dataverse (deprecated pero funcional) | Az.Accounts es más moderno y mejor mantenido |
| **XrmToolBox** | Suite gráfica de herramientas para Dataverse | Excelente para devs pero no automatizable. Útil para inspección visual |
| **Power Platform Pipelines** (Microsoft service) | CI/CD intra-tenant nativo | Cross-tenant (DEV/QA en GTC → PROD cliente) complica su uso. Usamos GitHub Actions |
| **Power Platform Build Tools** (Azure DevOps tasks) | Tareas pre-empaquetadas para AzDO pipelines | Estamos en GitHub Actions; usamos `microsoft/powerplatform-actions` |
| **Power Apps Test Engine** | Tests automatizados de Canvas | Evaluar en S0-9 (issue #20) |
| **Power Apps Test Studio** | Tests visuales Canvas | Decisión en S0-9 — recomendación: probablemente no |
| **Microsoft Power Apps CoE Starter Kit** | Center of Excellence dashboards | Para gobierno multi-app, no aplica a INNOVA single-app |

---

## 6. GitHub Actions oficiales para Power Platform

Disponibles en `microsoft/powerplatform-actions` para usar en `.github/workflows/`.

| Action | Para qué | Lo planeamos usar en |
|---|---|---|
| `actions-install` | Instalar PAC CLI en el runner | S0-6 CI/CD |
| `who-am-i` | Verificar auth | S0-6 CI/CD |
| `solution-pack` | Empaquetar solution | S0-6 |
| `solution-unpack` | Desempaquetar | S0-6 |
| `import-solution` | Importar solution con `--settings-file` | S0-6 (auto-deploy a QA) |
| `export-solution` | Exportar de un env | S0-6 (export tras change) |
| `solution-checker` | Validar solution contra catálogo Microsoft | S0-6 (gate de calidad) |
| `branch-solution` | Crear branch a partir de export | (futuro) |
| `pack-canvas-app` / `unpack-canvas-app` | Canvas en YAML | M2+ cuando empecemos canvas |

---

## 7. Microsoft Graph (para Entra ID — S0-5 próximo)

Para crear App Registrations y configurar Service Principals programáticamente, usaremos Microsoft Graph (vía Az PowerShell o Microsoft.Graph SDK).

**Endpoints clave que usaremos en S0-5**:
- `POST /applications` — crear App Registration
- `POST /servicePrincipals` — registrar SP
- `POST /applications/{id}/addPassword` — generar secret (rotable)

**Por ahora no implementado** — espera a issue #16.

---

## 8. Tokens y Auth: cómo fluye

```
Usuario humano (randall@gtc-cr.com)
   │
   │ 1. Connect-AzAccount -UseDeviceAuthentication
   │    (abre login.microsoft.com/device en navegador)
   ▼
Az PowerShell store (perfil local de usuario)
   │
   │ 2. Get-AzAccessToken -ResourceUrl "https://org93905a7d.crm.dynamics.com/"
   ▼
Bearer token (vida ~1 hora)
   │
   │ 3. Authorization header en Invoke-RestMethod
   ▼
Dataverse Web API
   │
   │ 4. Operación (Create role, POST metadata, etc.)
   ▼
INNOVA-DEV environment
```

Para Service Principal (S0-5), el flujo sustituye el paso 1 con `Connect-AzAccount -ServicePrincipal -Credential <pscred> -Tenant <id>` — no interactivo, ideal para CI/CD.

---

## 9. Convenciones para extender la lib

Si necesitas agregar funciones a `scripts/setup/lib/dataverse.ps1`:

1. Usar nombres con verbos PowerShell estándar (`Get-`, `New-`, `Add-`, `Remove-`)
2. Parámetros obligatorios con `[Parameter(Mandatory)]`
3. Get-* devuelve `$null` si no existe, no lanza excepción
4. Cachear lookups frecuentes (ver `Get-DataversePrivilegeIdByName`)
5. Manejar errores 404 con la lista de patrones que ya tenemos
6. Comentario `.SYNOPSIS` y `.PARAMETER` para que `Get-Help` funcione

---

## 10. Referencias oficiales

- [Dataverse Web API Reference](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/reference/about)
- [PAC CLI Reference](https://learn.microsoft.com/power-platform/developer/cli/reference/)
- [Az PowerShell Get-AzAccessToken](https://learn.microsoft.com/powershell/module/az.accounts/get-azaccesstoken)
- [Microsoft.Dynamics.CRM Metadata Types](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/reference/entitymetadata)
- [Security Roles via Web API](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/security-with-webapi)
- [Power Platform Build Tools](https://learn.microsoft.com/power-platform/alm/devops-build-tools)
- [microsoft/powerplatform-actions](https://github.com/microsoft/powerplatform-actions)
