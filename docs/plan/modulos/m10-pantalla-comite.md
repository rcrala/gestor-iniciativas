# M10 — Pantalla Comité de Proyectos

> **Pantalla**: dedicada (no numerada en el análisis)
> **Tablas principales**: `pas_votocomite`, `pas_miembrocomite`, `pas_iniciativa`
> **Stream**: `canvas` + `flows`

## Objetivo de negocio

Permitir al Comité de Proyectos votar (unanimidad requerida) sobre iniciativas que escalaron por monto o por ser multi-empresa.

## Historias de usuario (issues GitHub)

### M10-H1 — Pantalla Comité: bandeja de votación

| Campo | Contenido |
|---|---|
| **Objetivo** | Cada miembro del Comité ve iniciativas en estado "Pendiente Comité" y su estado de voto personal |
| **Alcance** | Canvas filtrada por estado. Indicador: "Yo no he votado" / "Yo voté: Aprobar/Rechazar" / "Ya cerrado" |
| **Criterios de aceptación** | (1) Solo miembros del Comité acceden. (2) Estado de voto personal visible. (3) Pueden ver votos de otros solo cuando todos votaron |
| **Validaciones** | Test con 3 usuarios miembros |
| **Riesgos** | Visibilidad temprana de votos influye decisión. Mitigación: ocultar votos hasta unanimidad o vencimiento |
| **Labels** | `activity`, `p0`, `canvas` |

### M10-H2 — Pantalla Comité: registrar voto individual

| Campo | Contenido |
|---|---|
| **Objetivo** | Capturar voto Aprobar/Rechazar con comentario obligatorio. Un voto por miembro por iniciativa |
| **Alcance** | `Patch()` a `pas_votocomite`. Constraint: clave compuesta (miembro + iniciativa) única |
| **Criterios de aceptación** | (1) Solo 1 voto por miembro por iniciativa (no editable después de submit). (2) Comentario requerido |
| **Validaciones** | Test de duplicado debe fallar |
| **Riesgos** | Miembro vota y se arrepiente. Mitigación: ventana de 5 min para editar; después solo Administrador puede modificar |
| **Labels** | `activity`, `p0`, `canvas`, `core` |

### M10-H3 — Flow: consolidar votos Comité → resultado final

| Campo | Contenido |
|---|---|
| **Objetivo** | Cuando todos los miembros votaron, calcular resultado: unanimidad Aprobar → Aprobada; cualquier voto Rechazar → Rechazada |
| **Alcance** | Flow Update sobre `pas_votocomite` que cuenta votos vs miembros activos. Si conteo == miembros activos → calcular y `Patch()` a `pas_iniciativa.estado` con el resultado. Notificar Solicitante + PMO |
| **Criterios de aceptación** | (1) Resultado correcto en los 4 casos (todos Aprobar, todos Rechazar, mixto, falta votar). (2) Cierre se dispara solo cuando aplica |
| **Validaciones** | Test con 3 miembros y 4 escenarios de votos |
| **Riesgos** | Miembro inactivo bloquea cierre. Mitigación: parámetro `dias_max_voto`, después de vencido se considera Abstención = Rechazo o se notifica Administrador |
| **Labels** | `activity`, `p0`, `flows` |

### M10-H4 — Suplentes del Comité

| Campo | Contenido |
|---|---|
| **Objetivo** | Soportar suplencia: si un miembro titular no puede votar en plazo, su suplente puede |
| **Alcance** | Tabla `pas_miembrocomite` con campo `pas_suplente_ref`. Lógica de flow: si titular no vota en X días, habilitar suplente |
| **Criterios de aceptación** | (1) Suplente puede ver y votar tras vencimiento del titular. (2) Voto del suplente cuenta igual que el del titular |
| **Validaciones** | Test escenario titular ausente + suplente vota |
| **Riesgos** | Conflicto si ambos votan. Mitigación: solo se habilita suplente cuando titular no votó, deshabilitar titular al activar suplente |
| **Labels** | `activity`, `p1`, `canvas`, `flows` |

## Tablas Dataverse tocadas

- `pas_votocomite` (Create, Update con ventana)
- `pas_miembrocomite` (Read)
- `pas_iniciativa` (Update: estado final)

## Flows requeridos

- `INNOVA - Comite - Consolidar Votos`
- `INNOVA - Comite - Habilitar Suplente`

## Dependencias previas

- M7 cerrado (escalamiento a Comité posible)
- Lista de miembros del Comité cargada vía seed data o admin

## Criterios de aceptación globales del módulo

- Comité vota con secreto hasta cierre, resultado por unanimidad
- Suplencia funciona sin intervención manual

## Riesgos

- Comité con muchas iniciativas estancadas. Mitigación: dashboard ejecutivo y SLA
- Cambios en composición del Comité durante votación. Mitigación: snapshot de miembros activos al abrir votación

## Definition of Done

- 4 historias cerradas
- Solutions exportadas
- Runbook
- Tests
- Demo con miembros piloto
