# Convención de Mensajes de Commit

> Esta convención es parte de la [Directriz de Trabajo con GitHub](./github-workflow.md). Si hay diferencia entre ambos, la directriz manda.

## Resumen

Seguimos [Conventional Commits](https://www.conventionalcommits.org/) en inglés con el footer `Refs #<id>` (o `Closes #<id>`) obligatorio.

## Formato

```
<tipo>(<scope>): <descripción corta en presente, imperativo>

[cuerpo opcional con detalle y "por qué"]

Refs #<número de issue>
[evidencia breve de validación]
```

## Tipos y scopes

Ver §4 de [`github-workflow.md`](./github-workflow.md#4-trazabilidad-en-commits) para la tabla completa.

Tipos: `feat`, `fix`, `chore`, `test`, `docs`, `refactor`, `style`, `perf`, `ci`.

Scopes: `core`, `canvas`, `flows`, `reports`, `pcf`, `plugins`, `docs`, `ci`, `m1`-`m14`, `f1`-`f6`.

## Reglas no-negociables

- Descripción en inglés, modo imperativo, sin punto final, máx 72 chars.
- Referencia al issue **obligatoria** en el cuerpo: `Refs #<id>`.
- `Closes #<id>` solo en el commit del PR final que cierra el issue.
- Un commit, un cambio lógico — si hay "y" en la descripción, probablemente son dos commits.

## Ejemplos

```
feat(m2): add pantalla del solicitante with consecutivo generator

Refs #23
- Implements 3 sections: información general, información de iniciativa,
  tabla dinámica de colaboradores
- Smoke test en DEV OK con 5 escenarios
```

```
fix(m7): correct timing of scheduled reminder flow

Refs #58
The reminder flow was running at midnight UTC which is 6 PM in CR.
Changed to run at 14:00 UTC (8 AM CR) per requirements.
```

```
docs(arch): update data model after PMO workshop decisions

Refs #12
```

```
chore(ci): bump pac CLI to latest version

Refs #45
```

## Co-autoría con agentes de IA

Cuando el commit sea generado/asistido por Claude Code u otro agente, incluir como footer adicional:

```
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```
