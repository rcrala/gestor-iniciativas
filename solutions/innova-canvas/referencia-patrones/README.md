# INNOVA - Patrones Power Fx [REFERENCIA]

App de referencia con los patrones canónicos de Power Fx documentados en [`docs/conventions/power-fx-patterns.md`](../../../docs/conventions/power-fx-patterns.md).

## Estado actual

| Atributo | Valor |
|---|---|
| Issue | #18 (S0-7) |
| Environment | INNOVA-DEV |
| Format | Tablet |
| Pantallas | 1 (Screen1, vacía) |
| Última descarga | 2026-05-24 |

**Hoy es solo un esqueleto** — bootstrap creado en el portal. Los patrones documentados se irán adicionando como pantallas comentadas. Para no duplicar trabajo, cuando se construya **M2 (Mis Solicitudes)** los patrones se demostrarán en código real ahí, y esta app puede quedar como esqueleto mínimo o reusarse para los patrones que no aparezcan naturalmente en M2-M14.

## NO MODIFICAR EN PROYECTOS REALES

Esta app es exclusivamente educativa/referencia. No se deploya a QA ni a PROD-cliente. No tiene Connection References ni Environment Variables productivas.

## Cómo actualizar tras editar en el portal

Ver workflow en [`../README.md`](../README.md).

## Patrones documentados

Los 16 patrones del documento están listos para ser implementados en código aquí o (preferiblemente) en M2. Listado resumido:

1. Variable global de usuario y rol
2. Variable de contexto local
3. Collection filtrada
4. Named formulas (`App.Formulas`)
5. `Patch()` con `Defaults()`
6. Manejo de errores con `IfError()`
7. Navegación entre pantallas
8. Formato de fecha CR (`es-CR`)
9. Filtros delegables vs no-delegables
10. Multi-statement con `;;`
11. Validaciones con `IsBlank()` / `IsEmpty()`
12. Lookup de parámetro tipado
13. Filtros encadenados con relación N:1
14. Mostrar/ocultar por rol
15. Patch a tabla puente N:M
16. Tema visual desde `pas_parametro`

Cada uno con snippet copy-paste-ready en el doc.
