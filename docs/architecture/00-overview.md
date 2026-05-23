# Arquitectura General — INNOVA

## Visión

INNOVA es una aplicación SaaS interna construida sobre Microsoft Power Platform que automatiza el flujo de gestión de iniciativas de proyectos en Grupo Pasquí.

## Capas

### Presentación (Canvas Apps)

Una sola Canvas App con múltiples pantallas organizadas por rol:

- Solicitante (Pantalla #1)
- PMO Evaluación (Pantalla #2) y Ejecución (Pantalla #5)
- TI (Pantalla #3)
- Jefatura (Pantallas #4 y #6)
- PMO Cotizaciones (Pantalla #7)
- Gerencia General (Pantalla #8)
- Comité (Pantalla dedicada)
- Administrador (configuración y catálogos)
- Tracking "Mis Solicitudes" (transversal)

Componentes reutilizables para tarjetas, tablas, botones, y el theme corporativo aplicado vía variables de App.OnStart.

### Orquestación (Power Automate)

- Flows top-level disparados por eventos de Dataverse (Create / Update sobre `pas_iniciativa`)
- Child flows para utilidades transversales: enviar correo, enviar mensaje Teams, registrar log, evaluar permisos
- Job programado: recordatorios cada 3 días para iniciativas estancadas, consolidado por aprobador

### Persistencia (Dataverse)

- Tablas custom con prefijo `pas_`
- Roles de seguridad alineados con los 7 roles del sistema
- Business Units para segmentación por empresa (ver ADR-0003)
- Auditoría activada en todas las tablas críticas

### Reportería (Power BI)

- Dashboard ejecutivo en tiempo real (DirectQuery a Dataverse)
- Paginated Reports para exportación a Excel, PDF y CSV
- RLS de Power BI espejo de los permisos de Dataverse

### Almacenamiento documental (SharePoint Online)

- Una biblioteca por solución (Cotizaciones, Ejecución)
- Permisos heredados desde grupos de seguridad
- Conexión desde Power Apps vía connector SharePoint

## Diagrama lógico

```
                  Microsoft Entra ID (SSO + App Registration)
                                 │
            ┌────────────┬───────┴───────┬───────────────┐
            ▼            ▼               ▼               ▼
       Power Apps    Power Automate   Power BI     Teams Connector
        Canvas
            │            │               │               │
            └────────────┴───────┬───────┴───────────────┘
                                 ▼
                          Dataverse (tablas, RLS, auditoría)
                                 │
                                 ▼
                          SharePoint Online (documentos)
```

## Decisiones arquitectónicas clave

Detalle en `docs/decisions/`. Resumen:

- **ADR-0001**: Power Platform como stack
- **ADR-0002**: Claude Code para desarrollo
- **ADR-0003**: Business Units para segmentación por empresa

## Ambientes

| Ambiente | Propósito | URL pattern |
|---|---|---|
| DEV | Desarrollo y pruebas individuales | `grupo-pasqui-innova-dev.crm.dynamics.com` |
| QA | Pruebas integradas y UAT | `grupo-pasqui-innova-qa.crm.dynamics.com` |
| PROD | Producción | `grupo-pasqui-innova.crm.dynamics.com` |

Los valores reales se configuran al provisionar los ambientes en Sprint 0.

## Estrategia de ALM

- Cada solution es independiente y puede desplegarse por separado (excepto `innova-core` que es prerequisito de las demás)
- DEV usa solutions Unmanaged
- QA y PROD usan solutions Managed
- Pipeline en Azure DevOps construye desde fuentes desempaquetadas, empaqueta, e importa
- Rollback: cada release etiqueta el repo (`git tag innova-core-v1.0.0`) para reconstruir cualquier versión
