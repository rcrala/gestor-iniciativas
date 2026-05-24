<#
.SYNOPSIS
    Crea las 12 tablas de INNOVA con sus columnas escalares en innova-core.

.DESCRIPTION
    Implementa la parte central de S0-4 (issue #15). Crea EntityDefinitions + Attributes
    no-lookup. Los lookups (que crean relaciones N:1) van en 04-create-relationships.ps1.

    Idempotencia:
    - Si la tabla existe: skip create entity, intenta crear cada columna individualmente
    - Si la columna existe: skip
    Permite re-correr para llenar tablas parciales tras un fallo.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER OnlyTable
    Opcional. Solo procesa la tabla con ese logical name (debug iterativo).

.PARAMETER WhatIf
    Dry-run.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',
    [string]$OnlyTable
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\dataverse.ps1"

$Solution = 'innova_core'

Write-Host "`n=== INNOVA S0-4 (paso 2/3): Crear Tablas en $($Environment.ToUpper()) ===" -ForegroundColor Cyan
Initialize-DataverseSession | Out-Null
$script:CurrentEnvironment = $Environment

# ==============================================================================
# Helpers de construccion de columnas
# ==============================================================================

function Convert-RequiredLevel {
    param([string]$Level)
    switch ($Level) {
        'None'                { return 'None' }
        'Recommended'         { return 'Recommended' }
        'ApplicationRequired' { return 'ApplicationRequired' }
        'SystemRequired'      { return 'SystemRequired' }
        default               { return 'None' }
    }
}

function Build-RequiredLevel {
    param([string]$Level)
    return @{ Value = (Convert-RequiredLevel $Level); CanBeChanged = $true; ManagedPropertyLogicalName = 'canmodifyrequirementlevelsettings' }
}

function Get-Desc {
    param($Col)
    if ([string]::IsNullOrWhiteSpace($Col.Description)) { return $Col.Display }
    return $Col.Description
}

function Get-OrDefault {
    param($Value, $Default)
    if ($null -eq $Value -or ($Value -is [string] -and [string]::IsNullOrEmpty($Value))) { return $Default }
    return $Value
}

function Build-StringAttribute {
    param($Col)
    return @{
        '@odata.type'  = 'Microsoft.Dynamics.CRM.StringAttributeMetadata'
        SchemaName     = $Col.SchemaName
        LogicalName    = $Col.LogicalName
        DisplayName    = (New-LocalizedLabel -Text $Col.Display)
        Description    = (New-LocalizedLabel -Text (Get-Desc $Col))
        RequiredLevel  = (Build-RequiredLevel $Col.Required)
        MaxLength      = (Get-OrDefault $Col.MaxLength 100)
        FormatName     = @{ Value = (Get-OrDefault $Col.Format 'Text') }   # Text, Email, Url, Phone, etc.
    }
}

function Build-MemoAttribute {
    param($Col)
    return @{
        '@odata.type'  = 'Microsoft.Dynamics.CRM.MemoAttributeMetadata'
        SchemaName     = $Col.SchemaName
        LogicalName    = $Col.LogicalName
        DisplayName    = (New-LocalizedLabel -Text $Col.Display)
        Description    = (New-LocalizedLabel -Text (Get-Desc $Col))
        RequiredLevel  = (Build-RequiredLevel $Col.Required)
        MaxLength      = (Get-OrDefault $Col.MaxLength 2000)
        Format         = 'TextArea'
    }
}

function Build-IntegerAttribute {
    param($Col)
    return @{
        '@odata.type'  = 'Microsoft.Dynamics.CRM.IntegerAttributeMetadata'
        SchemaName     = $Col.SchemaName
        LogicalName    = $Col.LogicalName
        DisplayName    = (New-LocalizedLabel -Text $Col.Display)
        Description    = (New-LocalizedLabel -Text (Get-Desc $Col))
        RequiredLevel  = (Build-RequiredLevel $Col.Required)
        MinValue       = (Get-OrDefault $Col.Min -2147483648)
        MaxValue       = (Get-OrDefault $Col.Max 2147483647)
        Format         = 'None'
    }
}

function Build-DecimalAttribute {
    param($Col)
    # MinValue/MaxValue son Edm.Decimal: PS los serializa como int si pasamos 0/10000.
    # Forzamos a [decimal] para que ConvertTo-Json los emita con decimal point (0.0, 10000.0)
    # que es lo que el deserializador OData de Dataverse espera por default.
    $body = @{
        '@odata.type'  = 'Microsoft.Dynamics.CRM.DecimalAttributeMetadata'
        SchemaName     = $Col.SchemaName
        LogicalName    = $Col.LogicalName
        DisplayName    = (New-LocalizedLabel -Text $Col.Display)
        Description    = (New-LocalizedLabel -Text (Get-Desc $Col))
        RequiredLevel  = (Build-RequiredLevel $Col.Required)
        Precision      = (Get-OrDefault $Col.Precision 2)
        MinValue       = [decimal](Get-OrDefault $Col.Min -100000000)
        MaxValue       = [decimal](Get-OrDefault $Col.Max 100000000)
    }
    return $body
}

function Build-MoneyAttribute {
    param($Col)
    return @{
        '@odata.type'   = 'Microsoft.Dynamics.CRM.MoneyAttributeMetadata'
        SchemaName      = $Col.SchemaName
        LogicalName     = $Col.LogicalName
        DisplayName     = (New-LocalizedLabel -Text $Col.Display)
        Description     = (New-LocalizedLabel -Text (Get-Desc $Col))
        RequiredLevel   = (Build-RequiredLevel $Col.Required)
        Precision       = 2
        PrecisionSource = 2          # 2 = use the currency precision
        MinValue        = (Get-OrDefault $Col.Min 0)
        MaxValue        = (Get-OrDefault $Col.Max 1000000000000)
    }
}

function Build-BooleanAttribute {
    param($Col)
    return @{
        '@odata.type'    = 'Microsoft.Dynamics.CRM.BooleanAttributeMetadata'
        SchemaName       = $Col.SchemaName
        LogicalName      = $Col.LogicalName
        DisplayName      = (New-LocalizedLabel -Text $Col.Display)
        Description      = (New-LocalizedLabel -Text (Get-Desc $Col))
        RequiredLevel    = (Build-RequiredLevel $Col.Required)
        DefaultValue     = ([bool](Get-OrDefault $Col.Default $false))
        OptionSet        = @{
            '@odata.type' = 'Microsoft.Dynamics.CRM.BooleanOptionSetMetadata'
            TrueOption    = @{
                '@odata.type' = 'Microsoft.Dynamics.CRM.OptionMetadata'
                Value = 1
                Label = (New-LocalizedLabel -Text (Get-OrDefault $Col.TrueLabel 'Yes'))
            }
            FalseOption   = @{
                '@odata.type' = 'Microsoft.Dynamics.CRM.OptionMetadata'
                Value = 0
                Label = (New-LocalizedLabel -Text (Get-OrDefault $Col.FalseLabel 'No'))
            }
        }
    }
}

function Build-DateTimeAttribute {
    param($Col)
    return @{
        '@odata.type'        = 'Microsoft.Dynamics.CRM.DateTimeAttributeMetadata'
        SchemaName           = $Col.SchemaName
        LogicalName          = $Col.LogicalName
        DisplayName          = (New-LocalizedLabel -Text $Col.Display)
        Description          = (New-LocalizedLabel -Text (Get-Desc $Col))
        RequiredLevel        = (Build-RequiredLevel $Col.Required)
        Format               = (Get-OrDefault $Col.Format 'DateOnly')  # DateOnly o DateAndTime
        DateTimeBehavior     = @{ Value = (Get-OrDefault $Col.Behavior 'UserLocal') }
    }
}

function Build-PicklistAttribute {
    param($Col)
    # Referencia a un global option set. La API exige usar el campo "GlobalOptionSet"
    # con @odata.bind a /GlobalOptionSetDefinitions(MetadataId={guid}), NO un OptionSet inline.
    $gos = Get-DataverseGlobalOptionSet -Environment $script:CurrentEnvironment -Name $Col.GlobalChoice
    if (-not $gos) { throw "Global option set '$($Col.GlobalChoice)' no encontrado. Ejecuta 02-create-choice-sets.ps1 primero." }
    return @{
        '@odata.type' = 'Microsoft.Dynamics.CRM.PicklistAttributeMetadata'
        SchemaName    = $Col.SchemaName
        LogicalName   = $Col.LogicalName
        DisplayName   = (New-LocalizedLabel -Text $Col.Display)
        Description   = (New-LocalizedLabel -Text (Get-Desc $Col))
        RequiredLevel = (Build-RequiredLevel $Col.Required)
        'GlobalOptionSet@odata.bind' = "/GlobalOptionSetDefinitions($($gos.MetadataId))"
    }
}

function Build-Attribute {
    param($Col)
    switch ($Col.Type) {
        'String'   { return (Build-StringAttribute   $Col) }
        'Memo'     { return (Build-MemoAttribute     $Col) }
        'Integer'  { return (Build-IntegerAttribute  $Col) }
        'Decimal'  { return (Build-DecimalAttribute  $Col) }
        'Money'    { return (Build-MoneyAttribute    $Col) }
        'Boolean'  { return (Build-BooleanAttribute  $Col) }
        'DateTime' { return (Build-DateTimeAttribute $Col) }
        'Picklist' { return (Build-PicklistAttribute $Col) }
        default    { throw "Tipo no soportado en script: $($Col.Type)" }
    }
}

# ==============================================================================
# Definiciones de tablas
# ==============================================================================

# Helper para definir una columna mas conciso
function Col {
    param(
        [string]$Type, [string]$Name, [string]$Display, [string]$Required = 'None',
        [int]$MaxLength = 0, [string]$Format = $null, [string]$GlobalChoice = $null,
        [string]$Description = $null, [string]$Behavior = $null, [int]$Precision = 0,
        [bool]$Default = $false, [string]$TrueLabel = $null, [string]$FalseLabel = $null
    )
    # IMPORTANTE: Dataverse deriva LogicalName del SchemaName tolowercase, IGNORANDO el LogicalName
    # que mandes en el POST. Para que LogicalName preserve underscores (snake_case), SchemaName
    # tambien debe tener underscores. Convencion: pas_nombre_corto -> Schema pas_Nombre_Corto.
    $logical = $Name.ToLower()
    if ($logical -match '^pas_(.+)$') {
        $parts = $matches[1] -split '_'
        $cap = ($parts | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join '_'
        $schema = "pas_$cap"
    } else {
        $schema = $logical
    }
    $col = @{ Type = $Type; SchemaName = $schema; LogicalName = $logical; Display = $Display; Required = $Required; Description = $Description }
    if ($MaxLength -gt 0) { $col.MaxLength = $MaxLength }
    if ($Format) { $col.Format = $Format }
    if ($GlobalChoice) { $col.GlobalChoice = $GlobalChoice }
    if ($Behavior) { $col.Behavior = $Behavior }
    if ($Precision -gt 0) { $col.Precision = $Precision }
    if ($PSBoundParameters.ContainsKey('Default')) { $col.Default = $Default }
    if ($TrueLabel) { $col.TrueLabel = $TrueLabel }
    if ($FalseLabel) { $col.FalseLabel = $FalseLabel }
    return $col
}

$tables = @(
    # ========== TABLAS DE PROCESO ==========
    @{
        LogicalName = 'pas_iniciativa'; SchemaName = 'pas_Iniciativa'
        Display = 'Iniciativa'; DisplayCollection = 'Iniciativas'
        Description = 'Entidad central del workflow de INNOVA'
        Ownership = 'UserOwned'
        PrimaryName = (Col -Type String -Name 'pas_consecutivo' -Display 'Consecutivo' -Required ApplicationRequired -MaxLength 20 -Description 'Formato INI-{ano}-{seq:00000}, generado por flow helper con lock')
        Columns = @(
            (Col -Type String   -Name 'pas_titulo'                       -Display 'Titulo'                       -Required ApplicationRequired -MaxLength 200)
            (Col -Type Memo     -Name 'pas_descripcion'                  -Display 'Descripcion'                  -Required ApplicationRequired -MaxLength 2000)
            (Col -Type Memo     -Name 'pas_descripcion_ampliada'         -Display 'Descripcion ampliada'         -MaxLength 4000)
            (Col -Type Picklist -Name 'pas_clasificacion'                -Display 'Clasificacion'                -GlobalChoice 'pas_iniciativa_clasificacion')
            (Col -Type Picklist -Name 'pas_complejidad'                  -Display 'Complejidad'                  -GlobalChoice 'pas_iniciativa_complejidad')
            (Col -Type Picklist -Name 'pas_prioridad'                    -Display 'Prioridad'                    -GlobalChoice 'pas_iniciativa_prioridad')
            (Col -Type Picklist -Name 'pas_estado'                       -Display 'Estado'                       -GlobalChoice 'pas_iniciativa_estado' -Required ApplicationRequired)
            (Col -Type Boolean  -Name 'pas_requiere_desarrollo'          -Display 'Requiere desarrollo'          -TrueLabel 'Si' -FalseLabel 'No')
            (Col -Type Boolean  -Name 'pas_es_multi_empresa'             -Display 'Es multi-empresa'             -TrueLabel 'Si' -FalseLabel 'No')
            (Col -Type Picklist -Name 'pas_decision_jefatura'            -Display 'Decision de Jefatura'         -GlobalChoice 'pas_decision')
            (Col -Type Memo     -Name 'pas_decision_jefatura_comentario' -Display 'Comentario Jefatura'          -MaxLength 2000)
            (Col -Type DateTime -Name 'pas_fecha_solicitud'              -Display 'Fecha de solicitud'           -Behavior 'UserLocal' -Format 'DateAndTime' -Description 'Fecha y hora en que el Solicitante envia la iniciativa (transicion de Borrador a En Evaluacion PMO). Distinto a createdon que es el guardado inicial.')
            (Col -Type DateTime -Name 'pas_fecha_decision_jefatura'      -Display 'Fecha decision Jefatura'      -Behavior 'UserLocal' -Format 'DateAndTime')
            (Col -Type Picklist -Name 'pas_decision_gerencia'            -Display 'Decision de Gerencia'         -GlobalChoice 'pas_decision')
            (Col -Type Memo     -Name 'pas_decision_gerencia_comentario' -Display 'Comentario Gerencia'          -MaxLength 2000)
            (Col -Type DateTime -Name 'pas_fecha_decision_gerencia'      -Display 'Fecha decision Gerencia'      -Behavior 'UserLocal' -Format 'DateAndTime')
            (Col -Type DateTime -Name 'pas_fecha_cierre_comite'          -Display 'Fecha cierre Comite'          -Behavior 'UserLocal' -Format 'DateAndTime')
            (Col -Type Money    -Name 'pas_monto_estimado'               -Display 'Monto estimado')
            (Col -Type Money    -Name 'pas_ahorro_anual_estimado'        -Display 'Ahorro anual estimado')
            (Col -Type Decimal  -Name 'pas_roi_porcentaje'               -Display 'ROI (%)'                      -Precision 2)
            (Col -Type Memo     -Name 'pas_resumen_ejecucion'            -Display 'Resumen ejecucion'            -MaxLength 4000)
            (Col -Type DateTime -Name 'pas_fecha_terminacion_ejecucion'  -Display 'Fecha terminacion ejecucion'  -Behavior 'UserLocal' -Format 'DateAndTime')
            (Col -Type Integer  -Name 'pas_anio'                         -Display 'Ano'                          -Min 2024 -Max 2100)
            (Col -Type Integer  -Name 'pas_dias_pendiente'               -Display 'Dias pendiente'               -Min 0 -Max 100000)
        )
    }
    @{
        LogicalName = 'pas_evaluacionpmo'; SchemaName = 'pas_EvaluacionPMO'
        Display = 'Evaluacion PMO'; DisplayCollection = 'Evaluaciones PMO'
        Description = 'Levantamiento y evaluacion del PMO para una iniciativa'
        Ownership = 'UserOwned'
        PrimaryName = (Col -Type String -Name 'pas_nombre' -Display 'Nombre' -Required ApplicationRequired -MaxLength 200 -Description 'Display compuesto: consecutivo iniciativa + evaluador')
        Columns = @(
            (Col -Type Picklist -Name 'pas_clasificacion_pmo' -Display 'Clasificacion PMO' -GlobalChoice 'pas_iniciativa_clasificacion')
            (Col -Type Picklist -Name 'pas_complejidad_pmo'   -Display 'Complejidad PMO'   -GlobalChoice 'pas_iniciativa_complejidad')
            (Col -Type Decimal  -Name 'pas_horas_levantamiento' -Display 'Horas de levantamiento' -Precision 2 -Min 0 -Max 10000)
            (Col -Type Money    -Name 'pas_tarifa_aplicada'   -Display 'Tarifa hora aplicada (snapshot)')
            (Col -Type Money    -Name 'pas_costo_levantamiento' -Display 'Costo de levantamiento (calculado)')
            (Col -Type Boolean  -Name 'pas_requiere_desarrollo' -Display 'Requiere desarrollo' -TrueLabel 'Si' -FalseLabel 'No')
            (Col -Type Memo     -Name 'pas_descripcion_pmo'   -Display 'Descripcion PMO'   -Required ApplicationRequired -MaxLength 4000)
            (Col -Type Memo     -Name 'pas_riesgos_pmo'       -Display 'Riesgos identificados' -MaxLength 2000)
            (Col -Type Memo     -Name 'pas_recomendacion'     -Display 'Recomendacion'     -MaxLength 2000)
            (Col -Type Picklist -Name 'pas_estado'            -Display 'Estado'            -GlobalChoice 'pas_evaluacion_estado' -Required ApplicationRequired)
            (Col -Type DateTime -Name 'pas_fecha_completada'  -Display 'Fecha completada'  -Behavior 'UserLocal' -Format 'DateAndTime')
        )
    }
    @{
        LogicalName = 'pas_evaluacionti'; SchemaName = 'pas_EvaluacionTI'
        Display = 'Evaluacion TI'; DisplayCollection = 'Evaluaciones TI'
        Description = 'Estimacion del equipo TI cuando la iniciativa requiere desarrollo'
        Ownership = 'UserOwned'
        PrimaryName = (Col -Type String -Name 'pas_nombre' -Display 'Nombre' -Required ApplicationRequired -MaxLength 200)
        Columns = @(
            (Col -Type Decimal  -Name 'pas_horas_desarrollo' -Display 'Horas de desarrollo' -Precision 2 -Min 0 -Max 100000)
            (Col -Type Decimal  -Name 'pas_horas_qa'         -Display 'Horas de QA'         -Precision 2 -Min 0 -Max 100000)
            (Col -Type Decimal  -Name 'pas_horas_otros'      -Display 'Horas otros (analisis/despliegue)' -Precision 2 -Min 0 -Max 100000)
            (Col -Type Decimal  -Name 'pas_horas_total'      -Display 'Horas total (calculado)' -Precision 2 -Min 0 -Max 1000000)
            (Col -Type Money    -Name 'pas_tarifa_aplicada'  -Display 'Tarifa hora TI aplicada (snapshot)')
            (Col -Type Money    -Name 'pas_costo_estimado'   -Display 'Costo estimado')
            (Col -Type Memo     -Name 'pas_supuestos'        -Display 'Supuestos criticos' -Required ApplicationRequired -MaxLength 4000)
            (Col -Type Memo     -Name 'pas_riesgos_tecnicos' -Display 'Riesgos tecnicos'   -MaxLength 2000)
            (Col -Type Memo     -Name 'pas_propuesta_tecnica' -Display 'Propuesta tecnica' -MaxLength 4000)
            (Col -Type Picklist -Name 'pas_estado'           -Display 'Estado'             -GlobalChoice 'pas_evaluacion_estado' -Required ApplicationRequired)
            (Col -Type DateTime -Name 'pas_fecha_completada' -Display 'Fecha completada'   -Behavior 'UserLocal' -Format 'DateAndTime')
        )
    }
    @{
        LogicalName = 'pas_cotizacion'; SchemaName = 'pas_Cotizacion'
        Display = 'Cotizacion'; DisplayCollection = 'Cotizaciones'
        Description = 'Cotizaciones para una iniciativa (max 3 enforced en UI)'
        Ownership = 'UserOwned'
        PrimaryName = (Col -Type String -Name 'pas_proveedor' -Display 'Proveedor' -Required ApplicationRequired -MaxLength 200)
        Columns = @(
            (Col -Type Picklist -Name 'pas_tipo'                 -Display 'Tipo'                 -GlobalChoice 'pas_cotizacion_tipo' -Required ApplicationRequired)
            (Col -Type Money    -Name 'pas_monto'                -Display 'Monto'                -Required ApplicationRequired)
            (Col -Type Memo     -Name 'pas_alcance'              -Display 'Alcance'              -Required ApplicationRequired -MaxLength 4000)
            (Col -Type Integer  -Name 'pas_plazo_dias'           -Display 'Plazo (dias)'         -Required ApplicationRequired -Min 1 -Max 9999)
            (Col -Type Boolean  -Name 'pas_es_ganadora'          -Display 'Es ganadora'          -TrueLabel 'Si' -FalseLabel 'No')
            (Col -Type Memo     -Name 'pas_justificacion_ganadora' -Display 'Justificacion ganadora' -MaxLength 2000)
            (Col -Type DateTime -Name 'pas_fecha_cotizacion'     -Display 'Fecha de cotizacion'  -Required ApplicationRequired -Behavior 'DateOnly' -Format 'DateOnly')
            (Col -Type String   -Name 'pas_contacto_proveedor'   -Display 'Contacto proveedor'   -MaxLength 200)
            (Col -Type String   -Name 'pas_correo_contacto'      -Display 'Correo del contacto'  -MaxLength 100 -Format 'Email')
        )
    }
    @{
        LogicalName = 'pas_horatrabajo'; SchemaName = 'pas_HoraTrabajo'
        Display = 'Hora de Trabajo'; DisplayCollection = 'Horas de Trabajo'
        Description = 'Bitacora de horas trabajadas por PMO/TI por iniciativa'
        Ownership = 'UserOwned'
        PrimaryName = (Col -Type String -Name 'pas_nombre' -Display 'Nombre' -Required ApplicationRequired -MaxLength 200)
        Columns = @(
            (Col -Type Picklist -Name 'pas_tipo'             -Display 'Tipo'             -GlobalChoice 'pas_hora_tipo' -Required ApplicationRequired)
            (Col -Type Decimal  -Name 'pas_horas'            -Display 'Horas'            -Required ApplicationRequired -Precision 2 -Min 0 -Max 9999)
            (Col -Type DateTime -Name 'pas_fecha_trabajo'    -Display 'Fecha de trabajo' -Required ApplicationRequired -Behavior 'DateOnly' -Format 'DateOnly')
            (Col -Type Memo     -Name 'pas_descripcion'      -Display 'Descripcion'      -MaxLength 2000)
            (Col -Type Money    -Name 'pas_tarifa_aplicada'  -Display 'Tarifa hora aplicada (snapshot)')
            (Col -Type Money    -Name 'pas_costo_calculado'  -Display 'Costo calculado')
        )
    }
    @{
        LogicalName = 'pas_votocomite'; SchemaName = 'pas_VotoComite'
        Display = 'Voto del Comite'; DisplayCollection = 'Votos del Comite'
        Description = 'Voto individual de un miembro del Comite sobre una iniciativa'
        Ownership = 'UserOwned'
        PrimaryName = (Col -Type String -Name 'pas_nombre' -Display 'Nombre' -Required ApplicationRequired -MaxLength 200)
        Columns = @(
            (Col -Type Picklist -Name 'pas_voto'        -Display 'Voto'        -GlobalChoice 'pas_voto' -Required ApplicationRequired)
            (Col -Type Memo     -Name 'pas_comentario'  -Display 'Comentario'  -Required ApplicationRequired -MaxLength 2000)
            (Col -Type DateTime -Name 'pas_fecha_voto'  -Display 'Fecha voto'  -Behavior 'UserLocal' -Format 'DateAndTime')
            (Col -Type Boolean  -Name 'pas_es_suplente' -Display 'Es voto de suplente' -TrueLabel 'Si' -FalseLabel 'No')
        )
    }
    @{
        LogicalName = 'pas_documentoadj'; SchemaName = 'pas_DocumentoAdj'
        Display = 'Documento Adjunto'; DisplayCollection = 'Documentos Adjuntos'
        Description = 'Metadata de archivos adjuntos (el binario vive en SharePoint)'
        Ownership = 'UserOwned'
        PrimaryName = (Col -Type String -Name 'pas_nombre_archivo' -Display 'Nombre del archivo' -Required ApplicationRequired -MaxLength 200)
        Columns = @(
            (Col -Type String   -Name 'pas_url_sharepoint' -Display 'URL en SharePoint' -Required ApplicationRequired -MaxLength 500 -Format 'Url')
            (Col -Type Picklist -Name 'pas_tipo_documento' -Display 'Tipo de documento' -GlobalChoice 'pas_documento_tipo' -Required ApplicationRequired)
            (Col -Type Integer  -Name 'pas_tamano_bytes'   -Display 'Tamano (bytes)'    -Min 0 -Max 2147483647)
            (Col -Type String   -Name 'pas_extension'      -Display 'Extension'         -MaxLength 10)
            (Col -Type Memo     -Name 'pas_descripcion'    -Display 'Descripcion'       -MaxLength 1000)
        )
    }
    # ========== TABLAS DE CONFIGURACION ==========
    @{
        LogicalName = 'pas_empresa'; SchemaName = 'pas_Empresa'
        Display = 'Empresa'; DisplayCollection = 'Empresas'
        Description = 'Empresas del Grupo Pasqui (mapea 1:1 a Business Unit del sistema)'
        Ownership = 'OrganizationOwned'
        PrimaryName = (Col -Type String -Name 'pas_nombre' -Display 'Razon social' -Required ApplicationRequired -MaxLength 200)
        Columns = @(
            (Col -Type String  -Name 'pas_nombre_corto'         -Display 'Nombre corto'         -Required ApplicationRequired -MaxLength 50)
            (Col -Type String  -Name 'pas_codigo_contable'      -Display 'Codigo contable'      -MaxLength 20)
            (Col -Type String  -Name 'pas_correo_corporativo'   -Display 'Correo corporativo'   -MaxLength 100 -Format 'Email')
            (Col -Type Boolean -Name 'pas_activa'               -Display 'Activa'               -Required ApplicationRequired -TrueLabel 'Si' -FalseLabel 'No' -Default $true)
            (Col -Type Integer -Name 'pas_orden_display'        -Display 'Orden de visualizacion' -Min 0 -Max 9999)
        )
    }
    @{
        LogicalName = 'pas_centrocosto'; SchemaName = 'pas_CentroCosto'
        Display = 'Centro de Costo'; DisplayCollection = 'Centros de Costo'
        Description = 'Catalogo de centros de costo'
        Ownership = 'OrganizationOwned'
        PrimaryName = (Col -Type String -Name 'pas_codigo' -Display 'Codigo' -Required ApplicationRequired -MaxLength 20)
        Columns = @(
            (Col -Type String  -Name 'pas_nombre' -Display 'Nombre' -Required ApplicationRequired -MaxLength 200)
            (Col -Type Boolean -Name 'pas_activo' -Display 'Activo' -Required ApplicationRequired -TrueLabel 'Si' -FalseLabel 'No' -Default $true)
        )
    }
    @{
        LogicalName = 'pas_plantillacorreo'; SchemaName = 'pas_PlantillaCorreo'
        Display = 'Plantilla de Correo'; DisplayCollection = 'Plantillas de Correo'
        Description = 'Plantillas reusables para correos automatizados'
        Ownership = 'OrganizationOwned'
        PrimaryName = (Col -Type String -Name 'pas_nombre_clave' -Display 'Nombre clave (codigo)' -Required ApplicationRequired -MaxLength 100 -Description 'Identificador estable usado por flows')
        Columns = @(
            (Col -Type String  -Name 'pas_nombre_display'           -Display 'Nombre amigable'  -Required ApplicationRequired -MaxLength 200)
            (Col -Type String  -Name 'pas_asunto'                   -Display 'Asunto'           -Required ApplicationRequired -MaxLength 200)
            (Col -Type Memo    -Name 'pas_cuerpo_html'              -Display 'Cuerpo HTML'      -Required ApplicationRequired -MaxLength 8000)
            (Col -Type Memo    -Name 'pas_descripcion'              -Display 'Descripcion'      -MaxLength 1000)
            (Col -Type Memo    -Name 'pas_variables_documentadas'   -Display 'Variables documentadas' -MaxLength 2000)
            (Col -Type Boolean -Name 'pas_activa'                   -Display 'Activa'           -Required ApplicationRequired -TrueLabel 'Si' -FalseLabel 'No' -Default $true)
        )
    }
    @{
        LogicalName = 'pas_parametro'; SchemaName = 'pas_Parametro'
        Display = 'Parametro'; DisplayCollection = 'Parametros del Sistema'
        Description = 'Single source of truth para parametros operacionales (configurables via M11)'
        Ownership = 'OrganizationOwned'
        PrimaryName = (Col -Type String -Name 'pas_clave' -Display 'Clave (codigo)' -Required ApplicationRequired -MaxLength 100 -Description 'Identificador estable usado por flows, ej. UmbralEscalamientoComite')
        Columns = @(
            (Col -Type String   -Name 'pas_nombre_display' -Display 'Nombre amigable' -Required ApplicationRequired -MaxLength 200)
            (Col -Type Picklist -Name 'pas_tipo'           -Display 'Tipo de valor'   -GlobalChoice 'pas_parametro_tipo' -Required ApplicationRequired)
            (Col -Type String   -Name 'pas_valor_texto'    -Display 'Valor (texto)'   -MaxLength 2000)
            (Col -Type Decimal  -Name 'pas_valor_numero'   -Display 'Valor (numero)'  -Precision 4 -Min -1000000000 -Max 1000000000)
            (Col -Type DateTime -Name 'pas_valor_fecha'    -Display 'Valor (fecha)'   -Behavior 'DateOnly' -Format 'DateOnly')
            (Col -Type Boolean  -Name 'pas_valor_booleano' -Display 'Valor (booleano)' -TrueLabel 'Si' -FalseLabel 'No')
            (Col -Type Memo     -Name 'pas_descripcion'    -Display 'Descripcion'     -Required ApplicationRequired -MaxLength 1000)
            (Col -Type String   -Name 'pas_unidad'         -Display 'Unidad'          -MaxLength 20)
        )
    }
    @{
        LogicalName = 'pas_miembrocomite'; SchemaName = 'pas_MiembroComite'
        Display = 'Miembro del Comite'; DisplayCollection = 'Miembros del Comite'
        Description = 'Miembros titulares + suplentes del Comite de Proyectos'
        Ownership = 'OrganizationOwned'
        PrimaryName = (Col -Type String -Name 'pas_nombre' -Display 'Nombre (display compuesto)' -Required ApplicationRequired -MaxLength 200)
        Columns = @(
            (Col -Type String   -Name 'pas_cargo'                   -Display 'Cargo institucional'  -MaxLength 200)
            (Col -Type DateTime -Name 'pas_fecha_inicio_vigencia'   -Display 'Inicio de vigencia'   -Required ApplicationRequired -Behavior 'DateOnly' -Format 'DateOnly')
            (Col -Type DateTime -Name 'pas_fecha_fin_vigencia'      -Display 'Fin de vigencia'      -Behavior 'DateOnly' -Format 'DateOnly')
            (Col -Type Boolean  -Name 'pas_activo'                  -Display 'Activo'               -Required ApplicationRequired -TrueLabel 'Si' -FalseLabel 'No' -Default $true)
            (Col -Type Integer  -Name 'pas_dias_max_voto'           -Display 'Dias maximos para votar' -Required ApplicationRequired -Min 1 -Max 90)
        )
    }
)

# ==============================================================================
# Filtrar si OnlyTable
# ==============================================================================

if ($OnlyTable) {
    $tables = $tables | Where-Object { $_.LogicalName -eq $OnlyTable }
    if (-not $tables) { throw "Tabla '$OnlyTable' no esta en el set definido" }
    Write-Host "Filtrado a tabla: $OnlyTable" -ForegroundColor DarkGray
}

# ==============================================================================
# Ejecucion
# ==============================================================================

$tableStats = @{ Created = 0; Skipped = 0; Failed = 0 }
$colStats   = @{ Created = 0; Skipped = 0; Failed = 0 }

foreach ($t in $tables) {
    Write-Host "`n--- $($t.LogicalName) ($($t.Display)) ---" -ForegroundColor Cyan

    # 1) Crear EntityDefinition si no existe (con primary attribute en el mismo POST)
    $existing = Get-DataverseEntity -Environment $Environment -LogicalName $t.LogicalName
    if ($existing) {
        Write-Host "  Tabla ya existe (id: $($existing.MetadataId))" -ForegroundColor DarkYellow
        $tableStats.Skipped++
    } else {
        $primaryAttr = Build-Attribute $t.PrimaryName
        $primaryAttr.IsPrimaryName = $true
        $entityBody = @{
            '@odata.type'           = 'Microsoft.Dynamics.CRM.EntityMetadata'
            SchemaName              = $t.SchemaName
            LogicalName             = $t.LogicalName
            DisplayName             = (New-LocalizedLabel -Text $t.Display)
            DisplayCollectionName   = (New-LocalizedLabel -Text $t.DisplayCollection)
            Description             = (New-LocalizedLabel -Text $t.Description)
            OwnershipType           = $t.Ownership
            HasActivities           = $false
            HasNotes                = $false
            IsActivity              = $false
            IsAuditEnabled          = @{ Value = $true; CanBeChanged = $true; ManagedPropertyLogicalName = 'canmodifyauditsettings' }
            IsValidForQueue         = @{ Value = $false; CanBeChanged = $true; ManagedPropertyLogicalName = 'canmodifyqueuesettings' }
            PrimaryNameAttribute    = $t.PrimaryName.LogicalName
            Attributes              = @($primaryAttr)
        }

        if ($PSCmdlet.ShouldProcess($t.LogicalName, "Create EntityDefinition")) {
            try {
                Invoke-DataverseApi -Environment $Environment -Method POST -Path 'EntityDefinitions' -Body $entityBody -SolutionUniqueName $Solution | Out-Null
                Write-Host "  [OK] tabla creada" -ForegroundColor Green
                $tableStats.Created++
            } catch {
                Write-Host "  [FAIL] tabla: $($_.Exception.Message)" -ForegroundColor Red
                $tableStats.Failed++
                continue
            }
        } else {
            Write-Host "  [WHATIF] crearia tabla con primary $($t.PrimaryName.LogicalName)" -ForegroundColor Magenta
            $tableStats.Created++
        }
    }

    # 2) Crear cada columna no-primary
    foreach ($col in $t.Columns) {
        $existingCol = Get-DataverseAttribute -Environment $Environment -EntityLogicalName $t.LogicalName -AttributeLogicalName $col.LogicalName
        if ($existingCol) {
            Write-Host "    [SKIP] $($col.LogicalName)" -ForegroundColor DarkYellow
            $colStats.Skipped++
            continue
        }

        $colBody = Build-Attribute $col
        if ($PSCmdlet.ShouldProcess($col.LogicalName, "Add column to $($t.LogicalName)")) {
            try {
                Invoke-DataverseApi -Environment $Environment -Method POST -Path "EntityDefinitions(LogicalName='$($t.LogicalName)')/Attributes" -Body $colBody -SolutionUniqueName $Solution | Out-Null
                Write-Host "    [OK] $($col.LogicalName) ($($col.Type))" -ForegroundColor Green
                $colStats.Created++
            } catch {
                Write-Host "    [FAIL] $($col.LogicalName): $($_.Exception.Message)" -ForegroundColor Red
                $colStats.Failed++
            }
        } else {
            Write-Host "    [WHATIF] $($col.LogicalName) ($($col.Type))" -ForegroundColor Magenta
            $colStats.Created++
        }
    }
}

Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
Write-Host "Tablas:   Created=$($tableStats.Created) Skipped=$($tableStats.Skipped) Failed=$($tableStats.Failed)"
Write-Host "Columnas: Created=$($colStats.Created)   Skipped=$($colStats.Skipped)   Failed=$($colStats.Failed)"
if ($tableStats.Failed -gt 0 -or $colStats.Failed -gt 0) {
    Write-Host "=== HUBO FALLAS - revisar arriba ===" -ForegroundColor Red
    exit 1
}
Write-Host "=== OK ===`n" -ForegroundColor Green
