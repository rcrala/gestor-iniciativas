# Test Plan: [Nombre del artefacto a probar]

> **Tipo**: [flow | canvas | smoke | exploratorio]
> **Artefacto**: `<nombre del flow / pantalla / módulo>`
> **Issue / PR origen**: #N
> **Última ejecución**: YYYY-MM-DD por @usuario
> **Resultado**: ✅ PASS / ❌ FAIL / ⚠️ PARCIAL

## Resumen

Una línea: ¿qué prueba este plan y por qué importa?

## Precondiciones

- Environment: dev | qa | prod-cliente
- Usuario que ejecuta: rol esperado (Solicitante / PMO / Jefatura / etc.)
- Datos necesarios: catálogos sembrados (link a script), iniciativa en estado X, etc.
- Connection References resueltas a: lista de connectors activos

## Casos de prueba

### Caso 1: [Título corto descriptivo]

**Objetivo**: qué validamos

**Pasos**:
1. ...
2. ...
3. ...

**Esperado**:
- Resultado observable 1
- Resultado observable 2
- Side-effect en Dataverse: registro X creado con campo Y = Z

**Evidencia** (al ejecutar):
- Screenshot 1: `tests/_evidence/YYYY-MM-DD-caso1-paso3.png`
- Log del flow: link a run history o copy del run id
- Query OData de verificación: `pas_iniciativas?$filter=...`

**Resultado**: ✅ PASS / ❌ FAIL
**Observaciones**: (solo si FAIL o algo inesperado)

---

### Caso 2: [Edge case / error path]

**Objetivo**: ...

**Pasos**: ...

**Esperado**: ...

**Resultado**: ...

---

## Issues encontradas durante el test

| # | Severidad | Descripción | Issue link |
|---|---|---|---|
| 1 | High/Med/Low | ... | #NN |

## Cobertura

- [ ] Happy path
- [ ] Validación de campos requeridos
- [ ] Validación de permisos por rol (intento de acceso no autorizado)
- [ ] Error path: dato faltante en parámetro
- [ ] Error path: connector falla / timeout
- [ ] Idempotencia (re-ejecutar no duplica ni corrompe)

## Notas

- Cualquier contexto adicional, hipótesis, dependencias rotas, etc.
