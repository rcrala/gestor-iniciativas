# ADR-0004: Estrategia de entrega al tenant del cliente

- **Status**: Aceptado
- **Fecha**: 2026-05-23
- **Decisores**: Tech Lead, Arquitecto, Patrocinador
- **Issue**: #5

## Contexto

INNOVA es desarrollado por nuestro equipo (GTC) pero **PROD vive en el tenant del cliente** (Grupo Pasquí). Esto cambia el modelo mental de "deploy continuo a producción" por uno de "entrega de producto instalable":

- DEV/QA en nuestro tenant GTC (`org93905a7d` y `org8b65c4d6`)
- PROD aprovisionado por el cliente en su propio tenant Power Platform
- INNOVA es entrega única a Grupo Pasquí (no producto multi-cliente)

Las siguientes restricciones aplican:

- No tendremos acceso administrativo permanente al tenant del cliente
- Las URLs de Dataverse, SharePoint y conexiones son **distintas** entre nuestro tenant y el del cliente
- El cliente provisiona su propio Service Principal con sus credenciales
- El primer import en PROD debe ser asistido; updates posteriores pueden ser autónomos del cliente
- Las conexiones (Outlook, SharePoint, Teams) en el cliente deben apuntar a **sus** cuentas, no a las nuestras

## Decisión

Adoptaremos un modelo de **paquete entregable + import asistido** con los siguientes pilares:

### 1. Solutions Managed entregables

- Todas las solutions (`innova-core`, `innova-flows`, `innova-canvas`, `innova-reports`) se exportan como **Managed** desde nuestro QA hacia un ZIP descargable
- El CI/CD pipeline produce el ZIP como artifact de GitHub Release
- El cliente importa vía PAC CLI o maker portal

### 2. Environment Variables para todo lo tenant-specific

Todo valor que difiera entre nuestro tenant y el del cliente vive en **Environment Variables de Dataverse** (no hardcodeado, no en código):

- URLs de bibliotecas SharePoint (Cotizaciones, Ejecución)
- IDs de equipos Teams para notificaciones
- Direcciones de correo institucionales (`pmo@cliente.com`, `comite@cliente.com`)
- Parámetros operativos sensibles al ambiente (URLs base de portales, dominios)

Los parámetros de **negocio** (umbral de escalamiento, tarifa hora PMO/TI, lista de empresas del Grupo Pasquí) viven en la tabla `pas_parametro` y se pueblan con seed-data al instalar.

### 3. Connection References

Cada conector externo usa **Connection References** en lugar de conexiones directas. Al importar el solution en el cliente:

1. El maker portal pide que el cliente vincule cada Connection Reference a una conexión real de su tenant
2. Las conexiones quedan bajo el control del cliente y usan SUS credenciales

Connection References previstas:
- `cr_innova_dataverse`
- `cr_innova_outlook`
- `cr_innova_sharepoint`
- `cr_innova_teams`
- `cr_innova_office365users` (lookup de manager/jefatura)

### 4. Service Principal en el cliente

El cliente provisiona en su tenant Entra ID:
- Una App Registration "INNOVA Service Principal"
- Asignación de rol `System Customizer` + rol custom de Dataverse con permisos a tablas `pas_*`
- Secret rotable cada 12 meses

Documentación detallada en [`docs/architecture/entrega-cliente.md`](../architecture/entrega-cliente.md).

### 5. Deployment Settings JSON

Cada entrega de PROD se acompaña de un archivo `deployment-settings.json` con:
- Valores concretos de Environment Variables para el cliente
- Mapeo de Connection References a IDs de conexión del cliente
- Variables aplicadas vía `pac solution import --settings-file`

Este archivo NUNCA se commitea con valores reales. Se genera por entrega y se comparte por canal seguro.

### 6. Datos: nunca en el solution

- Solutions contienen **solo metadata** (tablas, columnas, vistas, flows, canvas apps)
- Datos seed (catálogos, parámetros iniciales, miembros piloto del Comité) se cargan vía `scripts/seed-data.ps1` ejecutado contra el ambiente del cliente, autenticado con SU Service Principal
- Datos de prueba en DEV/QA nunca viajan al cliente

### 7. Acompañamiento del primer import

El primer import en PROD se hace **conjuntamente** con el cliente:
- Sesión presencial o videoconferencia
- Checklist en `docs/architecture/entrega-cliente.md`
- Validación post-import (smoke tests, verificación de Connection References, prueba de un flow end-to-end)
- Documento firmado de aceptación

Updates posteriores pueden ser autónomos del cliente si siguen el runbook.

## Consecuencias

### Positivas

- Cliente mantiene control total de sus datos y conexiones
- Sin dependencia operativa nuestra para que PROD funcione
- Modelo escalable si en el futuro se entrega a otro cliente
- ALM más estricto: cada release es un artefacto inmutable con checksum

### Negativas

- No podemos hotfixear PROD directamente — siempre vía entrega versionada
- Setup inicial más complejo para el cliente (provisionar SP, vincular Connection References, ejecutar seed)
- Sin acceso a logs de PROD para debugging — el cliente debe proveer evidencia

### Neutrales

- Equipo debe disciplinarse en parametrizar todo lo tenant-specific desde el día 1 (no "ya lo arreglamos después")
- El pipeline CI/CD se complica: produce artifact ZIP en lugar de hacer auto-deploy
- Necesidad de mantener "ambiente espejo" QA lo más similar posible a PROD (mismo tamaño de Business Units, mismas Connection References)

## Alternativas consideradas

### Alternativa 1: PROD en nuestro tenant, cliente accede como guest

**Por qué no**: Cliente no quiere depender de nuestro tenant para datos sensibles. Compliance + soberanía de datos. Aumenta riesgo legal y operativo nuestro.

### Alternativa 2: ISV con AppSource

**Por qué no**: INNOVA es entrega única, no producto comercial. Overhead del proceso de AppSource (certificación, soporte, marketplace) excede beneficio.

### Alternativa 3: Power Platform Pipelines (Microsoft) entre tenants

**Por qué no**: Power Platform Pipelines está optimizado para deployments intra-tenant. Cross-tenant requiere configuración compleja y limita el control sobre Environment Variables y Connection References.

## Próximos pasos

1. Crear `docs/architecture/entrega-cliente.md` con el checklist operativo (ya cubierto por el mismo issue #5)
2. Diseñar el set inicial de Environment Variables en S0-5
3. Ajustar pipeline CI/CD en S0-6 para producir ZIP en GitHub Release
4. Coordinar con admin del tenant del cliente para definir fechas tentativas de provisión y primer import (probablemente al final de M9 o M10)
