# ADR-0003: Arquitectura multi-empresa con Business Units

- **Status**: Aceptado
- **Fecha**: 2026-05-23
- **Decisores**: Tech Lead, Arquitecto

## Contexto

Grupo Pasquí está conformado por múltiples empresas. Una iniciativa pertenece a una empresa específica, y los aprobadores (Jefatura, Gerencia General) solo deben ver iniciativas de su propia empresa. El Comité de Proyectos, en cambio, ve iniciativas que escalaron por monto + multi-empresa.

Dataverse ofrece dos mecanismos principales para segmentación:

1. **Business Units (BU)** — jerarquía organizacional nativa, con scope de seguridad
2. **Row-Level Security (RLS) vía Security Roles + Field-Level Security**

## Decisión

Usaremos **Business Units** como mecanismo principal de segmentación por empresa, complementado con Security Roles para permisos transversales (Comité, Administrador).

Estructura:

```
Root BU: Grupo Pasquí
├── BU: Empresa A
├── BU: Empresa B
├── BU: Empresa C
└── BU: Comité (transversal, no es una empresa real, agrupa miembros del Comité)
```

Cada Iniciativa se asocia automáticamente a la BU de la empresa del Solicitante en el momento de creación.

## Consecuencias

### Positivas
- Aislamiento de datos nativo y bien documentado
- Performance: Dataverse aplica filtros BU a nivel de query
- Auditoría natural por empresa
- Compatible con jerarquías futuras (sub-empresas, divisiones)

### Negativas
- Mover una iniciativa de empresa requiere reasignar BU (operación administrativa)
- Reportes cross-BU requieren rol con scope "Organization"
- La configuración inicial de BU debe ser cuidadosa (no se pueden eliminar fácilmente)

### Neutrales
- Power BI debe configurar RLS espejo para reportes
- El service principal del proyecto debe tener un rol con scope Organization

## Alternativas consideradas

### Alternativa 1: Solo Security Roles + Row-Level Security
**Por qué no**: Más complejo de mantener, performance inferior para joins, sin scope nativo.

### Alternativa 2: Ambientes Dataverse separados por empresa
**Por qué no**: El costo de licenciamiento se multiplica, la reportería cross-empresa es imposible sin ETL, y el ALM se vuelve inmanejable.
