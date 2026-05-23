# Entrega de INNOVA al tenant del cliente — Guía operativa

> Complemento operativo del [ADR-0004](../decisions/0004-entrega-cliente.md). Este documento detalla **qué se entrega, cómo se entrega y qué provisiona el cliente** para poner INNOVA en producción.

## Responsabilidades

| Actor | Provisiona | Configura | Mantiene |
|---|---|---|---|
| **Nuestro equipo (GTC)** | Solutions managed (ZIP), seed-data script, deployment-settings template, documentación | Versiones, releases, fixes | Soporte L2/L3 según contrato |
| **Cliente (admin Power Platform)** | Environment Dataverse PROD, licencias Power Platform, Service Principal | Connection References, Environment Variables, usuarios y roles | Soporte L1, monitoreo, backups |
| **Cliente (usuarios finales)** | — | — | Uso operativo, reporte de incidencias |

## Prerrequisitos del cliente

Antes del primer import, el cliente debe tener:

### Licencias

- Power Apps (per user o per app) para cada uno de los 7 roles de INNOVA
- Power Automate (incluido con Power Apps, premium si se requieren conectores premium)
- Power BI Pro o Premium (según volumen de usuarios consumidores)
- Microsoft 365 con SharePoint Online

### Environment Dataverse

- Environment Production (no Trial) en su tenant
- Capacity Dataverse suficiente (estimación: 2 GB iniciales, crecimiento 500 MB/año)
- Business Units provisionadas (ver ADR-0003): raíz "Grupo Pasquí", una BU por empresa del Grupo, BU "Comité"

### Service Principal

App Registration en Entra ID con:

- Nombre sugerido: `INNOVA Service Principal`
- Tipo: Single tenant
- Permisos delegados: `https://<tenant>.crm.dynamics.com/.default`
- Application User en Dataverse con rol `System Customizer` + rol custom `INNOVA Service Principal` (creado por el solution)
- Secret rotable cada 12 meses, almacenado en Azure Key Vault del cliente

### SharePoint Online

- Sitio raíz para INNOVA (sugerido: `https://<cliente>.sharepoint.com/sites/innova`)
- Biblioteca `Cotizaciones` con permisos a rol PMO
- Biblioteca `Ejecucion` con permisos a rol PMO + rol Solicitante (read)
- Biblioteca `Documentos_Iniciativa` para adjuntos generales

### Cuentas funcionales

- `pmo@<cliente>.com` (correo institucional para notificaciones PMO)
- `comite@<cliente>.com` (correo institucional para notificaciones Comité)
- `innova-noreply@<cliente>.com` (sender de correos automatizados, opcional)

## Qué entregamos

Cada entrega oficial consta de:

### 1. Solutions Managed (ZIPs)

Generados por GitHub Actions en cada GitHub Release tagueado `v<major>.<minor>.<patch>`:

- `innova-core_<version>_managed.zip` — tablas, columnas, choice sets, security roles, business rules
- `innova-flows_<version>_managed.zip` — flows + connection references
- `innova-canvas_<version>_managed.zip` — canvas apps
- `innova-reports_<version>_managed.zip` — Power BI datasets/reports (cuando aplique)

Orden de import: `innova-core` siempre primero (es prerequisito).

### 2. `deployment-settings.<entorno>.json`

Archivo generado por entrega con los valores específicos del cliente:

```json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "pas_SharePointSiteUrl",
      "Value": "https://cliente.sharepoint.com/sites/innova"
    },
    {
      "SchemaName": "pas_PmoEmail",
      "Value": "pmo@cliente.com"
    },
    {
      "SchemaName": "pas_ComiteEmail",
      "Value": "comite@cliente.com"
    },
    {
      "SchemaName": "pas_TeamsChannelIniciativas",
      "Value": "<team-id>/<channel-id>"
    }
  ],
  "ConnectionReferences": [
    {
      "LogicalName": "cr_innova_dataverse",
      "ConnectionId": "<id-en-cliente>"
    },
    {
      "LogicalName": "cr_innova_outlook",
      "ConnectionId": "<id-en-cliente>"
    },
    {
      "LogicalName": "cr_innova_sharepoint",
      "ConnectionId": "<id-en-cliente>"
    },
    {
      "LogicalName": "cr_innova_teams",
      "ConnectionId": "<id-en-cliente>"
    }
  ]
}
```

