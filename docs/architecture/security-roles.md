# Security Roles — INNOVA

> **Versión**: 1.0 (Sprint 0 — issue #14)
> **Estado**: Diseño aprobado, implementado vía `scripts/setup/05-create-security-roles.ps1`
> **Modelo de datos asociado**: [`data-model.md`](data-model.md)
> **Multi-empresa**: [`docs/decisions/0003-arquitectura-multi-empresa.md`](../decisions/0003-arquitectura-multi-empresa.md)

## Notación

| Scope | Significado |
|---|---|
| **B** | Basic = User. Solo registros propios (donde el usuario es owner) |
| **L** | Local = Business Unit. Registros de la misma BU del usuario |
| **D** | Deep = Parent:Child BU. Registros de la BU propia + BUs hijas |
| **G** | Global = Organization. Todos los registros del environment |
| **—** | Sin privilegio |

Privilegios de Dataverse:
- **C** Create, **R** Read, **W** Write, **D**el Delete
- **Ap** Append (yo puedo ser child de otros), **AT** AppendTo (otros pueden ser child de mí)
- **As** Assign (reasignar owner), **S** Share

## Resumen visual (matriz consolidada)

| Tabla | Solicitante | PMO | TI | Jefatura | Gerencia | Comité | Administrador |
|---|---|---|---|---|---|---|---|
| `pas_iniciativa` | CRW Ap AT B | RW Ap L | RW G | RW L | RW L | R G | R G |
| `pas_evaluacionpmo` | R L | CRWD L Ap | R G | R L | R L | R G | R G |
| `pas_evaluacionti` | R L | R L | CRWD G | R L | R L | R G | R G |
| `pas_cotizacion` | R L | CRWD L | R G | R L | R L | R G | R G |
| `pas_horatrabajo` | R L | CRW L | CRW G | R L | R L | R G | R G |
| `pas_votocomite` | R L | R L | R G | R L | R L | CRW G | R G |
| `pas_documentoadj` | CRW B Ap | CRW L | R G | R L | R L | R G | R G |
| `pas_empresa` | R G | R G | R G | R G | R G | R G | CRWD G |
| `pas_centrocosto` | R G | R G | R G | R G | R G | R G | CRWD G |
| `pas_plantillacorreo` | — | R G | — | — | — | — | CRWD G |
| `pas_parametro` | R G | R G | R G | R G | R G | R G | CRWD G |
| `pas_miembrocomite` | — | R G | — | — | — | R G | CRWD G |

> **Nota sobre Read scope para Solicitante en process tables**: damos R **L** (BU) en lugar de R **B** (solo propios). Razón: el feature "Mis Solicitudes" (M12) necesita que el Solicitante vea registros child (evaluaciones, cotizaciones, etc.) de SUS iniciativas. Estos child records son creados por PMO/TI, no por el Solicitante, así que su owner no coincide. La opción más restrictiva (sharing por registro) tiene overhead operativo grande. Trade-off aceptado: Solicitante de Empresa A puede técnicamente leer evaluaciones de iniciativas de OTROS solicitantes de Empresa A, pero la UI filtra a las propias.

---

## INNOVA Solicitante

**Propósito**: Crea iniciativas, sube documentos de soporte, da seguimiento a sus propias solicitudes vía "Mis Solicitudes" (M12).

**Scope típico**: User (solo propio) en sus creaciones; BU en visualización de child records; Organization en catálogos.

| Tabla | C | R | W | Del | Ap | AT | As | S |
|---|---|---|---|---|---|---|---|---|
| `pas_iniciativa` | B | B | B (solo en Borrador) | — | B | B | B | B |
| `pas_evaluacionpmo` | — | L | — | — | — | — | — | — |
| `pas_evaluacionti` | — | L | — | — | — | — | — | — |
| `pas_cotizacion` | — | L | — | — | — | — | — | — |
| `pas_horatrabajo` | — | L | — | — | — | — | — | — |
| `pas_votocomite` | — | L | — | — | — | — | — | — |
| `pas_documentoadj` | B | B | B | — | B | — | — | — |
| `pas_empresa` | — | G | — | — | — | — | — | — |
| `pas_centrocosto` | — | G | — | — | — | — | — | — |
| `pas_plantillacorreo` | — | — | — | — | — | — | — | — |
| `pas_parametro` | — | G | — | — | — | — | — | — |
| `pas_miembrocomite` | — | — | — | — | — | — | — | — |

**Validaciones funcionales esperadas**:
- Solo puede editar `pas_iniciativa` mientras `pas_estado = Borrador` (BR-17 — implementado en flow/business rule)
- Solo ve iniciativas donde es Solicitante o Patrocinador (filtro de UI en M12)

---

## INNOVA PMO

**Propósito**: Recibe iniciativas, hace levantamiento, lleva ejecución, genera cotizaciones.

**Scope típico**: BU. PMO opera dentro de su empresa asignada.

| Tabla | C | R | W | Del | Ap | AT | As | S |
|---|---|---|---|---|---|---|---|---|
| `pas_iniciativa` | — | L | L | — | L | L | — | — |
| `pas_evaluacionpmo` | L | L | L | L | L | L | — | — |
| `pas_evaluacionti` | — | L | — | — | — | — | — | — |
| `pas_cotizacion` | L | L | L | L | L | L | — | — |
| `pas_horatrabajo` | L | L | L | — | L | — | — | — |
| `pas_votocomite` | — | L | — | — | — | — | — | — |
| `pas_documentoadj` | L | L | L | — | L | — | — | — |
| `pas_empresa` | — | G | — | — | — | — | — | — |
| `pas_centrocosto` | — | G | — | — | — | — | — | — |
| `pas_plantillacorreo` | — | G | — | — | — | — | — | — |
| `pas_parametro` | — | G | — | — | — | — | — | — |
| `pas_miembrocomite` | — | G | — | — | — | — | — | — |

**Notas**:
- Write en `pas_iniciativa` cubre cambios de estado, decisiones, fechas — la app/flow valida que solo cambien los campos apropiados a la fase
- Sin Delete en `pas_iniciativa` ni `pas_horatrabajo`: las iniciativas se cierran/rechazan, no se borran. Horas son auditables

---

## INNOVA TI

**Propósito**: Estima esfuerzo de desarrollo cuando una iniciativa requiere TI. Equipo transversal (cross-BU).

**Scope típico**: Organization (TI no está vinculado a una empresa específica).

| Tabla | C | R | W | Del | Ap | AT | As | S |
|---|---|---|---|---|---|---|---|---|
| `pas_iniciativa` | — | G | G | — | G | G | — | — |
| `pas_evaluacionpmo` | — | G | — | — | — | — | — | — |
| `pas_evaluacionti` | G | G | G | G | G | G | — | — |
| `pas_cotizacion` | — | G | — | — | — | — | — | — |
| `pas_horatrabajo` | G | G | G | — | G | — | — | — |
| `pas_votocomite` | — | G | — | — | — | — | — | — |
| `pas_documentoadj` | — | G | — | — | — | — | — | — |
| `pas_empresa` | — | G | — | — | — | — | — | — |
| `pas_centrocosto` | — | G | — | — | — | — | — | — |
| `pas_plantillacorreo` | — | — | — | — | — | — | — | — |
| `pas_parametro` | — | G | — | — | — | — | — | — |
| `pas_miembrocomite` | — | — | — | — | — | — | — | — |

**Notas**:
- Write en `pas_iniciativa` Organization: TI necesita actualizar campos derivados (monto estimado tras estimar) — limitado por app a esos campos
- Sin Delete en `pas_horatrabajo` (auditable)

---

## INNOVA Jefatura

**Propósito**: Aprueba decisiones en su BU: aprueba estimaciones (M5) y valida ejecución (M7).

**Scope típico**: BU. Jefatura aprueba para su empresa.

| Tabla | C | R | W | Del | Ap | AT | As | S |
|---|---|---|---|---|---|---|---|---|
| `pas_iniciativa` | — | L | L | — | L | L | — | — |
| `pas_evaluacionpmo` | — | L | — | — | — | — | — | — |
| `pas_evaluacionti` | — | L | — | — | — | — | — | — |
| `pas_cotizacion` | — | L | — | — | — | — | — | — |
| `pas_horatrabajo` | — | L | — | — | — | — | — | — |
| `pas_votocomite` | — | L | — | — | — | — | — | — |
| `pas_documentoadj` | — | L | — | — | — | — | — | — |
| `pas_empresa` | — | G | — | — | — | — | — | — |
| `pas_centrocosto` | — | G | — | — | — | — | — | — |
| `pas_plantillacorreo` | — | — | — | — | — | — | — | — |
| `pas_parametro` | — | G | — | — | — | — | — | — |
| `pas_miembrocomite` | — | — | — | — | — | — | — | — |

**Notas**:
- Write en `pas_iniciativa` se restringe vía app a los campos de decisión Jefatura (`pas_decision_jefatura`, `pas_decision_jefatura_comentario`, `pas_prioridad`, `pas_fecha_decision_jefatura`)

---

## INNOVA Gerencia

**Propósito**: Aprueba iniciativas bajo el umbral de escalamiento (M9), dentro de su BU.

**Scope típico**: BU.

| Tabla | C | R | W | Del | Ap | AT | As | S |
|---|---|---|---|---|---|---|---|---|
| `pas_iniciativa` | — | L | L | — | L | L | — | — |
| `pas_evaluacionpmo` | — | L | — | — | — | — | — | — |
| `pas_evaluacionti` | — | L | — | — | — | — | — | — |
| `pas_cotizacion` | — | L | — | — | — | — | — | — |
| `pas_horatrabajo` | — | L | — | — | — | — | — | — |
| `pas_votocomite` | — | L | — | — | — | — | — | — |
| `pas_documentoadj` | — | L | — | — | — | — | — | — |
| `pas_empresa` | — | G | — | — | — | — | — | — |
| `pas_centrocosto` | — | G | — | — | — | — | — | — |
| `pas_plantillacorreo` | — | — | — | — | — | — | — | — |
| `pas_parametro` | — | G | — | — | — | — | — | — |
| `pas_miembrocomite` | — | — | — | — | — | — | — | — |

**Notas**:
- Write en `pas_iniciativa` se restringe vía app a campos de decisión Gerencia

---

## INNOVA Comité

**Propósito**: Vota en iniciativas escaladas (M10) por monto o por ser multi-empresa. Es un cuerpo cross-BU.

**Scope típico**: Organization. El Comité ve iniciativas de cualquier empresa que requieran su voto.

| Tabla | C | R | W | Del | Ap | AT | As | S |
|---|---|---|---|---|---|---|---|---|
| `pas_iniciativa` | — | G | — | — | — | — | — | — |
| `pas_evaluacionpmo` | — | G | — | — | — | — | — | — |
| `pas_evaluacionti` | — | G | — | — | — | — | — | — |
| `pas_cotizacion` | — | G | — | — | — | — | — | — |
| `pas_horatrabajo` | — | G | — | — | — | — | — | — |
| `pas_votocomite` | G | G | G | — | G | — | — | — |
| `pas_documentoadj` | — | G | — | — | — | — | — | — |
| `pas_empresa` | — | G | — | — | — | — | — | — |
| `pas_centrocosto` | — | G | — | — | — | — | — | — |
| `pas_plantillacorreo` | — | — | — | — | — | — | — | — |
| `pas_parametro` | — | G | — | — | — | — | — | — |
| `pas_miembrocomite` | — | G | — | — | — | — | — | — |

**Notas**:
- Solo Read en `pas_iniciativa`: el Comité no edita el registro, solo emite voto
- Write en `pas_votocomite`: para editar su voto en la ventana permitida (BR-7 valida unicidad por miembro+iniciativa)
- Sin Delete: votos son inmutables

---

## INNOVA Administrador

**Propósito**: Gestiona catálogos (M11), monitorea el sistema, atiende soporte L1.

**Scope típico**: Organization. Admin ve todo pero no edita process tables.

| Tabla | C | R | W | Del | Ap | AT | As | S |
|---|---|---|---|---|---|---|---|---|
| `pas_iniciativa` | — | G | — | — | — | — | — | — |
| `pas_evaluacionpmo` | — | G | — | — | — | — | — | — |
| `pas_evaluacionti` | — | G | — | — | — | — | — | — |
| `pas_cotizacion` | — | G | — | — | — | — | — | — |
| `pas_horatrabajo` | — | G | — | — | — | — | — | — |
| `pas_votocomite` | — | G | — | — | — | — | — | — |
| `pas_documentoadj` | — | G | — | — | — | — | — | — |
| `pas_empresa` | G | G | G | G | G | G | — | — |
| `pas_centrocosto` | G | G | G | G | G | G | — | — |
| `pas_plantillacorreo` | G | G | G | G | G | G | — | — |
| `pas_parametro` | G | G | G | G | G | G | — | — |
| `pas_miembrocomite` | G | G | G | G | G | G | — | — |

**Notas**:
- Sin Write en process tables: ayuda a auditoría, evita que admin "corrija" datos en silencio. Si necesita corregir un dato de proceso, requiere `System Administrator` (rol nativo de Dataverse).
- CRUD completo en config tables: ese ES el rol de Administrador funcional.
- **No reemplaza al `System Administrator`** de Dataverse, que sigue siendo necesario para gestión de roles, BUs y schema.

---

## Asignación a usuarios

Cada usuario debe tener AL MENOS un rol INNOVA. Algunos pueden tener varios (ej: un usuario que es PMO pero también Jefatura suplente). Dataverse acumula privilegios — el más permisivo gana por privilegio.

Asignación de BU del usuario:
- **Solicitante / PMO / Jefatura / Gerencia**: asignar a la BU de su empresa (ej: `Empresa A`)
- **TI / Comité / Administrador**: asignar a BU raíz del environment para acceso cross-BU (rol con scope Global ya cubre esto, pero la BU determina ownership de registros creados por ellos)

## Coexistencia con roles nativos

Los roles INNOVA **no reemplazan** roles nativos de Dataverse:
- `System Administrator` — necesario para crear roles, BUs, modificar schema, gestionar SP
- `System Customizer` — para devs/Tech Lead durante desarrollo
- `Basic User` — Dataverse lo asigna automáticamente; no removerlo

Un usuario funcional típico tiene: `Basic User` (nativo) + `INNOVA <su rol>` (custom).

## Privilegios omitidos deliberadamente

- **Assign**: ningún rol custom tiene Assign en process tables. La reasignación de iniciativas es una operación administrativa (System Admin).
- **Share**: tampoco se otorga. Si el negocio lo requiere, evaluar caso por caso vía app.

## Próximos pasos

1. Ejecutar `scripts/setup/05-create-security-roles.ps1` para crear los roles en DEV
2. En #16 (S0-5), el Service Principal recibe rol propio (`INNOVA Service Principal`) con privilegios para Dataverse Web API
3. Crear usuarios de prueba (1 por rol) para validar permisos antes de M2
4. En el cliente: este mismo documento + script aplican igual

## Cambios a esta matriz

Cualquier cambio (agregar privilegios, ampliar scopes) debe:
1. Documentarse aquí con justificación
2. Reflejarse en `scripts/setup/05-create-security-roles.ps1` (definitions hashtable)
3. Re-ejecutarse el script — idempotente: aplica el delta
4. Probarse con un usuario afectado antes de cerrar el PR
