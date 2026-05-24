# Validación de cambios — INNOVA

> **Versión**: 1.0
> **Aplica a**: todo el repo
> **Cargo**: cualquier contribuidor antes de commit + CI en cada PR

INNOVA usa dos capas de validación para asegurar calidad antes que el código llegue a main:

1. **Pre-commit hook** (local, rápido — < 5s): validaciones básicas sobre los archivos staged
2. **CI workflow** (GitHub Actions, en cada PR/push a main): validaciones completas sobre todo el repo

Ambas capas usan el mismo orquestador `scripts/validate/run-validators.ps1`.

## Setup inicial (una sola vez por clone del repo)

Tras clonar el repo, ejecutar:

```powershell
pwsh -File .githooks/install.ps1
```

Esto configura `git config core.hooksPath .githooks` (scope local del repo). De ahora en adelante, cada `git commit` ejecutará automáticamente las validaciones sobre los archivos staged.

**Verificar**:

```powershell
git config core.hooksPath   # debe imprimir: .githooks
```

## Validadores incluidos

### 1. PowerShell syntax

Parsea cada `.ps1` / `.psm1` modificado con `System.Management.Automation.Language.Parser` y reporta errores de sintaxis. **No ejecuta el script**, solo lo parsea.

**Falla con**: ERROR (bloquea el commit).

### 2. JSON validity

Valida que cada `.json` modificado parse correctamente.

**Falla con**: ERROR.

### 3. Secret detection

Patrones regex que buscan posibles secretos commiteados:

| Patrón | Ejemplo |
|---|---|
| `client_secret = "..."` con valor de 20+ chars | App Registration secrets |
| Connection strings SQL con `Password=` | Cadenas embebidas |
| `-----BEGIN PRIVATE KEY-----` | Llaves privadas |
| Azure SAS tokens (`sv=...&sig=...`) | URLs firmadas |
| GitHub PATs (`ghp_...`) | Tokens de acceso personal |

**Whitelist de placeholders** que evita falsos positivos: `***`, `REPLACE_ME`, `YOUR_`, `EXAMPLE_`, `PLACEHOLDER`, `<...>`, `${...}`, `xxxxxxx...`.

**Falla con**: ERROR.

### 4. Convenciones del proyecto

- Scripts en `scripts/setup/NN-*.ps1` deben cargar `lib/dataverse.ps1` (consistencia con la librería helper). Si el script no usa Web API es OK ignorar la warning.
- `TODO` / `FIXME` / `XXX` / `HACK` sin número de issue `#nnn` — warn para forzar tracking en el backlog.
- Schema names `pas_*` con camelCase tras el prefijo (`pas_NombreCorto`) — warn porque INNOVA usa snake_case lowercase para LogicalName.
- Archivos sensibles que **NUNCA** deben commitearse: `.pfx`, `.pem`, `.key`, `.env`, `appsettings.local.json` — ERROR.

**Falla con**: ERROR para archivos sensibles, WARN para el resto.

## Uso manual

### Validar todo el repo (lo mismo que CI)

```powershell
pwsh -File scripts/validate/run-validators.ps1 -AllFiles
```

### Validar archivos específicos

```powershell
pwsh -File scripts/validate/run-validators.ps1 -StagedFiles "scripts/setup/03-create-tables.ps1`ndocs/glossary.md"
```

## Bypass en emergencia

Si tienes que commitear con el hook fallando (raro, justificable):

```bash
git commit --no-verify -m "msg"
```

**Reglas**:
- Solo usar si es realmente urgente
- Documentar la razón en el body del commit
- Abrir issue de seguimiento para arreglar el problema bypaseado

## CI workflow

`.github/workflows/ci.yml` tiene un job `validate-scripts` que corre sobre `ubuntu-latest` con `pwsh`:

```yaml
- name: Run INNOVA validators (full repo scan)
  shell: pwsh
  run: pwsh -NoProfile -NonInteractive -File scripts/validate/run-validators.ps1 -AllFiles
```

Si falla, el PR se marca con check rojo y queda bloqueado para merge (configurable en repo settings → branches → main protection rules).

## Cuándo agregar un nuevo validador

Si encuentras un tipo de error recurrente que se podría detectar automáticamente:

1. Agregar la función `Test-XYZ` al final del archivo `scripts/validate/run-validators.ps1`
2. Llamarla en el bloque de "Ejecución"
3. Decidir si es ERROR (bloquea) o WARN (solo informa)
4. Agregar caso de prueba: archivo intencionalmente roto + verificar que el validador lo atrape
5. Documentar aquí

## Limitaciones conocidas

- **PSScriptAnalyzer no está integrado** todavía. Si quieres reglas más estrictas (uso correcto de cmdlets, prefer foreach over `%`, etc.), se puede agregar como validador #5 con `Install-Module PSScriptAnalyzer` en el job de CI.
- **Markdown lint** no incluido (links rotos, headings mal formateados). Issue separado para evaluar `markdownlint-cli` o `lychee`.
- **Smoke tests contra Dataverse DEV** no se corren en pre-commit ni CI (requieren service principal, scope mayor). Plan separado en S0-9 (#20).

## Referencias

- Script orquestador: [`scripts/validate/run-validators.ps1`](../../scripts/validate/run-validators.ps1)
- Hook: [`.githooks/pre-commit`](../../.githooks/pre-commit)
- Instalador: [`.githooks/install.ps1`](../../.githooks/install.ps1)
- CI: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) job `validate-scripts`
