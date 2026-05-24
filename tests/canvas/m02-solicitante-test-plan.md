# Test Plan: M2 - Pantalla Solicitante (Nueva Solicitud)

> **Tipo**: canvas
> **Artefacto**: pantalla `M2 - Nueva Solicitud` en `INNOVA - Tracking Mis Solicitudes`
> **Issue / PR origen**: #20 (S0-9 test framework — referencia)
> **Última ejecución**: pendiente (pantalla aún no implementada)
> **Resultado**: N/A

## Resumen

Solicitante captura iniciativa: titulo, descripción, justificación, beneficios, empresa, departamento, monto estimado, urgencia/importancia (para Eisenhower futuro), sistemas afectados si requiere integración, y tabla dinámica de colaboradores con costo del proceso actual.

## Precondiciones

- Environment: dev
- Usuario: con rol `INNOVA Solicitante`
- Datos: catálogos sembrados (`pas_empresa`, `pas_departamento`, `pas_sistema`)

## Casos de prueba

### Caso 1: Happy path — crear iniciativa simple sin desarrollo

**Pasos**:
1. Solicitante abre la app
2. Pantalla de Inicio → tarjeta "Crear nueva solicitud"
3. Llena: titulo, descripción, justificación, beneficios
4. Selecciona empresa → dropdown departamento se filtra por empresa
5. Selecciona departamento, centro de costo, monto estimado, ahorro anual
6. Marca `pas_requiere_desarrollo = No`
7. (Opcional) agrega 2 colaboradores en tabla "Costo actual del proceso"
8. Presiona "Guardar como borrador" → registro creado con `pas_estado = Borrador`
9. Presiona "Enviar a PMO" → estado pasa a Revisión inicial PMO, flow dispara notificación

**Esperado**:
- Registro creado con todos los campos
- Consecutivo generado formato `<codigo_corto>-2026-NNN`
- Flow `INNOVA - Iniciativa Creada - Notificar PMO` dispara
- Solicitante ve la iniciativa en "Mis Solicitudes" con estado actualizado

---

### Caso 2: Validación de campos requeridos

**Pasos**:
1. Solicitante intenta enviar sin llenar titulo
2. Solicitante intenta enviar sin seleccionar empresa
3. Solicitante intenta enviar con monto = 0

**Esperado**:
- UI bloquea envío con mensajes específicos por campo
- No se crea registro hasta que todos los requeridos estén llenos

---

### Caso 3: Iniciativa con desarrollo y sistemas afectados

**Pasos**:
1. Solicitante marca `pas_requiere_desarrollo = Yes`
2. UI muestra sección "Sistemas a integrar" (multi-select de `pas_sistema` filtrado por empresa)
3. Selecciona 2 sistemas → se crean 2 registros en `pas_iniciativa_sistema`
4. Envía iniciativa

**Esperado**:
- 2 registros bridge creados
- Cuando PMO abra M3, ve los 2 sistemas seleccionados

---

### Caso 4: Permisos — Solicitante no ve iniciativas de otros

**Pasos**:
1. Solicitante A crea iniciativa
2. Solicitante B (otra cuenta del mismo BU) abre "Mis Solicitudes"

**Esperado**:
- B no ve la iniciativa de A
- Filtro de UI: `pas_solicitante.systemuserid = User().UserPrincipalName`

---

### Caso 5: Edición solo en estado Borrador

**Pasos**:
1. Iniciativa de A en estado Borrador → A puede editar todos los campos
2. A envía → estado Revisión inicial PMO
3. A intenta editar de nuevo

**Esperado**:
- Campos read-only tras envío
- UI muestra mensaje "Iniciativa en revisión por PMO"
- BR-17 enforced

---

## Cobertura

- [ ] Happy path crear + enviar
- [ ] Validación campos requeridos
- [ ] Multi-select sistemas + bridge
- [ ] Tabla dinámica colaboradores
- [ ] Cálculo automático ROI
- [ ] Permisos por solicitante
- [ ] Read-only post-envío
- [ ] Responsive mobile

## Notas

Test plan placeholder. Se ejecutará cuando M2 se implemente. Sirve como referencia de estilo para todas las pantallas (M3-M14).
