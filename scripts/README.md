# Scripts

Scripts de utilidad para el desarrollo y operación de INNOVA.

## Inventario

| Script | Propósito | Idempotente |
|---|---|---|
| `bootstrap.ps1` | Setup inicial del entorno de desarrollo (PAC CLI, módulos PS, auth profile) | Sí |
| `setup/01-create-business-units.ps1` | Crear Business Units (Empresa A/B/C + Comite) en Dataverse | Sí |
| `setup/02-create-choice-sets.ps1` | Crear los 11 Global Option Sets + sincronizar labels existentes | Sí |
| `setup/03-create-tables.ps1` | Crear las 15 tablas + sus columnas escalares en `innova-core` | Sí |
| `setup/04-create-relationships.ps1` | Crear las 22 relaciones N:1 (lookups) | Sí |
| `setup/05-create-security-roles.ps1` | Crear los 7 Security Roles INNOVA + 189 privilegios | Sí |
| `setup/06-seed-parametros.ps1` | Sembrar 12 parámetros operacionales en `pas_parametro` | Sí |
| `setup/07-seed-catalogos.ps1` | Sembrar catálogos placeholder (empresas, CCs, deptos, sistemas, plantillas, miembros) | Sí |
| `validate/run-validators.ps1` | Orquestador del pre-commit hook + CI (PS syntax, JSON, secrets, naming) | N/A |

## Provisioning end-to-end (DEV vacío)

Ejecutar en orden:

```powershell
# Auth (una vez por sesión)
Connect-AzAccount -UseDeviceAuthentication -Subscription "338026e8-b9a5-4ae4-a01f-60108e52c08e"

# Provisioning
pwsh ./scripts/setup/01-create-business-units.ps1 -Environment dev
pwsh ./scripts/setup/02-create-choice-sets.ps1    -Environment dev
pwsh ./scripts/setup/03-create-tables.ps1         -Environment dev
pwsh ./scripts/setup/04-create-relationships.ps1  -Environment dev
pwsh ./scripts/setup/05-create-security-roles.ps1 -Environment dev

# Seed data
pwsh ./scripts/setup/06-seed-parametros.ps1       -Environment dev
pwsh ./scripts/setup/07-seed-catalogos.ps1        -Environment dev
```

Cada script puede re-ejecutarse sin efectos colaterales (skip si el artefacto existe).

## Convención de seed data placeholder

Todos los datos sembrados por `06-*` y `07-*` son **placeholders identificables**:

| Marcador | Significado |
|---|---|
| Texto contiene `(placeholder)` | Es un dato de prueba a reemplazar por M11 Admin antes de productivo |
| Códigos prefijados (`CC-`, `DEPT-`, `SYS-`) | Patrón claro para distinguir de datos reales |
| Valores numéricos round (`25000`, `5000000`, `10000`) | Indica que vienen de seed, no de configuración del cliente |
| Empresa placeholders `EMA / EMB / EMC` | Códigos cortos de prueba para `pas_codigo_corto` (G7 consecutivo) |
| URL `placeholder.cdn` / `placeholder.local` | Dominios reservados que nunca resuelven |

**Regla en code review**: ningún flow/canvas debe hardcodear estos valores. Siempre via lookup o `pas_parametro`.

## Idempotencia

Todos los scripts siguen el patrón:

1. Query del artefacto por clave única (LogicalName, nombre, código)
2. Si existe → SKIP (default) o UPDATE (con flag `-ForceUpdate`)
3. Si no existe → CREATE

Esto permite:
- Re-ejecutar tras un fallo parcial sin duplicados
- Aplicar deltas (agregar una nueva columna al script y solo se crea esa)
- Provisionar nuevos environments con el mismo código

## Validación pre-commit

Los scripts en `validate/` corren automáticamente vía pre-commit hook (ver `docs/conventions/validation.md`). Para instalar:

```powershell
pwsh -File .githooks/install.ps1
```

## Ejecución manual de validadores

```powershell
# Full scan (todo el repo)
pwsh ./scripts/validate/run-validators.ps1 -AllFiles

# Solo archivos específicos
pwsh ./scripts/validate/run-validators.ps1 -StagedFiles "scripts/setup/07-seed-catalogos.ps1`ndocs/glossary.md"
```

## Troubleshooting

| Síntoma | Causa probable | Fix |
|---|---|---|
| `Az.Accounts no instalado` | Falta módulo PowerShell | `Install-Module Az.Accounts -Scope CurrentUser` |
| `No hay sesion Az activa` | No has hecho `Connect-AzAccount` | Conectar con device auth: `Connect-AzAccount -UseDeviceAuthentication -Subscription <id>` |
| `404 Could not find` en seed | El script de la fase anterior no se ejecutó | Ejecutar `01-*` → `05-*` antes de `06-*`/`07-*` |
| `An undeclared property 'pas_xxx'` | Nombre de navigation property incorrecto | Las nav props de lookups son PascalCase (`pas_Empresa`), no snake_case (`pas_empresa`) |
| `Required field 'PrimaryAttribute' is missing` | Atributo primario sin flag | Verificar `IsPrimaryName = $true` en el script |
