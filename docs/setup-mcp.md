# Setup de Claude Code y MCP en INNOVA

Esta guía cubre cómo dejar funcionando Claude Code con el MCP server `code-review-graph` en una máquina nueva, sin necesidad de editar archivos commiteados (`.mcp.json`, `.claude/settings.json`).

## ¿Qué hay en el repo?

| Archivo | Tracked en git | Para qué |
|---|---|---|
| `.mcp.json` | Sí | Configuración del MCP server compartida por todo el equipo. **No editar localmente** |
| `.claude/settings.json` | Sí | Hooks y permisos del proyecto compartidos por todo el equipo. **No editar localmente** |
| `.claude/settings.local.json` | **No** (gitignored) | Tus permisos y settings personales que sobreescriben los del proyecto |
| `.claude/local/`, `.claude/projects/` | **No** (gitignored) | Estado local de sesiones de Claude Code |

Regla de oro: si necesitas cambios solo-tuyos, ponlos en `.claude/settings.local.json`. Si necesitas cambios para todo el equipo, abre un issue y haz PR a `.claude/settings.json`.

## Prerrequisitos

- Claude Code (CLI, IDE extension, o desktop app) instalado
- Python 3.10+ (para `code-review-graph`, instalable vía pipx)
- Git Bash o WSL (los hooks usan sintaxis Bash)

## Instalar `code-review-graph` (MCP server)

`code-review-graph` es opcional pero recomendado. Sin él, Claude Code funciona pero pierde la capacidad de navegar el grafo de código del repo (más rápido y barato que Grep/Glob para muchas tareas).

### Opción A — Windows nativo

1. Instala Python 3.10+ desde [python.org](https://www.python.org/downloads/) (asegúrate de marcar "Add Python to PATH")
2. Instala pipx:
   ```powershell
   python -m pip install --user pipx
   python -m pipx ensurepath
   ```
   Reinicia la terminal para que tome el PATH actualizado.
3. Instala `code-review-graph`:
   ```powershell
   pipx install code-review-graph
   ```
4. Verifica:
   ```powershell
   code-review-graph --help
   ```

### Opción B — WSL (Ubuntu / Debian)

1. Dentro de WSL:
   ```bash
   sudo apt update && sudo apt install -y python3 python3-pip pipx
   pipx ensurepath
   ```
   Reinicia la terminal.
2. Instala `code-review-graph`:
   ```bash
   pipx install code-review-graph
   ```
3. Verifica:
   ```bash
   code-review-graph --help
   ```

> **Importante**: Si usas WSL para Claude Code pero el repo está en `/mnt/c/...`, todo funciona pero el filesystem es más lento que tener el repo en filesystem nativo de WSL (`~/proyectos/...`).

### Opción C — Sin `code-review-graph` (opcional)

Si decides no instalarlo, Claude Code seguirá funcionando. Los hooks `PostToolUse` y `SessionStart` están escritos defensivamente:

```bash
git rev-parse --git-dir >/dev/null 2>&1 && code-review-graph status --repo . || echo 'Not a git repo or code-review-graph not installed, skipping'
```

Si el comando no existe, el hook imprime el mensaje "skipping" y no rompe la sesión.

## Configurar PAC CLI

PAC CLI (Power Platform CLI) es necesario para trabajar con solutions y exportar/importar metadata.

```powershell
# Windows nativo (via .NET Tool)
dotnet tool install --global Microsoft.PowerApps.CLI.Tool

# o via winget
winget install Microsoft.PowerAppsCLI

# Verificar
pac --version
```

Después, autenticar contra los environments del proyecto:

```powershell
pwsh ./scripts/bootstrap.ps1
```

El bootstrap autentica contra `innova-dev` e `innova-qa` (en el tenant GTC). PROD vive en el tenant del cliente — ver [`docs/architecture/entrega-cliente.md`](architecture/entrega-cliente.md).

## Permisos personales (`settings.local.json`)

Si Claude Code te ofrece dar permiso a un comando específico (ej. una herramienta que sólo tú usas), puedes:

- **Aceptar para esta sesión** → no se persiste
- **Aceptar para este proyecto** → se persiste en `.claude/settings.local.json` (gitignored, OK)

**Nunca** edites `.claude/settings.json` manualmente para añadir tus permisos personales. Si crees que un permiso debería ser para todo el equipo, abre un issue y discutámoslo.

Ejemplo de `.claude/settings.local.json` personal:

```json
{
  "permissions": {
    "allow": [
      "Bash(my-personal-tool:*)"
    ]
  }
}
```

## Validar el setup

Tras clonar el repo y completar los pasos:

```powershell
# 1. Claude Code arranca sin errores
claude

# 2. git diff debe estar limpio
git status
# Expected: working tree clean (excepto archivos gitignored)

# 3. Los hooks ejecutan
# Hacer un Edit cualquiera; en el output del hook PostToolUse debe aparecer
# "code-review-graph update" o el mensaje "skipping" si no lo instalaste

# 4. PAC CLI responde
pac --version
```

Si algo falla, revisa:
- ¿Python y pipx en PATH? (`where python`, `where pipx`)
- ¿`code-review-graph` en PATH? (`where code-review-graph`)
- ¿Estás en una sesión nueva tras instalar? (PATH no se refresca en sesiones existentes)

## FAQ

**¿Por qué la cwd del MCP no está hardcodeada?**
MCP por default usa la cwd desde donde se lanza Claude Code. Como Claude Code se abre en la raíz del proyecto, el MCP server recibe esa cwd automáticamente. No necesita hardcodearla.

**¿Por qué los hooks usan `--repo .`?**
`.` es la cwd actual del proceso del hook, que Claude Code corre en la raíz del proyecto. Funciona en Windows nativo y WSL sin modificación.

**¿Qué pasa si edito accidentalmente `.claude/settings.json`?**
Te aparecerá en `git status`. Revisa la diff con `git diff .claude/settings.json` y decide:
- Si es un cambio personal → muévelo a `.claude/settings.local.json` y revierte con `git checkout .claude/settings.json`
- Si es un cambio para el equipo → abre un issue, branch, PR como cualquier otro cambio

**¿Tengo que instalar `code-review-graph` sí o sí?**
No. Es opcional. Sin él, Claude Code usa Grep/Glob/Read directamente. Más lento y caro pero funcional.
