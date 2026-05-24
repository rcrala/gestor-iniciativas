# Runbook 03 — Crear / mantener Security Roles de INNOVA

> **Para qué**: Provisionar los 7 Security Roles de INNOVA en un environment nuevo, o aplicar cambios a la matriz de privilegios.
> **Issue origen**: #14 (S0-3)
> **Matriz canónica**: [`docs/architecture/security-roles.md`](../architecture/security-roles.md)

## Concepto

Los 7 roles de INNOVA encapsulan los permisos por tabla y scope para cada función del negocio. Se crean en la BU raíz del environment (Dataverse replica automáticamente a las BUs hijas).

| Rol | Scope típico | Privilegios |
|---|---|---|
| `INNOVA Solicitante` | User (B) en propios, Local en lectura | 19 |
| `INNOVA PMO` | BU (L) en su empresa | 31 |
| `INNOVA TI` | Organization (G), cross-BU | 21 |
| `INNOVA Jefatura` | BU (L) en su empresa | 13 |
| `INNOVA Gerencia` | BU (L) en su empresa | 13 |
| `INNOVA Comité` | Organization (G) | 14 |
| `INNOVA Administrador` | Organization (G), CRUD en catálogos | 37 |

Total: **148 privilegios** distribuidos entre 7 roles y 12 tablas.

## Prerequisitos

- Tablas y choices ya creadas (runbook 02 completado)
- Az.Accounts instalado + `Connect-AzAccount` activo
- Usuario con `System Administrator` en el environment destino

## Crear los 7 roles (provisioning)

### Dry-run

```powershell
pwsh ./scripts/setup/05-create-security-roles.ps1 -Environment dev -WhatIf
```

### Ejecutar

```powershell
pwsh ./scripts/setup/05-create-security-roles.ps1 -Environment dev
```

Para QA: `-Environment qa`.

Tiempo estimado: 30-60 segundos (1 POST de rol + ~20 POST de privilegios por rol).

## Crear/actualizar un solo rol

```powershell
pwsh ./scripts/setup/05-create-security-roles.ps1 -Environment dev -OnlyRole 'INNOVA PMO'
```

Útil para iterar sobre un rol específico tras ajustar la matriz.

## Aplicar cambios a la matriz

Si cambia `docs/architecture/security-roles.md`:

1. Editar el `$roles` hashtable en `scripts/setup/05-create-security-roles.ps1` (sección "Definiciones")
2. Re-ejecutar el script — `AddPrivilegesRole` sobreescribe el depth de cada privilegio (idempotente)
3. Si se RETIRAN privilegios de un rol, usar la API DELETE manualmente o limpiar via maker portal (el script no detecta privilegios a remover, solo a agregar)

## Notación de la matriz en el script

El script usa specs compactos para no escribir 8 entries por tabla:

```
'pas_iniciativa' = 'CRW:B Ap:B AT:B As:B S:B'
```

Significa:
- Create, Read, Write con scope Basic
- Append con scope Basic
- AppendTo con scope Basic
- Assign con scope Basic
- Share con scope Basic

Verbos: `C`, `R`, `W`, `D`, `Ap`, `AT`, `As`, `S`. Scopes: `B`, `L`, `D`, `G`.

Ver `Parse-PrivilegeSpec` en el script para detalles.

## Asignar usuarios a roles

Tras crear los roles, asignar a cada usuario funcional su rol INNOVA correspondiente.

### Via Power Platform Admin Center

1. admin.powerplatform.microsoft.com → INNOVA-DEV → Settings → Users + permissions → Users
2. Click sobre el usuario → Manage roles
3. Marcar el rol INNOVA aplicable + `Basic User` (siempre)

### Via script (futuro — no implementado en S0-3)

Endpoint Web API:
```
POST /systemusers({userId})/systemuserroles_association/$ref
{ "@odata.id": "{webApiUrl}/roles({roleId})" }
```

Se puede automatizar en seed-data o un script aparte si la cantidad de usuarios crece.

## Cambiar BU de un usuario

La BU determina el scope efectivo para roles con privilegios `Local`:

- Solicitante / PMO / Jefatura / Gerencia: asignar a la BU de su empresa (`Empresa A`, etc.)
- TI / Comité / Administrador: asignar a BU raíz (sus privilegios son Global, así que la BU es indiferente para visibilidad, pero los registros que creen tendrán esa BU como owner BU)

Via Admin Center: Users → user → Business Unit → seleccionar.

## Validación post-provisioning

Crear 1 usuario de prueba por rol y verificar:

| Rol | Test esperado |
|---|---|
| Solicitante | Crea iniciativa, ve solo su propia. No puede aprobar |
| PMO (BU Empresa A) | Ve iniciativas de Empresa A. No ve iniciativas de Empresa B |
| TI | Ve iniciativas de todas las empresas. Solo edita estimación TI |
| Jefatura (BU Empresa A) | Aprueba/devuelve iniciativas de Empresa A. No ve B |
| Gerencia (BU Empresa A) | Aprueba bajo umbral de Empresa A |
| Comité | Ve todas las iniciativas escaladas. Vota |
| Administrador | CRUD en catálogos. Solo lee iniciativas |

## Estado actual (registro de provisioning)

| Environment | Roles creados | Fecha | Verificado |
|---|---|---|---|
| DEV (`org93905a7d`) | 7 roles (148 privilegios) | 2026-05-24 | Idempotencia OK |
| QA (`org8b65c4d6`) | — | pendiente | — |
| PROD (cliente) | — | pendiente | Ver [`entrega-cliente.md`](../architecture/entrega-cliente.md) |

## Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `Privilege 'prvXxx' no encontrado` | Tabla aún no existe en el environment | Ejecutar runbook 02 primero. Privileges se crean automáticamente al crear cada tabla |
| `403 Forbidden` al POST roles | Usuario sin `System Administrator` | Asignar rol nativo via Admin Center |
| Usuario no ve registros esperados | BU incorrecta o rol con scope insuficiente | Verificar BU del usuario + scope del privilegio aplicable en `security-roles.md` |
| Privilegio aplicado pero usuario no lo ve en UI | Caché de session | Cerrar y reabrir Power Apps. Esperar ~2 min |
| `AddPrivilegesRole` lento (>10s) | Volumen de privilegios | Normal en primera corrida. Idempotencia rapida en re-corridas |

## Coexistencia con roles nativos

Los 7 roles INNOVA son **complementarios**, no sustitutos, de:

- `Basic User` (nativo, automático)
- `System Administrator` (para Tech Lead / soporte L2-L3 / scripts de provisioning)
- `System Customizer` (para devs durante desarrollo)
- `Service Principal` (S0-5, próximo issue)

## Próximos pasos

- **#21 (S0-10)**: seed-data.ps1 puebla catálogos + crea usuarios de prueba con sus roles asignados
- **#16 (S0-5)**: Service Principal con rol propio `INNOVA Service Principal` para flows
- Validación funcional: 1 usuario test por rol con casos de uso del runbook
