# ADR-0001: Stack tecnológico Microsoft Power Platform

- **Status**: Aceptado
- **Fecha**: 2026-05-23
- **Decisores**: Tech Lead, Arquitecto, Patrocinador

## Contexto

INNOVA es un sistema de workflow empresarial con las siguientes características:

- Múltiples roles con permisos diferenciados
- Flujos de aprobación complejos con bifurcaciones condicionales
- Necesidad de notificaciones por email y Teams
- Reportería ejecutiva en tiempo real
- Integración con Active Directory corporativo (Entra ID)
- Gestión documental
- Auditoría completa
- Despliegue interno para todas las empresas de Grupo Pasquí

Grupo Pasquí ya cuenta con licencias Microsoft 365 E3/E5, lo que reduce significativamente el costo incremental de adoptar Power Platform.

## Decisión

Adoptaremos Microsoft Power Platform como stack principal:

- **Dataverse** para persistencia
- **Power Apps Canvas** para la interfaz de usuario
- **Power Automate** para orquestación de flujos
- **Power BI** para reportería
- **SharePoint Online** para gestión documental
- **Entra ID** para autenticación

## Consecuencias

### Positivas
- Tiempo de desarrollo 40-60% menor vs. desarrollo a medida
- Integraciones nativas con Teams, Outlook, SharePoint
- Seguridad empresarial out-of-the-box (RLS, BU, roles)
- Auditoría nativa en Dataverse
- ALM maduro con PAC CLI y Solutions
- El equipo no necesita conocimientos profundos de DevOps

### Negativas
- Licenciamiento per-user puede ser costoso a escala
- Limitaciones del low-code para lógica compleja, lo que puede requerir PCF Controls o plug-ins C#
- Dependencia de Microsoft (vendor lock-in)
- Limitaciones de performance en escenarios con miles de transacciones concurrentes

### Neutrales
- El equipo debe especializarse en Power Platform
- La documentación oficial es extensa pero a veces fragmentada
- Cambios frecuentes en la plataforma requieren mantenimiento continuo

## Alternativas consideradas

### Alternativa 1: Desarrollo a medida (.NET 8 + Angular/React + SQL Server)
**Por qué no**: Tiempo de desarrollo 40-50% mayor (1.900-2.300 horas vs. 1.340), requiere DevOps maduro, sin ventajas claras para el dominio de workflow empresarial.

### Alternativa 2: Salesforce / Pega / ServiceNow
**Por qué no**: Licenciamiento adicional significativo. Curva de aprendizaje similar a Power Platform sin la ventaja de integración nativa con M365 ya pagado.

### Alternativa 3: Workflow engines open-source (Camunda, n8n)
**Por qué no**: Requiere infraestructura de hosting propia, integración custom con AD y Teams, equipo de soporte mayor. Mayor costo total de ownership.
