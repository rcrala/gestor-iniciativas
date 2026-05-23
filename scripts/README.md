# Scripts

Scripts de utilidad para el desarrollo y operación de INNOVA.

## Inventario

| Script | Propósito |
|---|---|
| `bootstrap.ps1` | Setup inicial del entorno de desarrollo |
| `deploy.ps1` | Despliegue de solutions a un ambiente (pendiente — Sprint 0) |
| `seed-data.ps1` | Carga de datos de catálogos iniciales (pendiente — Sprint 1) |

## Ejecución

Los scripts asumen PowerShell 7+ y se ejecutan desde la raíz del repo:

```powershell
pwsh ./scripts/bootstrap.ps1
```
