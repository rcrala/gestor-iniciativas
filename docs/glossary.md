# Glosario de Dominio — INNOVA

Términos del negocio en orden alfabético. Algunos términos no tienen una traducción limpia al inglés y se mantienen en español tanto en docs como en código.

## Términos de negocio

| Término (ES) | Término (EN) | Definición |
|---|---|---|
| Aprobada | Approved | Estado final positivo de una iniciativa |
| Aprobador | Approver | Usuario con derecho a aprobar (Jefatura, Gerencia, Comité) |
| Centro de costo | Cost Center | Unidad contable a la que se cargan horas e impactos económicos |
| Cerrada | Closed | Estado final, sea Aprobada o Rechazada |
| Cotización | Quote / Quotation | Estimación de costo para ejecutar la iniciativa |
| Cotización ganadora | Winning Quote | Cotización seleccionada para proceder |
| Costo de levantamiento | Discovery Cost | Costo de las horas que el PMO invierte analizando |
| Costo de estimación | Estimation Cost | Costo de las horas que TI invierte estimando |
| Devuelta | Returned | Estado en el cual la iniciativa vuelve al PMO para corrección |
| Ejecución | Execution | Fase donde PMO documenta el trabajo realizado (Pantalla #5) |
| Empresa | Company | Una de las entidades del Grupo Pasquí. Atributo clave de seguridad |
| En Evaluación PMO | Under PMO Review | Estado mientras PMO está analizando |
| En Evaluación TI | Under IT Review | Estado mientras TI está estimando |
| Estimación | Estimation | Horas y costo proyectado |
| Iniciativa | Initiative | Entidad principal. Tabla: `pas_iniciativa` |
| Jefatura | Line Manager | Supervisor directo del Solicitante |
| Levantamiento | Discovery | Fase de análisis del PMO |
| Multi-empresa | Multi-company | Iniciativa que involucra a más de una empresa del Grupo |
| Patrocinador | Sponsor | Ejecutivo que respalda la iniciativa |
| PMO | Project Management Office | Oficina de gestión de proyectos |
| Prioridad | Priority | Asignada al aprobar: P1, P2, P3 |
| Rechazada | Rejected | Estado final negativo |
| Requiere Desarrollo | Requires Development | Booleano que indica si pasa por TI |
| ROI | Return on Investment | (Ahorros anuales − Costo del proyecto) / Costo del proyecto × 100 |
| Solicitante | Requester | Usuario que inicia el proceso |
| Umbral de escalamiento | Escalation Threshold | Monto sobre el cual se requiere aprobación del Comité |

## Términos técnicos

| Término | Definición |
|---|---|
| Business Unit (BU) | Construct de Dataverse para segmentación. Usamos uno por empresa del Grupo |
| Connection Reference | Referencia indirecta a una conexión, necesaria para deployment |
| Service Principal | Identidad no-humana para autenticar Power Automate contra Dataverse |
| Solution | Contenedor versionable de customizaciones de Power Platform |
| RLS | Row-Level Security: filtrado de filas por usuario |
| FLS | Field-Level Security: control de visibilidad por columna |
| PCF Control | Power Apps Component Framework, controles custom TypeScript/React |
| MSAL | Microsoft Authentication Library |