> **NO commitear** este archivo con valores reales. Generarlo por entrega y transmitir por canal seguro.

### 3. `seed-data.ps1`

Script PowerShell ejecutado contra el environment del cliente con SU Service Principal. Carga:

- Lista de empresas del Grupo Pasquí (catálogo Choice o tabla)
- Centros de costo iniciales
- Plantillas de correo
- Parámetros del sistema (umbral de escalamiento, tarifas hora, días de recordatorio)
- Miembros del Comité piloto (datos provistos por el cliente, NUNCA hardcodeados)

Idempotente: re-ejecutarlo no duplica registros existentes.

### 4. Runbook de instalación

Este documento + sección específica de instalación paso a paso (abajo).

### 5. Tag de release y checksum

Cada entrega va con su tag `v<x.y.z>` en el repo y los checksums SHA-256 de los ZIPs, para que el cliente verifique integridad.

## Cómo se importa en el cliente

### Paso 1 — Provisionar el environment

Cliente provisiona el environment Dataverse PROD y comparte URL con nosotros. Confirmamos capacidad y licencias.

### Paso 2 — Crear Business Units

Aplicar ADR-0003: raíz Grupo Pasquí + BUs por empresa + BU Comité. Documentar en sesión guiada.

### Paso 3 — Crear Service Principal y Application User

Cliente crea App Registration y la asocia como Application User en Dataverse. Asigna rol `System Customizer` temporalmente para permitir el import.

### Paso 4 — Importar solutions en orden

```powershell
# Con auth del SP del cliente
pac auth create --name innova-prod-cliente `
                --tenant <tenant-id> `
                --applicationId <client-id> `
                --clientSecret <secret> `
                --environment <url-prod-cliente>

pac auth select --name innova-prod-cliente

# 1. Core (siempre primero)
pac solution import --path innova-core_v1.0.0_managed.zip `
                    --settings-file deployment-settings.prod.json

# 2. Flows
pac solution import --path innova-flows_v1.0.0_managed.zip `
                    --settings-file deployment-settings.prod.json

# 3. Canvas
pac solution import --path innova-canvas_v1.0.0_managed.zip `
                    --settings-file deployment-settings.prod.json

# 4. Reports
pac solution import --path innova-reports_v1.0.0_managed.zip `
                    --settings-file deployment-settings.prod.json
```

### Paso 5 — Vincular Connection References

En el maker portal: Solutions → INNOVA Core → Connection References. Para cada una, vincular a una conexión real del cliente (Outlook, SharePoint, Teams, Dataverse).

Validar que las conexiones usen credenciales de cuentas funcionales (`pmo@<cliente>.com`, etc.), NO cuentas personales.

### Paso 6 — Ejecutar seed-data

```powershell
pwsh ./scripts/seed-data.ps1 -EnvironmentUrl <url-prod-cliente> `
                              -ServicePrincipalId <client-id> `
                              -ServicePrincipalSecret <secret>
```

Verificar que los registros aparezcan en `pas_centrocosto`, `pas_parametro`, `pas_plantillacorreo`, `pas_miembrocomite`.

### Paso 7 — Reducir permisos del SP

Reemplazar `System Customizer` por rol custom `INNOVA Service Principal` (mínimos privilegios, creado por el solution).

### Paso 8 — Asignar usuarios a security roles

Asignar a los usuarios finales del cliente sus roles INNOVA:

- `INNOVA Solicitante` — usuarios del negocio
- `INNOVA PMO` — equipo PMO
- `INNOVA TI` — equipo TI
- `INNOVA Jefatura` — supervisores/gerentes de área
- `INNOVA Gerencia` — gerencia general
- `INNOVA Comite` — miembros del Comité
- `INNOVA Administrador` — admin del sistema

### Paso 9 — Smoke tests post-import

Checklist en `tests/smoke-prod.md`:

