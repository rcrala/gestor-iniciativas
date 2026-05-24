# Runbook: Deploy de un Release al cliente (PROD en tenant cliente)

> **Audiencia**: técnico responsable del cliente (con acceso admin a su tenant Power Platform)
> **Pre-requisitos**: Service Principal creado en el tenant cliente, conexiones de Power Platform autenticadas
> **Tiempo estimado**: 30-60 min en primer deploy; 10-15 min en subsecuentes

## Contexto

INNOVA se entrega via GitHub Releases. Cada Release contiene:

- ZIP **Managed** de cada solution (innova-core, innova-canvas, innova-flows, etc.)
- `deployment-settings.prod.template.json` con placeholders
- `SHA256SUMS.txt` con checksums
- Release notes con cambios desde la versión anterior

**PROD vive en tu tenant**. Nosotros NO tenemos acceso ni hacemos auto-deploy ([ADR-0004](../decisions/0004-entrega-cliente.md)).

## Setup inicial (una sola vez por tenant)

### 1. Service Principal en tu tenant

En Azure Portal:
1. **Microsoft Entra ID → App registrations → + New registration**
   - Nombre: `INNOVA Service Principal`
   - Supported account types: Single tenant
2. **API permissions → + Add → Dynamics CRM → Delegated → user_impersonation → Grant admin consent**
3. **Certificates & secrets → + New client secret** → guardar el valor (no se puede ver de nuevo)
4. Anotar:
   - Application (client) ID
   - Directory (tenant) ID
   - Secret value

En Power Platform Admin Center:
5. **Environments → tu environment PROD → Settings → Users + permissions → Application users → + New app user**
   - Seleccionar la app registrada
   - Asignar Business Unit (root)
   - Security role: `System Customizer` (y posteriormente `INNOVA Administrador` cuando se cree)

### 2. Conexiones en Power Platform

En `make.powerapps.com → Connections → + New connection`, crear:
- Microsoft Dataverse
- Office 365 Outlook
- SharePoint
- Microsoft Teams
- Office 365 Users

Cada una autenticada con la cuenta del cliente. Anotar los `Connection ID` (visibles en la URL al editar la conexión).

## Deploy de una versión

### Para cada Release nuevo

#### Paso 1: Descargar el Release

Ir a https://github.com/rcrala/gestor-iniciativas/releases → tag deseado → descargar:
- `innova-core-X.Y.Z-managed.zip`
- `innova-canvas-X.Y.Z-managed.zip`
- `innova-flows-X.Y.Z-managed.zip`
- `deployment-settings.prod.template.json`
- `SHA256SUMS.txt`

#### Paso 2: Verificar checksums

```powershell
# En Windows PowerShell
foreach ($line in (Get-Content SHA256SUMS.txt)) {
  $parts = $line -split '\s+', 2
  $expected = $parts[0]
  $file = $parts[1].Trim()
  $actual = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
  if ($expected -eq $actual) { Write-Host "OK   $file" -ForegroundColor Green }
  else { Write-Host "FAIL $file (expected $expected, got $actual)" -ForegroundColor Red }
}
```

Si algún checksum falla → **NO continuar**. Descargar de nuevo desde GitHub.

#### Paso 3: Rellenar deployment-settings

Copiar `deployment-settings.prod.template.json` a `deployment-settings.prod.json` y rellenar:

```jsonc
{
  "EnvironmentVariables": [
    {
      "SchemaName": "pas_SharePointSiteUrl",
      "Value": "https://tuempresa.sharepoint.com/sites/INNOVA"
    },
    {
      "SchemaName": "pas_PmoEmail",
      "Value": "pmo@tuempresa.com"
    },
    // ... resto
  ],
  "ConnectionReferences": [
    {
      "LogicalName": "cr_innova_dataverse",
      "ConnectionId": "<el GUID de la conexion creada en Setup paso 2>"
    },
    // ... resto
  ]
}
```

**NO commitear este archivo** — contiene IDs de conexiones específicos a tu tenant.

#### Paso 4: Autenticar PAC contra tu environment

```powershell
pac auth create --name innova-prod-cliente `
  --url https://<tu-org>.crm.dynamics.com `
  --tenant <tu-tenant-id> `
  --applicationId <client-id> `
  --clientSecret <secret-value>

pac auth select --name innova-prod-cliente
pac org who    # verificar conexion
```

#### Paso 5: Importar solutions en orden

**Orden crítico**: core primero (tiene tablas), después canvas (depende de tablas), después flows (depende de tablas y conexiones).

```powershell
pac solution import `
  --path innova-core-1.0.0-managed.zip `
  --settings-file deployment-settings.prod.json `
  --publish-changes

pac solution import `
  --path innova-canvas-1.0.0-managed.zip `
  --settings-file deployment-settings.prod.json `
  --publish-changes

