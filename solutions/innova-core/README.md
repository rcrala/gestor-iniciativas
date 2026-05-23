# Solution: innova-core

Contiene los artefactos base de INNOVA:

- 11 tablas custom (`pas_iniciativa`, `pas_cotizacion`, `pas_evaluacionpmo`, etc.)
- 12 Choice sets globales
- Relaciones entre tablas
- 7 Security Roles (`pas-solicitante`, `pas-pmo`, etc.)
- Business Units por empresa
- Business Rules sobre `pas_iniciativa`

Esta solution NO contiene flows ni apps. Esos viven en sus solutions dedicadas para mantener separación de concerns y reducir el blast radius de los despliegues.

Ver `docs/architecture/data-model.md` para el detalle del modelo.
