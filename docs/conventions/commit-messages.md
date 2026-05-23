# Convención de Mensajes de Commit

Seguimos [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/) en inglés.

## Formato

```
<tipo>(<scope>): <descripción corta en presente, imperativo>

[cuerpo opcional]

[footer opcional]
```

## Tipos

| Tipo | Uso |
|---|---|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `docs` | Solo documentación |
| `style` | Cambios de formato, sin cambio de comportamiento |
| `refactor` | Refactor sin cambio de comportamiento ni nuevo feature |
| `perf` | Mejora de performance |
| `test` | Agregar o corregir pruebas |
| `chore` | Build, deps, configuración |
| `ci` | Cambios al pipeline de CI |

## Scopes recomendados

- `m1` a `m14` para los módulos del WBS
- `f1` a `f6` para fases transversales
- `core`, `flows`, `canvas`, `reports` para solutions
- `pcf`, `plugins` para artefactos custom
- `docs`, `scripts`, `ci`

## Ejemplos

```
feat(m2): add pantalla del solicitante with consecutivo generator

Adds the requester screen with all sections from the specification:
- Información general
- Información de la iniciativa
- Tabla dinámica de colaboradores

Closes #42
```

```
fix(m7): correct timing of scheduled reminder flow

The reminder flow was running at midnight UTC which is 6 PM in CR.
Changed to run at 14:00 UTC (8 AM CR) per requirements.
```

```
docs(arch): update data model after PMO workshop decisions
```

```
chore(ci): bump pac CLI to latest version
```

## Reglas

- Descripción corta en inglés, modo imperativo, sin punto final
- Máximo 72 caracteres en la primera línea
- Cuerpo opcional con detalle, separado por línea en blanco
- Footer para referencias (Closes, Refs, BREAKING CHANGE)
- Un commit, un cambio lógico — si hay que poner "y" en la descripción, probablemente son dos commits