pac solution import `
  --path innova-flows-1.0.0-managed.zip `
  --settings-file deployment-settings.prod.json `
  --publish-changes
```

Cada import tarda 2-10 min. Si alguno falla, capturar el log y reportar al equipo INNOVA.

#### Paso 6: Asignar Security Roles a usuarios reales

En Power Platform Admin Center → environment → Users + permissions → Users:
- Cada usuario que va a usar INNOVA debe tener uno de los 7 roles: `INNOVA Solicitante`, `INNOVA PMO`, `INNOVA TI`, `INNOVA Jefatura`, `INNOVA Gerencia`, `INNOVA Comite`, `INNOVA Administrador`

Ver matriz: [`docs/architecture/security-roles.md`](../architecture/security-roles.md)

#### Paso 7: Sembrar parámetros y catálogos reales

Reemplazar los valores placeholder por los reales del cliente:
- Empresas reales (nombres, códigos cortos, códigos contables) — via la app M11 Admin
- Centros de costo reales
- Departamentos reales por empresa
- Sistemas reales que pueden integrarse
- Miembros del Comité reales (con sus usuarios systemuser)
- Tarifas reales por hora (PMO, Desarrollador)
- Umbral de escalamiento real al Comité

Los placeholders están claramente marcados (`(placeholder)`, dominios `placeholder.local`, etc.) — son fáciles de identificar.

#### Paso 8: Smoke test post-deploy

Ejecutar el smoke test del runbook (cuando exista; ver [`tests/smoke/`](../../tests/smoke/)). Mínimo:
- Un usuario con cada rol puede loguearse
- Crear una iniciativa de prueba como Solicitante
- Notificación al PMO llega por correo
- Dashboard Power BI carga datos

## Rollback

Si un import falla a medio camino o un release tiene un bug crítico:

### Opción A: Re-importar versión anterior

```powershell
pac solution import `
  --path innova-core-1.0.0-managed.zip `
  --settings-file deployment-settings.prod.json `
  --publish-changes
```

Solo funciona si los cambios entre versiones no son destructivos (no eliminan tablas/columnas).

### Opción B: Restore point del environment

En Power Platform Admin Center → environment → Backups + Restore → seleccionar punto previo al deploy → Restore. Esto restaura TODO el environment (no solo INNOVA). Ventana de retención: 7 días en P1.

## Generación de un Release (interno, equipo INNOVA)

Solo lo hace el equipo INNOVA cuando una versión está lista:

```bash
# 1. Asegurar que main está al día y CHANGELOG.md tiene la sección de la nueva versión
git checkout main && git pull

# 2. Crear y empujar tag
git tag -a v1.0.0 -m "INNOVA v1.0.0 - First release to clients"
git push origin v1.0.0
```

GitHub Actions (.github/workflows/release.yml) automáticamente:
- Empaqueta cada solution como Managed
- Genera deployment-settings.prod.template.json
- Calcula SHA256SUMS.txt
- Extrae notas de CHANGELOG.md
- Crea el GitHub Release con todo

Si el tag tiene sufijo (`v1.0.0-beta`), el Release se marca como `prerelease`.

## Diagnóstico de errores comunes

| Error en import | Causa probable | Solución |
|---|---|---|
| `Connection reference not resolved` | El `ConnectionId` en deployment-settings es inválido | Verificar el GUID en Power Apps Maker Portal → Connections |
| `Solution dependency missing` | Importaste canvas o flows antes que core | Reimportar core primero |
| `Environment variable required` | Schema name de la variable en settings no coincide con el de la solution | Revisar `pas_<NombreVariable>` exacto |
| `Permission denied` | El SP del cliente no tiene Security Role | Asignar `System Customizer` al app user |
| `Plugin assembly version conflict` | Solution previa con plugins distintos | Desinstalar la solution vieja primero (cuidado con dependencias) |

## Referencias

- ADR-0004 entrega al cliente: [`docs/decisions/0004-entrega-cliente.md`](../decisions/0004-entrega-cliente.md)
- Estrategia técnica de entrega: [`docs/architecture/entrega-cliente.md`](../architecture/entrega-cliente.md)
- Matriz de roles: [`docs/architecture/security-roles.md`](../architecture/security-roles.md)
- Workflow GitHub Actions de release: [`.github/workflows/release.yml`](../../.github/workflows/release.yml)
