# ADR-0006: Stack pro-code React + .NET, desplegable en cliente y evolución a SaaS

- **Status**: Aceptado (supersedes ADR-0001)
- **Fecha**: 2026-06-25
- **Decisores**: Tech Lead, Arquitecto, Patrocinador (pendiente de ratificación)

## Contexto

El ADR-0001 adoptó Microsoft Power Platform (Dataverse, Power Apps Canvas,
Power Automate, Power BI, SharePoint) como stack principal de INNOVA.

Con el avance del proyecto, la viabilidad de continuar sobre la capa low-code
de Power Platform ha disminuido. A esto se suma un cambio en la **estrategia de
producto**: INNOVA deja de concebirse como una herramienta interna de Grupo
Pasquí y pasa a perfilarse como un **producto desplegable en la infraestructura
del cliente** (on-premise o nube del cliente), con **interconexión hacia los
sistemas internos del cliente**, y con una **evolución posterior hacia una
plataforma SaaS multi-tenant**.

Este modelo de despliegue impone fuerzas que Power Platform no satisface bien:

- El producto debe instalarse en infraestructura ajena, no solo en el tenant
  M365 de Grupo Pasquí.
- Debe integrarse con el IdP y los sistemas de cada cliente.
- Debe poder operar tanto single-tenant (instalación en cliente) como
  multi-tenant (SaaS) con el mismo artefacto.
- El licenciamiento per-user de Power Platform no es compatible con un modelo
  de producto vendible a terceros.

Toda la **definición funcional** existente (modelo de datos, máquina de estados
de aprobación, glosario, roles, convenciones de negocio en `docs/`) se conserva:
describe *qué* hace el sistema, independiente de la tecnología de implementación.

## Decisión

Adoptaremos un stack **pro-code, container-native y cloud-agnóstico**, regido
por el principio: **desplegable en cliente desde el día 1, multi-tenant ready**.

Stack:

- **Frontend**: React + TypeScript + Next.js, Tailwind CSS + shadcn/ui,
  TanStack Query/Table, React Hook Form + Zod.
- **Backend**: ASP.NET Core Web API + EF Core (reutiliza la experiencia C# del
  equipo proveniente de los plug-ins de Dataverse).
- **Base de datos**: PostgreSQL con Row-Level Security para aislamiento de
  tenants. Una sola tecnología de datos para on-prem y SaaS.
- **Workflows / aprobaciones**: motor durable self-hosted — **Elsa Workflows**
  (incluye diseñador visual, análogo a Power Automate) o **Hangfire** para
  orquestación más simple. Reemplaza Power Automate sin atar a Azure.
- **Identidad**: **Keycloak** como broker de identidad, federando el IdP de cada
  cliente (Entra ID, AD on-prem vía LDAP/SAML, etc.). Multi-realm habilita el
  SaaS multi-tenant.
- **Almacenamiento documental**: API S3 → MinIO (on-prem) o bucket de objetos
  (SaaS). Reemplaza SharePoint con una sola abstracción.
- **Correo**: SMTP pluggable (servidor del cliente on-prem, proveedor cloud en
  SaaS).
- **Reportería**: Metabase self-hosted; Power BI opcional como conector para
  clientes que ya lo tengan. Deja de ser dependencia obligatoria.
- **Integración con sistemas del cliente**: API REST + webhooks; opcionalmente
  n8n self-hosted como capa de conectores (análogo a Power Automate para
  integraciones externas).
- **Empaque y despliegue**: imágenes OCI (Docker). Docker Compose para la
  instalación en cliente; Helm/Kubernetes para el SaaS. Mismo artefacto, distinto
  orquestador. IaC con Bicep/Terraform. CI/CD con GitHub Actions.
- **Pruebas**: xUnit (backend), Vitest (frontend), Playwright (E2E).

Multi-tenancy se diseña desde el inicio: el modelo asume `tenant_id` + RLS; una
instalación en cliente es simplemente un tenant.

## Consecuencias

### Positivas
- Producto desplegable en infraestructura del cliente y, con el mismo código,
  como SaaS multi-tenant.
- Cloud-agnóstico: sin lock-in a Azure ni a M365; corre en on-prem, Azure, AWS
  o GCP.
- Licenciamiento viable como producto vendible (sin per-user de Power Platform).
- Control total sobre lógica compleja, performance e integraciones.
- Reutiliza la experiencia C# del equipo y conserva el 100% de las specs
  funcionales en `docs/`.
- Identidad federable con el IdP de cada cliente.

### Negativas
- Mayor tiempo de desarrollo inicial vs. low-code (se pierde el 40-60% de ahorro
  citado en ADR-0001).
- Requiere madurez en DevOps (contenedores, K8s, observabilidad) que antes no
  era necesaria.
- El equipo asume la operación de componentes que antes eran gestionados
  (auth, storage, workflow engine, DB).
- Se pierden las integraciones nativas out-of-the-box con Teams/Outlook/
  SharePoint (se reemplazan por integraciones explícitas).

### Neutrales
- El equipo se especializa en React/.NET/contenedores en lugar de Power Platform.
- La auditoría deja de ser nativa de Dataverse y pasa a implementarse en la capa
  de datos (columnas + triggers / interceptores EF Core).
- Power BI puede conservarse como conector opcional.

## Alternativas consideradas

### Alternativa 1: Continuar en Power Platform (ADR-0001)
**Por qué no**: No soporta despliegue en infraestructura del cliente ni un modelo
de producto vendible; licenciamiento per-user incompatible con SaaS; lock-in a
M365/Azure.

### Alternativa 2: Full-stack TypeScript (NestJS + Prisma + Temporal)
**Por qué no (como primaria)**: Igualmente válido y portátil, con la ventaja de
un solo lenguaje. Se descartó frente a .NET por la experiencia C# previa del
equipo y la robustez de ASP.NET Core para un producto enterprise de larga vida e
integración intensiva. Queda como alternativa de respaldo.

### Alternativa 3: Backend-as-a-Service (Supabase gestionado)
**Por qué no**: El valor de Supabase está en su servicio gestionado; el
self-host por cliente y la posterior consolidación multi-tenant del SaaS
resultan operativamente incómodos para este modelo de despliegue.
