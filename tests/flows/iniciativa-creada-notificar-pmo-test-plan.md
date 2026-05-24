# Test Plan: INNOVA - Iniciativa Creada - Notificar PMO

> **Tipo**: flow
> **Artefacto**: `INNOVA - Iniciativa Creada - Notificar PMO` (flow piloto)
> **Issue / PR origen**: #20 (S0-9 test framework)
> **Última ejecución**: pendiente (flow aún no implementado — issue #19 S0-8)
> **Resultado**: N/A

## Resumen

Cuando una iniciativa se envía (transición `Borrador` → `Revisión inicial PMO`), el flow envía un correo al PMO asignado usando la plantilla `iniciativa_creada_pmo` con las variables del registro.

## Precondiciones

- Environment: dev
- Solicitante: usuario con rol `INNOVA Solicitante`
- Datos necesarios:
  - Catálogos sembrados (`pas_empresa`, `pas_centrocosto`, `pas_departamento`, `pas_plantillacorreo` con clave `iniciativa_creada_pmo`)
  - Parámetros sembrados (`DiasRecordatorio`, etc.)
  - Al menos un usuario con rol `INNOVA PMO` para recibir la notificación
- Connection References resueltas a: `cr_innova_dataverse`, `cr_innova_outlook`

## Casos de prueba

### Caso 1: Happy path — iniciativa enviada genera correo al PMO

**Objetivo**: validar que al cambiar `pas_estado` de Borrador a Revisión inicial PMO se envía el correo correcto.

**Pasos**:
1. Solicitante crea iniciativa con título, descripción, empresa, departamento, monto estimado
2. Solicitante presiona "Enviar" → flow patches `pas_iniciativa.pas_estado` = 100000001 (Revisión inicial PMO)
3. Flow trigger se dispara
4. Flow lee la iniciativa, resuelve el PMO asignado y la plantilla
5. Flow envía correo con asunto y cuerpo expandido

**Esperado**:
- Correo llega al PMO asignado (verificar inbox)
- Asunto: `[INNOVA] Nueva iniciativa requiere evaluacion - {consecutivo}` con el consecutivo real (ej. `EMA-2026-001`)
- Cuerpo HTML con variables `{titulo}`, `{solicitante}`, `{urlIniciativa}` expandidas
- `pas_iniciativa.pas_fecha_solicitud` poblada con timestamp del envío
- Flow run history muestra status `Succeeded`

**Evidencia**:
- Screenshot inbox PMO con el correo
- Run history link del flow
- Query OData: `pas_iniciativas?$filter=pas_iniciativaid eq <guid>&$select=pas_consecutivo,pas_estado,pas_fecha_solicitud`

**Resultado**: pendiente

---

### Caso 2: Error path — plantilla `iniciativa_creada_pmo` desactivada

**Objetivo**: el flow debe degradar elegantemente si la plantilla no está activa.

**Pasos**:
1. Admin desactiva la plantilla (`pas_activa = false`)
2. Solicitante envía una iniciativa
3. Flow corre

**Esperado**:
- Flow detecta plantilla inactiva → usa fallback hardcoded mínimo O loguea warning y skip envío (decisión a tomar en S0-8)
- Run history muestra warning explícito (no error silencioso)
- Iniciativa avanza igual a Revisión inicial PMO (el envío de correo no debe bloquear el cambio de estado)

**Resultado**: pendiente

---

### Caso 3: Error path — no hay PMO asignable

**Objetivo**: validar manejo cuando no hay usuario con rol PMO en el environment.

**Pasos**:
1. Remover/deshabilitar a todos los usuarios con rol `INNOVA PMO`
2. Solicitante envía iniciativa
3. Flow corre

**Esperado**:
- Flow detecta lista vacía de PMOs
- Envía correo al Admin (o al `pas_parametro.PmoEmail` fallback) con notificación de "iniciativa sin PMO asignado"
- Run history muestra warning
- Iniciativa avanza igual

**Resultado**: pendiente

---

## Issues encontradas durante el test

(ninguna, flow aún no implementado)

## Cobertura

- [ ] Happy path
- [ ] Validación de plantilla inactiva
- [ ] Validación de lista PMO vacía
- [ ] Idempotencia: re-trigger del flow no envía 2 correos
- [ ] Performance: flow termina en < 10s

## Notas

Este test plan se ejecutará cuando el flow se implemente en issue #19 (S0-8). Sirve como **referencia de estilo** para todos los flows futuros: estructura, granularidad de casos, evidencia esperada.
