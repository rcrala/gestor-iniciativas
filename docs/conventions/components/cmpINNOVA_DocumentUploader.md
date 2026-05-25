# cmpINNOVA_DocumentUploader

> **Tipo**: Functional Container (Component)
> **Versión**: 1.0
> **Issue**: #59 (S1-03)

## Propósito

Componente para **subir archivos adjuntos** asociados a una iniciativa. Los archivos físicos se almacenan en **SharePoint** (definido por convención `entrega-cliente.md`), y la metadata se persiste en la tabla Dataverse **`pas_documentoadj`**. Renderiza también la lista de adjuntos existentes con opciones de descarga y eliminación (soft delete según rol).

## Dónde se usa

- **M2 Solicitante (H3)**: adjuntar documentos de soporte (PDF, Word, Excel, imagen) al crear/editar borrador
- **M3 PMO Evaluación**: subir documentos del levantamiento
- **M5 Jefatura Estimación**: ver adjuntos del solicitante y PMO
- **M6 PMO Ejecución**: subir entregables y documentos de avance
- **M8 PMO Cotizaciones**: subir PDFs de cotizaciones de proveedores

## Limitación arquitectónica importante

Power Apps Canvas tiene **límite de upload de 64MB por archivo** (control nativo `AddMediaButton`). Para archivos más grandes habría que usar un **PCF Control personalizado** que invoque Microsoft Graph API directamente — fuera del alcance de v1.

Adicional: **el upload real a SharePoint NO lo hace el componente**, lo hace un **flow de Power Automate** (ver `INNOVA - Documento Adjunto - Mover a SharePoint`, pendiente de implementar — riesgo M2-H3 documentado en plan). El componente:
1. Captura el archivo y metadata en Power Apps (modo "pending")
2. Llama al flow vía conector custom o trigger HTTP
3. El flow mueve el binario a SharePoint y devuelve la URL
4. El componente persiste `pas_documentoadj` con la URL devuelta

## Referencia visual del cliente

[image4.png](../../01-Requeriments/media/image4.png) M2 — no se ve explícitamente en este mockup (M2-H3 es story separada) pero el patrón aparece en [image6.png](../../01-Requeriments/media/image6.png) M6 ("Documentación de Ejecución" con tabla de archivos + botón "Cargar archivos").

## ASCII wireframe

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  📎  Documentos adjuntos                                  [+ Subir archivo]  │  ← header
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  📄 Cotizacion_Proveedor_X.pdf      2.4 MB   2026-05-25   Cotizacion    🗑   │  ← fila adjunto
│  📊 Analisis_costos.xlsx            850 KB   2026-05-24   Soporte       🗑   │
│  📷 Diagrama_proceso.png            312 KB   2026-05-24   Soporte       🗑   │
│                                                                              │
│  (sin adjuntos)                                                              │  ← empty state
└──────────────────────────────────────────────────────────────────────────────┘
   Click en nombre = descarga (abre URL SharePoint en nueva pestaña)
   Click 🗑 = soft delete (pas_documentoadj.pas_activo=false; archivo SP se conserva)
```

Alto: **calculado por cantidad de filas** (header 40 + N filas 56 + empty state 60 si vacío).
Width: **fill** del padre.

## Input properties (`pp*`)

| Property | Tipo | Default | Required | Descripción |
|---|---|---|---|---|
| `ppIniciativaId` | GUID | (blank) | sí | ID de la iniciativa padre. Si blank, modo "pending" (archivos se acumulan en collection local y se persisten al primer Save de la iniciativa) |
| `ppModoSoloLectura` | Boolean | `false` | no | Si true: oculta botón "+ Subir" y "🗑" en filas. Sigue permitiendo descargar |
| `ppTema` | Record | (default tema) | sí | Tema visual |
| `ppTiposPermitidos` | Text | `".pdf,.docx,.xlsx,.png,.jpg,.jpeg"` | no | CSV de extensiones permitidas. El componente valida y rechaza otras con un Notify |
| `ppTamanoMaxMB` | Number | `25` | no | Tamaño máximo por archivo en MB (límite Power Apps es 64; defaultmos a 25 para evitar problemas perf) |
| `ppFlowUploadName` | Text | `"INNOVA - Documento Adjunto - Mover a SharePoint"` | sí | Nombre del flow Power Automate que mueve archivos a SharePoint. Pasado como input para permitir mock en testing |

## Output properties (`oo*`)

| Property | Tipo | Disparado cuando... | Descripción |
|---|---|---|---|
| `ooColeccionLocal` | Table | (reactivo) | Si `ppIniciativaId` blank, collection de archivos pendientes con shape `{nombre, tipo, tamanoBytes, base64Content}`. La pantalla padre la persiste al Save inicial |
| `ooCantidadAdjuntos` | Number | (reactivo) | Conteo de adjuntos activos (persistidos + pendientes locales) |
| `ooOnSelectSubir` | Behavior | Click en "+ Subir archivo" | Logging o validación pre-add |
| `ooOnUploadComplete` | Behavior | Después de upload exitoso a SharePoint | Útil para refresh de gallery o navegar |
| `ooOnUploadError` | Behavior | Si el flow de upload falla | Pantalla puede mostrar mensaje de error custom |

## Comportamiento

### Modo persistido (`ppIniciativaId` no blank)

1. Usuario hace click "+ Subir archivo"
2. Se abre el file picker nativo del navegador (vía control `AddMediaButton`)
3. Usuario selecciona archivo
4. Componente valida tipo + tamaño contra `ppTiposPermitidos` y `ppTamanoMaxMB` — si falla, `Notify(...)` y aborta
5. Componente serializa el archivo a base64 y llama al flow `ppFlowUploadName` con `{iniciativaId, nombreArchivo, base64, tipo}`
6. Flow mueve a SharePoint, devuelve `{urlSharePoint, success}`
7. Si success: componente hace `Patch(pas_documentoadjs, Defaults(...), {pas_url_sharepoint, pas_nombre_archivo, pas_tipo_documento, pas_iniciativa, ...})`
8. Gallery refresca

### Modo local (`ppIniciativaId` blank)

1-4. Igual que persistido
5. Componente acumula `{nombre, tipo, tamanoBytes, base64Content}` en `colDocumentosLocal`
6. Pantalla padre, al Submit de la iniciativa:
   - Primero `Patch(pas_iniciativas, Defaults, {...})` → obtiene `varIniciativaNueva`
   - Luego `ForAll(cmpINNOVA_DocumentUploader_1.ooColeccionLocal, ...)` para cada uno:
     - Llama al flow con `{iniciativaId: varIniciativaNueva.pas_iniciativaid, base64Content, nombre, tipo}`
     - Recibe URL y hace `Patch(pas_documentoadjs, Defaults, {...})`

## Power Fx por propiedad clave

### Botón "+ Subir archivo" (AddMediaButton nativo o ImagePicker custom)

```powerquery
// Visible
!Self.ppModoSoloLectura

