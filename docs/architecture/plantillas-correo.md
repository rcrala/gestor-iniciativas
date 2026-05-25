# Plantillas de correo de INNOVA

Almacenadas en la tabla `pas_plantillacorreo`. Cada plantilla es leida por un Power Automate flow que:
1. Recupera el record por `pas_nombre_clave`
2. Sustituye las variables `{variable}` en `pas_asunto` y `pas_cuerpo_html`
3. Envia con Office 365 Outlook (cuerpo en HTML)

## Tabla de plantillas

| Clave | Display | Asunto | Disparada por |
|---|---|---|---|
| `iniciativa_creada_pmo` | Notificacion al PMO de nueva iniciativa | `[INNOVA] Nueva iniciativa requiere evaluacion - {consecutivo}` | Flow al pasar a Revision PMO |
| `iniciativa_estimacion_jefatura` | Notificacion a Jefatura | `[INNOVA] Estimacion lista para tu revision - {consecutivo}` | Flow al pasar a Revision Estimacion |
| `iniciativa_aprobada_gerencia` | Notificacion al solicitante | `[INNOVA] Tu iniciativa fue aprobada - {consecutivo}` | Flow al pasar a Aprobada por Gerencia |
| `iniciativa_recordatorio_3dias` | Recordatorio consolidado | `[INNOVA] Recordatorio: iniciativa {consecutivo} pendiente desde hace {diasPendiente} dias` | Scheduled flow diario |
| `iniciativa_comite_voto` | Solicitud de voto al Comite | `[INNOVA] Solicitud de voto - {consecutivo}` | Flow al pasar a Revision Comite |

## Convencion de variables

Las variables se referencian con `{nombreVariable}` (camelCase, sin namespacing, sin espacios).
Tipos de variables comunes:

- `{consecutivo}` → string `COA-2026-001`
- `{titulo}` → string del titulo de la iniciativa
- `{solicitante}` → display name del usuario solicitante
- `{jefatura}` → display name de la jefatura del solicitante
- `{duenioActual}` → display name del dueño del registro al momento
- `{montoEstimado}` → string formateado tipo `CRC 5,000,000` o `USD 10,000`
- `{diasPendiente}` → integer (e.g., `7`)
- `{diasMaxVoto}` → integer (e.g., `3`)
- `{estado}` → label legible del estado actual
- `{razonEscalamiento}` → texto explicativo del por que escalo al Comite
- `{esMultiEmpresa}` → string `Si` o `No`
- `{urlIniciativa}` → URL absoluta al registro en Power Apps

## Estructura HTML

Las plantillas usan tabla-based layout para compatibilidad con Outlook (que no renderiza flexbox/grid). CSS inline porque Gmail strip `<style>`. Ancho fijo 600px (estandar email marketing). Colores corporativos hardcoded para MVP — el flow puede sustituir por `pas_parametro.pas_color_*` si necesita brand customization por cliente.

```html
<table width="600" align="center" style="font-family: Segoe UI, Arial; max-width: 600px;">
  <tr><td bgcolor="#5C2D91" style="padding:24px;color:white;">
    <strong>INNOVA</strong> · Plataforma de Iniciativas
  </td></tr>
  <tr><td style="padding:32px 24px;background:white;">
    <h2>{titulo del mensaje}</h2>
    <p>{intro}</p>
    <table width="100%" style="background:#f5f5f5;">
      <tr><td><strong>Consecutivo:</strong> {consecutivo}</td></tr>
      ...
    </table>
    <p><a href="{urlIniciativa}" style="background:#5C2D91;color:white;padding:12px 24px;text-decoration:none;">Ver detalle</a></p>
  </td></tr>
  <tr><td style="padding:16px 24px;background:#f5f5f5;color:#666;font-size:12px;">
    Correo automatico · No responder · INNOVA - Grupo Pasqui
  </td></tr>
</table>
```

## Sustitucion en flow

El flow helper `INNOVA - Helper - Enviar Correo con Plantilla` (pendiente de crear) debe:
1. Recibir parametros: `claveTemplate` (string), `variables` (object con kvp)
2. Retrieve del record por `pas_nombre_clave`
3. Foreach variable: `string-replace(cuerpo, '{' & key & '}', value)`
4. Mismo para asunto
5. Send email V2 con HTML body + To + Subject

Implementacion del flow queda pendiente (requiere model-driven app o portal manual para autoria).

## Source de la verdad

Los HTML reales viven en [`scripts/seed-data/plantillas-correo/`](../../scripts/seed-data/plantillas-correo/) como archivos `.html` versionables. El script [`scripts/setup/08-update-plantillas-html.ps1`](../../scripts/setup/08-update-plantillas-html.ps1) los lee y los PATCH en pas_plantillacorreo. Idempotente: si el cuerpo en DEV es identico al del archivo, salta.

Cuando se necesite modificar una plantilla:
1. Editar el `.html` en el repo (con preview en VS Code via `Live Server`)
2. Correr `pwsh ./scripts/setup/08-update-plantillas-html.ps1 -Environment dev` para sincronizar
3. Probar via flow (cuando exista)
4. Commit + PR

## Internacionalizacion (deferida)

Por ahora todas las plantillas son en espanol (CR). Si en el futuro se requiere multi-idioma, se puede:
- Agregar campo `pas_idioma` (Choice: es/en) y duplicar el record por idioma
- O usar un solo template con secciones `{lang:es}...{/lang:es}{lang:en}...{/lang:en}` y filtrar en el flow segun `systemuser.preferredlanguageid`
