---
name: Deliver Story INNOVA
description: Ejecuta una historia funcional de INNOVA end-to-end en Power Platform con checklist de arquitectura, convenciones, pruebas y ALM
---

## Deliver Story INNOVA

Usa este workflow cuando el usuario pida implementar una historia funcional en este repositorio.

### Objetivo

Entregar una historia completa sin romper convenciones: Dataverse, Flows, Canvas, pruebas, documentación y changelog.

### Entradas mínimas

- Descripción de historia (rol, necesidad, valor)
- Criterios de aceptación
- Módulo objetivo (`innova-core`, `innova-flows`, `innova-canvas`, `innova-reports`)

Si falta información crítica, pedir aclaración antes de editar.

### Fuentes obligatorias

1. `CLAUDE.md`
2. `docs/architecture/00-overview.md`
3. `docs/decisions/README.md`
4. `docs/conventions/dataverse-naming.md`
5. `docs/conventions/power-fx-style.md`
6. `docs/conventions/power-automate-style.md`
7. `tests/README.md`

### Orden de implementación

1. Validar restricciones arquitectónicas y convenciones.
2. Diseñar/ajustar datos y seguridad en `solutions/innova-core`.
3. Implementar orquestación en `solutions/innova-flows`.
4. Implementar UI y fórmulas en `solutions/innova-canvas`.
5. Ajustar reportes en `solutions/innova-reports` (si aplica).
6. Ejecutar pruebas y registrar evidencia.
7. Actualizar documentación y `CHANGELOG.md`.

### Reglas no negociables

- Prefijo `pas_` en objetos custom Dataverse.
- Etiquetas de UI en español.
- Power Fx multi-statement con `;;` (no `;`).
- No hardcodear tenant IDs, GUIDs, secretos o certificados.
- No trabajar en Default Solution.
- Pedir aprobación antes de agregar nuevas dependencias externas.

### Checklist de aceptación técnica

- Convenciones cumplidas (naming, estilo, seguridad).
- Errores de lint/build/tests revisados en archivos tocados.
- Artefactos de solución exportados/desempaquetados cuando corresponde.
- Docs y changelog actualizados en el mismo cambio.
- Riesgos/limitaciones documentados en la respuesta final.

### Salida esperada al usuario

- Resumen de cambios por módulo.
- Lista de archivos modificados.
- Resultado de validaciones ejecutadas.
- Supuestos o dudas abiertas.
- Siguientes pasos concretos.