// OnSelect (cuando se selecciona un archivo en file picker)
// AddMediaButton dispara OnChange al seleccionar archivo:
With(
    {
        archivo: AddMediaButton1.Media,
        nombreArchivo: AddMediaButton1.FileName,
        tamanoBytes: Len(JSON(AddMediaButton1.Media, JSONFormat.IncludeBinaryData)) * 3 / 4  // estimación base64 → bytes
    },
    If(
        // Validar tipo
        !(Lower(Right(nombreArchivo, 4)) in Split(Lower(Self.ppTiposPermitidos), ",")),
        Notify($"Tipo no permitido. Permitidos: {Self.ppTiposPermitidos}", NotificationType.Error),
        // Validar tamaño
        tamanoBytes > (Self.ppTamanoMaxMB * 1048576),
        Notify($"Archivo excede {Self.ppTamanoMaxMB} MB", NotificationType.Error),
        // OK: subir
        If(
            !IsBlank(Self.ppIniciativaId),
            // Modo persistido: llamar al flow
            With(
                {
                    resultado: 'INNOVA - Documento Adjunto - Mover a SharePoint'.Run(
                        Self.ppIniciativaId,
                        nombreArchivo,
                        JSON(archivo, JSONFormat.IncludeBinaryData)
                    )
                },
                If(
                    resultado.success,
                    Patch(
                        pas_documentoadjs,
                        Defaults(pas_documentoadjs),
                        {
                            pas_nombre_archivo: nombreArchivo,
                            pas_url_sharepoint: resultado.urlSharePoint,
                            pas_tamano_bytes: tamanoBytes,
                            pas_extension: Lower(Right(nombreArchivo, 4)),
                            pas_subido_por: User(),
                            pas_iniciativa: LookUp(pas_iniciativas, pas_iniciativaid = Self.ppIniciativaId),
                            pas_tipo_documento: 3  // "Soporte / Analisis" por default; ver pas_documento_tipo choice
                        }
                    );; Self.ooOnUploadComplete(),
                    Self.ooOnUploadError()
                )
            ),
            // Modo local: solo agregar a collection
            Collect(
                colDocumentosLocal,
                {
                    nombre: nombreArchivo,
                    tipo: Lower(Right(nombreArchivo, 4)),
                    tamanoBytes: tamanoBytes,
                    base64Content: JSON(archivo, JSONFormat.IncludeBinaryData)
                }
            );; Self.ooOnUploadComplete()
        )
    )
);;
Self.ooOnSelectSubir()
```

### Gallery (lista de adjuntos)

```powerquery
// Items
If(
    !IsBlank(Self.ppIniciativaId),
    Filter(
        pas_documentoadjs,
        pas_iniciativa.pas_iniciativaid = Self.ppIniciativaId
        // Soft delete: pas_documentoadj no tiene pas_activo; alternativa es agregar columna en v2
    ),
    colDocumentosLocal
)
```

### Click en nombre del archivo (descarga)

```powerquery
// OnSelect
Launch(ThisItem.pas_url_sharepoint, "", LaunchTarget.New)
```

### Botón 🗑 eliminar (por fila)

```powerquery
// Visible
!Parent.ppModoSoloLectura
// Y rol del usuario es Solicitante (dueño) o PMO/Admin
And gblRolUsuario in ["Solicitante", "PMO", "Administrador"]

