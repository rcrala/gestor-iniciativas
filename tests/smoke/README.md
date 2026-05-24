# Tests — Smoke tests post-deployment

Pruebas mínimas a ejecutar **inmediatamente después** de cualquier deploy a QA o PROD para detectar regresiones obvias antes de habilitar el ambiente a usuarios.

## Convención

Cada deploy tiene su propio test plan ejecutado: `deploy-<env>-YYYYMMDD-smoke.md`.

## Casos mínimos

1. **Login**: usuario test puede autenticarse y ver la app
2. **Catálogos visibles**: dropdown de empresas y departamentos cargan
3. **Crear iniciativa**: solicitante puede crear una iniciativa de prueba
4. **Notificación**: flow `Iniciativa Creada - Notificar PMO` envía correo
5. **Dashboard**: M13 Power BI carga con datos sembrados
6. **Connection References**: las 5 connections resuelven a connections válidas en el environment

## Tiempo objetivo

< 15 minutos. Si tarda más, automatizar lo que se pueda.

## Ejemplo (cuando exista el primer deploy)

`deploy-qa-20260601-smoke.md` con resultado por cada caso.

## Referencias

- Plantilla: [`../_template-test-plan.md`](../_template-test-plan.md)
