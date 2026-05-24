# Runbook 01 — Crear / mantener Business Units

> **Para qué**: Provisionar las Business Units de INNOVA en un environment nuevo (DEV/QA), o agregar/renombrar/quitar BUs en un environment existente sin redeploy.
> **Issue origen**: #13 (S0-2)
> **ADR**: [`0003-arquitectura-multi-empresa.md`](../decisions/0003-arquitectura-multi-empresa.md)

## Concepto

INNOVA usa **Business Units (BU)** de Dataverse para aislar datos por empresa del Grupo Pasquí. Estructura:

```
Root BU del environment (ej: org93905a7d)
├── Empresa A          ← placeholder, renombrar
├── Empresa B          ← placeholder, renombrar
├── Empresa C          ← placeholder, renombrar
└── Comite             ← BU transversal para miembros del Comité de Proyectos
```

Cada `pas_iniciativa` se asocia a la BU de la empresa del Solicitante. Cada `pas_empresa` (tabla) tiene un lookup 1:1 a la BU correspondiente — ver [`data-model.md`](../architecture/data-model.md#pas_empresa--empresas-del-grupo-pasquí).

## Crear las BUs iniciales (provisioning)

### Opción A — Script automatizado (recomendado)

Crea las 4 BUs placeholder en una corrida. Idempotente.

**Prerequisitos**:
- Az.Accounts instalado: `Install-Module Az.Accounts -Scope CurrentUser`
- Sesión activa: `Connect-AzAccount -UseDeviceAuthentication -Subscription <id>`
- Usuario con rol System Administrator en el environment destino

**Dry-run primero**:
```powershell
pwsh ./scripts/setup/01-create-business-units.ps1 -Environment dev -WhatIf
```

**Ejecutar**:
```powershell
pwsh ./scripts/setup/01-create-business-units.ps1 -Environment dev
```

Crea: `Empresa A`, `Empresa B`, `Empresa C`, `Comite` bajo la BU raíz del environment.

Para QA: `-Environment qa`.

### Opción B — Manual via Power Platform Admin Center

1. Ir a [admin.powerplatform.microsoft.com](https://admin.powerplatform.microsoft.com)
2. Environments → INNOVA-DEV → Settings → Users + permissions → Business units
3. Click `+ New` y crear cada una:
   - Name: `Empresa A` / `Empresa B` / `Empresa C` / `Comite`
   - Parent: la BU raíz del environment
   - Description: ver script para textos

## Renombrar una BU placeholder por su nombre real

Cuando el cliente confirme los nombres reales de las empresas (ej: `Pasqui Pinturas`, `Pasqui Quimicos`):

### Via Admin Center

1. admin.powerplatform.microsoft.com → INNOVA-DEV → Business units
2. Click sobre la BU placeholder → Edit
3. Cambiar Name → Save

> **Importante**: el cambio de nombre NO afecta los registros asociados ni rompe iniciativas existentes. Las relaciones lookup persisten por GUID, no por nombre.

### Via Web API (script)

```powershell
. ./scripts/setup/lib/dataverse.ps1
Initialize-DataverseSession | Out-Null

$bu = Get-DataverseBusinessUnit -Environment dev -Name 'Empresa A'
$body = @{ name = 'Pasqui Pinturas' }
Invoke-DataverseApi -Environment dev -Method PATCH -Path "businessunits($($bu.businessunitid))" -Body $body
```

## Agregar una BU nueva

Si en el futuro el Grupo Pasquí incorpora una nueva empresa:

### Via Admin Center

Mismo flujo que Opción B arriba, parent = BU raíz.

### Via script

Editar `scripts/setup/01-create-business-units.ps1`, agregar entrada en `$busToCreate`, ejecutar (idempotente, solo crea las nuevas).

## Quitar una BU (cuidado)

**Antes de borrar una BU debes reasignar todos sus registros** o sus usuarios. Si no, Dataverse rechaza la eliminación.

### Pasos

1. Identificar registros y usuarios asignados a esa BU:
   ```powershell
   . ./scripts/setup/lib/dataverse.ps1
   Initialize-DataverseSession | Out-Null

   $bu = Get-DataverseBusinessUnit -Environment dev -Name 'Empresa C'
   $count = Invoke-DataverseApi -Environment dev -Method GET -Path "systemusers?`$filter=businessunitid eq $($bu.businessunitid)&`$count=true&`$top=0"
   "Usuarios en la BU: $($count.'@odata.count')"
   ```

2. Reasignar usuarios y registros a otra BU (via Admin Center: bulk reassign), o cambiar la BU del usuario.

3. Deshabilitar la BU primero (soft):
   ```powershell
   $body = @{ isdisabled = $true }
   Invoke-DataverseApi -Environment dev -Method PATCH -Path "businessunits($($bu.businessunitid))" -Body $body
   ```

4. Luego eliminar via Admin Center o:
   ```powershell
   Invoke-DataverseApi -Environment dev -Method DELETE -Path "businessunits($($bu.businessunitid))"
   ```

## Validación de aislamiento

Después de crear las BUs y asignar al menos 1 usuario a cada una:

1. Login con usuario en `Empresa A`
2. Crear una iniciativa de prueba
3. Logout
4. Login con usuario en `Empresa B`
5. Verificar que la iniciativa de Empresa A **no es visible**

(Cuando exista M2 — pantalla Solicitante — esto se prueba via la app; mientras tanto, via maker portal viendo `pas_iniciativa`.)

## Estado actual (registro de provisioning)

| Environment | BUs creadas | Fecha | Verificado |
|---|---|---|---|
| DEV (`org93905a7d`) | `Empresa A`, `Empresa B`, `Empresa C`, `Comite` | 2026-05-24 | Idempotencia OK (2da corrida → all skip) |
| QA (`org8b65c4d6`) | — | pendiente | — |
| PROD (cliente) | — | pendiente | Ver [`entrega-cliente.md`](../architecture/entrega-cliente.md) |

## Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `Az.Accounts no instalado` | Module faltante | `Install-Module Az.Accounts -Scope CurrentUser` |
| `No hay sesion Az activa` | No conectado | `Connect-AzAccount -UseDeviceAuthentication -Subscription <id>` |
| `403 Forbidden` al POST businessunits | Usuario sin rol System Administrator | Asignar rol via Admin Center |
| BU creada pero no aparece en dropdown | Cache de Power Apps | Refresh navegador, esperar 1-2 min |
| `Cannot delete business unit because it has...` | Registros asociados | Ver sección "Quitar una BU" |
