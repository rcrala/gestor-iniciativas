# Solution: innova-canvas

Contiene las Canvas Apps de INNOVA. Eventualmente albergará todas las pantallas:

- Pantalla de Inicio personalizada por rol
- Pantalla #1 Solicitante (M2)
- Pantalla #2 PMO Evaluación (M3)
- Pantalla #3 TI (M4)
- Pantallas #4 y #6 Jefatura (M5, M7)
- Pantalla #5 PMO Ejecución (M6)
- Pantalla #7 Cotizaciones (M8)
- Pantalla #8 Gerencia (M9)
- Pantalla del Comité (M10)
- Pantalla "Mis Solicitudes" tracking (M12)
- Pantalla Administrador (M11)

Componentes compartidos (header, navegación, cards de indicadores) vivirán en `Component` library dentro de la app principal.

## Apps versionadas hoy

| Carpeta | App en DEV | Estado | Issue |
|---|---|---|---|
| `referencia-patrones/` | `INNOVA - Patrones Power Fx [REFERENCIA]` | Bootstrap vacío (Screen1 only) | #18 (S0-7) |

## Formato y workflow

Cada app vive en una subcarpeta como **YAML desempaquetado** producido por `pac canvas download --extract-to-directory`. La estructura típica:

```
referencia-patrones/
├── Header.json
├── Properties.json
├── References/        # DataSources, Themes, Templates, Resources
├── Resources/         # PublishInfo
├── Controls/          # JSON por pantalla (1.json, 4.json, etc.)
└── Src/               # YAML legible (App.pa.yaml, ScreenN.pa.yaml)
```

### Workflow actual (formato YAML está en **Preview**)

⚠️ El formato `.pa.yaml` está marcado `(Preview)` por Microsoft. El round-trip standalone `download → editar YAML → pack → import` **falla con FormatException** hoy. Hasta que pase a GA, usar este workflow:

#### Para editar una app

1. Abrir Studio: `https://make.powerapps.com` → la app → Edit
2. Hacer cambios en el portal
3. Save
4. Descargar para versionar:
   ```powershell
   $pac = "$env:LOCALAPPDATA\Microsoft\PowerAppsCLI\pac.cmd"
   Remove-Item -Recurse -Force .work/canvas-download -ErrorAction SilentlyContinue
   & $pac canvas download --name "INNOVA - <Nombre>" --extract-to-directory ".work/canvas-download"
   # Reemplazar la carpeta versionada (excluyendo archivos transientes)
   Remove-Item -Recurse -Force solutions/innova-canvas/<subcarpeta>/* -Force
   Copy-Item -Recurse .work/canvas-download/* solutions/innova-canvas/<subcarpeta>/
   Remove-Item -Force solutions/innova-canvas/<subcarpeta>/Src/_EditorState.pa.yaml -ErrorAction SilentlyContinue
   Remove-Item -Force solutions/innova-canvas/<subcarpeta>/AppCheckerResult.sarif -ErrorAction SilentlyContinue
   ```
5. Commit del diff

#### Para deployar entre environments

Usar `pac solution export/import` (el path que SÍ es estable):

```powershell
# En DEV (origen)
& $pac auth select --name innova-dev
& $pac solution export --name innova_canvas --path ./exported/innova-canvas.zip

# En QA o PROD-cliente (destino)
& $pac auth select --name innova-qa
& $pac solution import --path ./exported/innova-canvas.zip
```

El solution export incluye la app completa con su `.msapp` válido (no en formato YAML preview).

### Archivos que NO se versionan

Por convención (ver `.gitignore`):

- `**/Src/_EditorState.pa.yaml` — orden de pantallas del editor; cambia con cada save sin afectar comportamiento
- `**/AppCheckerResult.sarif` — output del validador de accesibilidad, regenerable
- `.work/canvas-download/` — área de trabajo temporal para el download

## Cuándo el round-trip YAML pase a GA

Estaremos pendientes de Microsoft. Cuando `pac canvas pack` deje de estar en Preview y el round-trip funcione confiablemente, este README cambia para usar pack/unpack standalone.

## Referencias

- Convenciones Power Fx: [`docs/conventions/power-fx-style.md`](../../docs/conventions/power-fx-style.md)
- Patrones Power Fx canónicos: [`docs/conventions/power-fx-patterns.md`](../../docs/conventions/power-fx-patterns.md)
- Documentación oficial schema YAML: https://go.microsoft.com/fwlink/?linkid=2304907