// OnSelect
If(
    !IsBlank(Parent.ppIniciativaId),
    // Para v1 hacemos hard delete (la tabla pas_documentoadj no tiene pas_activo);
    // alternativa: agregar columna pas_activo en v2 para soft delete
    Remove(pas_documentoadjs, ThisItem),
    Remove(colDocumentosLocal, ThisItem)
);;
// El archivo en SharePoint se conserva (responsabilidad cliente vaciar después)
Notify("Adjunto eliminado del registro (archivo en SharePoint conservado)", NotificationType.Success)
```

### Empty state

```powerquery
// Visible (Label "Sin adjuntos")
CountRows(GalleryAdjuntos.AllItems) = 0
```

### Output `ooCantidadAdjuntos`

```powerquery
If(
    !IsBlank(Self.ppIniciativaId),
    CountRows(Filter(pas_documentoadjs, pas_iniciativa.pas_iniciativaid = Self.ppIniciativaId)),
    CountRows(colDocumentosLocal)
)
```

## Ejemplo de instanciación

### M2 Solicitante (modo local, nueva iniciativa)

```powerquery
// cmpINNOVA_DocumentUploader_1.ppIniciativaId = Blank()
// cmpINNOVA_DocumentUploader_1.ppModoSoloLectura = false
// cmpINNOVA_DocumentUploader_1.ppTema = gblTema
// cmpINNOVA_DocumentUploader_1.ppTiposPermitidos = ".pdf,.docx,.xlsx,.png,.jpg"
// cmpINNOVA_DocumentUploader_1.ppTamanoMaxMB = 10
// cmpINNOVA_DocumentUploader_1.ppFlowUploadName = "INNOVA - Documento Adjunto - Mover a SharePoint"
// cmpINNOVA_DocumentUploader_1.ooOnUploadComplete = Notify("Archivo agregado a pendientes. Se subirá al guardar.", NotificationType.Information)
```

### M3 PMO (modo persistido, iniciativa existente)

```powerquery
// cmpINNOVA_DocumentUploader_2.ppIniciativaId = gblIniciativaEnEvaluacion.pas_iniciativaid
// cmpINNOVA_DocumentUploader_2.ppModoSoloLectura = false   // PMO puede subir docs del levantamiento
// cmpINNOVA_DocumentUploader_2.ppTema = gblTema
// cmpINNOVA_DocumentUploader_2.ooOnUploadComplete = Notify("Documento subido correctamente", NotificationType.Success)
// cmpINNOVA_DocumentUploader_2.ooOnUploadError = Notify("Error subiendo. Reintentar o contactar admin.", NotificationType.Error)
```

### M5 Jefatura (solo lectura — solo ven los del Solicitante + PMO)

```powerquery
// cmpINNOVA_DocumentUploader_3.ppIniciativaId = ...
// cmpINNOVA_DocumentUploader_3.ppModoSoloLectura = true
```

## Reglas de uso

- **El flow de upload tiene que existir** antes de poner el componente en producción — sin él, el OnSelect del botón falla silenciosamente
- **Conexión al flow** debe estar agregada a la app (Connections → Power Automate → seleccionar el flow)
- **Categorizar el tipo de documento** (`pas_tipo_documento`) — el componente defaultea a "Soporte / Análisis" (valor 3) pero para Cotizaciones debe ser 1, Entregables 2, Otro 4. Considerar agregar `ppTipoDocumentoDefault` como input en V2
- **El componente NO maneja versionado de archivos** — si el usuario sube el mismo nombre 2 veces, SharePoint hace versioning nativo pero la tabla `pas_documentoadj` tendrá 2 filas. Por diseño en v1; agregar dedupe en v2 si negocio lo pide
- **Modo local no muestra preview** — los archivos pending solo se ven listados; preview requiere upload primero

## Cambios breaking que requerirían V2

- Cambiar shape de `ooColeccionLocal` (las pantallas que persisten al Save fallarían)
- Renombrar/remover `ppFlowUploadName` (el flow llamado se rompería)

Cambios no-breaking OK en V1:
- Agregar `ppTipoDocumentoDefault` para categorizar al upload
- Agregar `ppPermiteMultiple` para selección múltiple en un solo file picker
- Agregar preview/thumbnail para imágenes

## Referencias

- Overview: [`../canvas-component-library.md`](../canvas-component-library.md)
- Mockup con adjuntos visibles: [`../../01-Requeriments/media/image6.png`](../../01-Requeriments/media/image6.png) (M6 Ejecución)
- Tabla Dataverse: [`../../architecture/data-model.md`](../../architecture/data-model.md) sección `pas_documentoadj`
- Choice `pas_documento_tipo`: ver [`../../architecture/data-model.md`](../../architecture/data-model.md)
- Estrategia de archivos en SharePoint: [`../../architecture/entrega-cliente.md`](../../architecture/entrega-cliente.md)
- Story M2-H3 (adjuntar documentos): [`../../plan/modulos/m02-pantalla-solicitante.md`](../../plan/modulos/m02-pantalla-solicitante.md)