- [ ] Solicitante puede abrir la app
- [ ] Crear una iniciativa de prueba (consecutivo se genera)
- [ ] Flow "Iniciativa Creada → Notificar PMO" envía correo
- [ ] PMO recibe la notificación y puede abrir la iniciativa
- [ ] Connection References muestran "OK" (no broken)
- [ ] Dashboard Power BI carga datos

### Paso 10 — Aceptación firmada

Cliente firma documento de aceptación. INNOVA está en PROD.

## Rollback

Si el import falla o introduce defectos críticos:

```powershell
# Desinstalar el solution problemático (en orden inverso al import)
pac solution delete --solution-name innova_reports
pac solution delete --solution-name innova_canvas
pac solution delete --solution-name innova_flows
pac solution delete --solution-name innova_core   # solo si hay que tirar todo
```

Importar la versión previa estable. Los datos en tablas custom se preservan si no se borra `innova_core`. Si se borra, requiere restore desde backup Dataverse del cliente (su responsabilidad).

## Updates posteriores

Para releases siguientes (v1.1, v1.2, etc.):

1. Cliente descarga el nuevo ZIP desde el GitHub Release
2. Descarga el nuevo `deployment-settings.prod.json` (puede tener nuevas variables)
3. Ejecuta `pac solution import --upgrade` (no `--import` directo)
4. Ejecuta `seed-data.ps1` si la release lo requiere
5. Smoke test

Cambios destructivos (drops de columnas, renames críticos) requieren coordinación previa y posiblemente intervención manual. Documentar en el changelog de cada release.

## Inventario de Environment Variables

Lista exhaustiva que vive en `innova-core`. Cada variable tiene tipo, descripción y valor por defecto (cuando aplica).

| Schema name | Tipo | Descripción | Default DEV/QA |
|---|---|---|---|
| `pas_SharePointSiteUrl` | Text | URL base del sitio SharePoint de INNOVA | `https://gtc.sharepoint.com/sites/innova-dev` |
| `pas_PmoEmail` | Text | Correo institucional del PMO para notificaciones | `pmo-dev@gtc-cr.com` |
| `pas_ComiteEmail` | Text | Correo institucional del Comité | `comite-dev@gtc-cr.com` |
| `pas_TeamsChannelIniciativas` | Text | `<teamId>/<channelId>` para notificaciones Teams | (vacío en DEV, opcional) |
| `pas_DiasRecordatorio` | Number | Días entre recordatorios automáticos | `3` |
| `pas_UmbralEscalamientoComite` | Number | Monto a partir del cual escala a Comité | `5000000` (CRC) |

> Lista vive y se mantiene en este documento + en el solution. Cualquier valor nuevo tenant-specific debe modelarse como Environment Variable, no como parámetro hardcodeado.

## Inventario de Connection References

| Logical name | Conector | Uso |
|---|---|---|
| `cr_innova_dataverse` | Common Data Service (current) | CRUD sobre tablas `pas_*` |
| `cr_innova_outlook` | Office 365 Outlook | Envío de correos |
| `cr_innova_sharepoint` | SharePoint | Subida y descarga de adjuntos |
| `cr_innova_teams` | Microsoft Teams | Notificaciones a canales |
| `cr_innova_office365users` | Office 365 Users | Lookup de manager (Jefatura) |

## Contactos

- **Tech Lead INNOVA (GTC)**: `randall@gtc-cr.com`
- **Admin Power Platform cliente**: `<pendiente, cliente provee>`
- **Patrocinador cliente**: `<pendiente>`
- **Soporte L1 cliente**: `<pendiente>`

## Referencias

- [ADR-0001](../decisions/0001-stack-power-platform.md): Stack Power Platform
- [ADR-0003](../decisions/0003-arquitectura-multi-empresa.md): Business Units
- [ADR-0004](../decisions/0004-entrega-cliente.md): Estrategia de entrega
- [Plan Sprint 0](../plan/sprint-0-bootstrap.md): Bootstrap técnico
- [Plan M14](../plan/modulos/m14-cierre-runbooks-training.md): Cierre y handoff
