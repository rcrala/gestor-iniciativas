# Directriz de Trabajo con GitHub

> Aplicable a cualquier proyecto de software con repositorio GitHub y agentes de IA (Copilot, Claude, Cursor, etc.).
> Estas reglas son **obligatorias** para todo trabajo de desarrollo.

---

## 1. Branch antes de cualquier cambio

- Nunca empezar implementación sobre `dev-cfg`.
- Crear siempre un branch de trabajo primero:
  - Con issue: `issue-<id>-<stream>-<tema-corto>`
  - Sin issue aún: `wip-<yyyymmdd>-<tema-corto>`
- El branch debe crearse desde `dev-cfg` actualizado.
- Todos los cambios quedan aislados en ese branch.

### Ejemplos de nombres

```
issue-42-backend-cursor-pagination
issue-17-frontend-auth-flow
wip-20260519-spike-redis-cache
```

---

## 2. Issue primero, implementación después

- No implementar ninguna actividad sin un issue previo en GitHub.
- Crear **un issue por actividad concreta** con los siguientes campos:

| Campo                         | Contenido                                            |
| ----------------------------- | ---------------------------------------------------- |
| Objetivo                      | Qué se quiere lograr                                 |
| Alcance                       | Qué archivos/módulos toca                            |
| Criterios de aceptación       | Condiciones observables que confirman que está listo |
| Validaciones/tests requeridos | Qué tests deben pasar                                |
| Riesgos                       | Efectos secundarios posibles                         |

- Agregar labels y prioridad cuando aplique.
- Vincular el issue al sprint/plan vigente.

---

## 3. Implementar y validar por issue

- Implementar solo lo definido en el issue.
- Ejecutar las validaciones/tests relevantes para ese issue.
- Si algún test falla, corregirlo en el mismo branch antes de avanzar.
- Marcar el issue como listo para cerrar solo cuando los criterios de aceptación estén cumplidos.

---

## 4. Trazabilidad en commits

Usar mensajes de commit estructurados:

```
<tipo>(<scope>): <resumen corto>

Refs #<número de issue>
[evidencia breve de validación]
```

### Tipos permitidos

| Tipo       | Cuándo usarlo                                 |
| ---------- | --------------------------------------------- |
| `feat`     | Nueva funcionalidad                           |
| `fix`      | Corrección de bug                             |
| `chore`    | Tareas de mantenimiento, configuración        |
| `test`     | Agregar o corregir tests                      |
| `docs`     | Solo documentación                            |
| `refactor` | Reestructuración sin cambio de comportamiento |

### Reglas

- Incluir referencias al issue en el cuerpo: `Refs #123`
- Agregar evidencia breve de validación (ej: `13/13 tests passing`)
- Usar `Closes #123` solo cuando el merge debe cerrar el issue automáticamente

### Ejemplo de commit completo

```
feat(calendar): parametrize SOFT constraints from DB CalendarRule

Refs #38
- SoftEngine_v1/v2/v3 now reads MIN_DAYS_BETWEEN from context.rules
- Falls back to hardcoded constants if DB rules not available
- 13/13 hard_only tests passing · 454/454 scheduled
```

---

## 5. PR, merge y limpieza

### Abrir el PR

- Siempre desde el branch temporal hacia `dev-cfg`.
- La descripción del PR debe incluir:

```markdown
## Resumen técnico

[Qué hace este PR y por qué]

## Issues relacionados

Closes #38
Refs #39, #40

## Evidencia de tests

- test_hard_only.js: 13/13 ✅
- test_soft_s1.js: 454/454 scheduled ✅

## Riesgos

[Efectos colaterales posibles o deuda técnica introducida]
```

### Después del merge

1. Confirmar que los issues vinculados quedaron cerrados.
2. Eliminar el branch temporal (local y remoto):

```bash
git checkout dev-cfg
git pull --ff-only origin dev-cfg
git branch -d issue-38-calendar-mj01-rebase
git push origin --delete issue-38-calendar-mj01-rebase
```

---

## 6. Regla operacional permanente

| Regla                                           | Consecuencia de incumplimiento |
| ----------------------------------------------- | ------------------------------ |
| Sin branch → sin implementación                 | Rollback directo               |
| Sin issue → sin implementación                  | El trabajo no cuenta           |
| Sin tests → no se cierra el issue               | Queda abierto hasta evidencia  |
| Sin PR mergeado y branch limpio → no está hecho | Trabajo incompleto             |

---

## 7. Flujo completo de una tarea

```
1. Actualizar dev-cfg
       ↓
2. Crear GitHub issue con criterios de aceptación
       ↓
3. Crear branch  issue-<id>-<stream>-<topic>  desde dev-cfg
       ↓
4. Implementar solo lo del issue
       ↓
5. Ejecutar tests → si falla, corregir en el mismo branch
       ↓
6. Commit con mensaje estructurado + Refs #<id>
       ↓
7. Abrir PR con evidencia
       ↓
8. Aprobar y mergear a dev-cfg
       ↓
9. Confirmar cierre del issue
       ↓
10. Eliminar branch local y remoto
```

---

## 8. Convenciones de labels en GitHub

| Label                               | Uso                                    |
| ----------------------------------- | -------------------------------------- |
| `activity`                          | Issue de actividad concreta            |
| `bug`                               | Defecto o comportamiento incorrecto    |
| `p0`                                | Prioridad crítica (bloquea producción) |
| `p1`                                | Prioridad alta                         |
| `p2`                                | Prioridad media                        |
| `backend` / `frontend` / `calendar` | Stream al que pertenece                |

---

## 9. Checklist rápido antes de abrir un PR

- [ ] Branch creado desde `main` actualizado
- [ ] Issue existente con criterios de aceptación definidos
- [ ] Implementación acotada al scope del issue
- [ ] Tests relevantes ejecutados y pasando
- [ ] Commits con mensaje estructurado y `Refs #<id>`
- [ ] PR description incluye resumen, issues, evidencia de tests y riesgos
- [ ] Sin archivos temporales ni credenciales en el diff
