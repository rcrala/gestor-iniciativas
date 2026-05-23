# M7 — Pantalla Jefatura — Validación de ejecución (#6)

> **Pantalla**: #6 del análisis funcional
> **Tablas principales**: `pas_iniciativa`
> **Stream**: `canvas` + `flows`

## Objetivo de negocio

Permitir a la Jefatura del Solicitante validar que lo ejecutado por PMO corresponde con lo aprobado, y decidir si pasa a la siguiente aprobación (Gerencia General o Comité según monto).

## Historias de usuario (issues GitHub)

### M7-H1 — Pantalla Jefatura Validación: bandeja

| Campo | Contenido |
|---|---|
| **Objetivo** | La Jefatura ve iniciativas en estado "Pendiente Validación Jefatura" de su BU |
| **Alcance** | Canvas analógo a M5-H1 pero con filtro de estado distinto |
| **Criterios de aceptación** | Igual que M5-H1 ajustando estado |
| **Validaciones** | Smoke test |
| **Riesgos** | Mismo que M5 |
| **Labels** | `activity`, `p1`, `canvas` |

### M7-H2 — Pantalla Jefatura Validación: aprobar o devolver con comentario

| Campo | Contenido |
|---|---|
| **Objetivo** | Capturar decisión: Validar (pasa a siguiente aprobador) o Devolver al PMO con comentarios |
| **Alcance** | Canvas con sección decisión + comentarios. Vista completa de avances y entregables |
| **Criterios de aceptación** | (1) Decisiones funcionan. (2) Comentario obligatorio si devuelve |
| **Validaciones** | Test ambos caminos |
| **Riesgos** | Devoluciones repetidas. Mitigación: contador + alerta |
| **Labels** | `activity`, `p1`, `canvas` |

### M7-H3 — Flow: routing post-validación Jefatura

| Campo | Contenido |
|---|---|
| **Objetivo** | Si Validada → escalar según umbral; si Devuelta → vuelve al PMO Ejecución |
| **Alcance** | Flow Update sobre `pas_iniciativa`. Comparar monto contra parámetro "Umbral Escalamiento". Si monto ≤ umbral → "Pendiente Gerencia General"; si > umbral o multi-empresa → "Pendiente Comité" |
| **Criterios de aceptación** | (1) Routing correcto en los 3 casos (Gerencia / Comité / Devolver). (2) Notificación al actor correcto |
| **Validaciones** | Test con 3 montos (debajo, igual, sobre el umbral). Test multi-empresa |
| **Riesgos** | Cambios en el umbral por parámetro. Mitigación: leer parámetro al momento del routing, no cachear |
| **Labels** | `activity`, `p1`, `flows` |

## Tablas Dataverse tocadas

- `pas_iniciativa` (Update)
- `pas_parametro` (Read: umbral, definición multi-empresa)

## Flows requeridos

- `INNOVA - Validacion Jefatura - Routing`
- `INNOVA - Validacion Jefatura - Devolver a PMO`

## Dependencias previas

- M6 cerrado
- Parámetros del sistema configurados (umbral, criterio multi-empresa)

## Criterios de aceptación globales del módulo

- Jefatura valida la ejecución en menos de 5 min
- Routing correcto según monto y multi-empresa
- Devoluciones trazables

## Riesgos

- Definición ambigua de "multi-empresa". Mitigación: regla explícita: "involucra más de 1 BU" basada en colaboradores o presupuesto compartido
- Umbral cambia en producción y rompe estado en flight. Mitigación: evaluación al momento de transición, no en creación

## Definition of Done

- 3 historias cerradas
- Solutions exportadas
- Runbook
- Tests
- Demo
