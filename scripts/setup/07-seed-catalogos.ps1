<#
.SYNOPSIS
    Sembrar catalogos placeholder en INNOVA (S0-10 / issue #21).

.DESCRIPTION
    Crea los datos placeholder de catalogos para que cualquier dev pueda trabajar
    sobre DEV vacio. Mismo script aplica para DEV/QA/PROD-cliente — los valores
    reales se ajustan via M11 (Admin) despues.

    Catalogos sembrados:
      - pas_empresa            (3 empresas placeholder con codigo_corto para G7)
      - pas_centrocosto        (3 CCs por empresa)
      - pas_departamento       (3 deptos por empresa, consume G1)
      - pas_sistema            (3 sistemas por empresa, consume G2)
      - pas_plantillacorreo    (5 plantillas genericas)
      - pas_miembrocomite      (3 miembros placeholder)

    Idempotente: si la clave ya existe, salta (no sobreescribe).
    Flag -ForceUpdate para reset.

    Parametros operacionales: ya estan seedeados por 06-seed-parametros.ps1 (G8).

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER ForceUpdate
    Sobreescribe valores existentes. Default: skip si existe.

.PARAMETER SkipMiembrosComite
    Salta el seed de miembros del comite (util si los systemuser placeholder
    no existen en el environment).

.PARAMETER WhatIf
    Dry-run.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',
    [switch]$ForceUpdate,
    [switch]$SkipMiembrosComite
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\lib\dataverse.ps1"

$Solution = 'innova_core'

Write-Host "`n=== INNOVA S0-10: Seed Catalogos en $($Environment.ToUpper()) ===" -ForegroundColor Cyan
Initialize-DataverseSession | Out-Null

# ==============================================================================
# Helpers genericos
# ==============================================================================

function Get-Record {
    param(
        [Parameter(Mandatory)] [string]$Environment,
        [Parameter(Mandatory)] [string]$EntitySet,   # ej. 'pas_empresas'
        [Parameter(Mandatory)] [string]$Filter        # ej. "pas_codigo_corto eq 'COA'"
    )
    $result = Invoke-DataverseApi -Environment $Environment -Method GET `
        -Path "${EntitySet}?`$filter=$Filter&`$top=1"
    if ($result.value -and $result.value.Count -gt 0) {
        return $result.value[0]
    }
    return $null
}

function Upsert-Record {
    param(
        [string]$EntitySet,
        [string]$KeyFilter,
        [string]$Label,
        [hashtable]$Body,
        [string]$IdProperty   # ej. 'pas_empresaid'
    )
    try {
        $existing = Get-Record -Environment $Environment -EntitySet $EntitySet -Filter $KeyFilter
        if ($existing) {
            if ($ForceUpdate) {
                if ($PSCmdlet.ShouldProcess($Label, "Force-update")) {
                    Invoke-DataverseApi -Environment $Environment -Method PATCH `
                        -Path "$EntitySet($($existing.$IdProperty))" `
                        -Body $Body -SolutionUniqueName $Solution | Out-Null
                    Write-Host "  [UPDATE] $Label" -ForegroundColor Yellow
                    return $existing.$IdProperty
                }
            } else {
                Write-Host "  [SKIP]   $Label" -ForegroundColor DarkYellow
                return $existing.$IdProperty
            }
        }
        if ($PSCmdlet.ShouldProcess($Label, "Create")) {
            $new = Invoke-DataverseApi -Environment $Environment -Method POST `
                -Path $EntitySet -Body $Body -PreferReturn -SolutionUniqueName $Solution
            Write-Host "  [OK]     $Label (id: $($new.$IdProperty))" -ForegroundColor Green
            return $new.$IdProperty
        }
    } catch {
        Write-Host "  [FAIL]   ${Label}: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# ==============================================================================
# 1) Empresas
# ==============================================================================

Write-Host "`n--- pas_empresa (3 placeholders) ---" -ForegroundColor Cyan

$empresas = @(
    @{ Nombre = 'Empresa A (placeholder)'; NombreCorto = 'EmpA';     CodigoCorto = 'EMA'; CodigoContable = 'EA-001'; Correo = 'empresa-a@placeholder.local';  Orden = 10 }
    @{ Nombre = 'Empresa B (placeholder)'; NombreCorto = 'EmpB';     CodigoCorto = 'EMB'; CodigoContable = 'EB-001'; Correo = 'empresa-b@placeholder.local';  Orden = 20 }
    @{ Nombre = 'Empresa C (placeholder)'; NombreCorto = 'EmpC';     CodigoCorto = 'EMC'; CodigoContable = 'EC-001'; Correo = 'empresa-c@placeholder.local';  Orden = 30 }
)

$empresaIds = @{}   # NombreCorto -> guid
foreach ($e in $empresas) {
    $body = @{
        pas_nombre              = $e.Nombre
        pas_nombre_corto        = $e.NombreCorto
        pas_codigo_corto        = $e.CodigoCorto
        pas_codigo_contable     = $e.CodigoContable
        pas_correo_corporativo  = $e.Correo
        pas_activa              = $true
        pas_orden_display       = $e.Orden
    }
    $id = Upsert-Record -EntitySet 'pas_empresas' `
        -KeyFilter ("pas_codigo_corto eq '" + $e.CodigoCorto + "'") `
        -Label "Empresa $($e.CodigoCorto) - $($e.Nombre)" `
        -Body $body -IdProperty 'pas_empresaid'
    if ($id) { $empresaIds[$e.NombreCorto] = $id }
}

# ==============================================================================
# 2) Centros de costo (3 por empresa)
# ==============================================================================

Write-Host "`n--- pas_centrocosto (9 placeholders: 3 x empresa) ---" -ForegroundColor Cyan

$ccsPorEmpresa = @(
    @{ Codigo = 'CC-001'; Nombre = 'CC General (placeholder)' }
    @{ Codigo = 'CC-002'; Nombre = 'CC Operativo (placeholder)' }
    @{ Codigo = 'CC-003'; Nombre = 'CC Administrativo (placeholder)' }
)

foreach ($empCorto in $empresaIds.Keys) {
    $empId = $empresaIds[$empCorto]
    foreach ($cc in $ccsPorEmpresa) {
        $codigoCompuesto = "$($cc.Codigo)-$empCorto"
        $body = @{
            pas_codigo = $codigoCompuesto
            pas_nombre = "$($cc.Nombre) [$empCorto]"
            pas_activo = $true
            'pas_Empresa@odata.bind' = "/pas_empresas($empId)"
        }
        Upsert-Record -EntitySet 'pas_centrocostos' `
            -KeyFilter ("pas_codigo eq '$codigoCompuesto'") `
            -Label "CC $codigoCompuesto" `
            -Body $body -IdProperty 'pas_centrocostoid' | Out-Null
    }
}

# ==============================================================================
# 3) Departamentos (3 por empresa, consume G1)
# ==============================================================================

Write-Host "`n--- pas_departamento (9 placeholders: 3 x empresa) ---" -ForegroundColor Cyan

$deptsPorEmpresa = @(
    @{ Codigo = 'DEPT-OPS';   Nombre = 'Operaciones (placeholder)' }
    @{ Codigo = 'DEPT-FIN';   Nombre = 'Finanzas (placeholder)' }
    @{ Codigo = 'DEPT-IT';    Nombre = 'Tecnologia (placeholder)' }
)

foreach ($empCorto in $empresaIds.Keys) {
    $empId = $empresaIds[$empCorto]
    foreach ($dep in $deptsPorEmpresa) {
        $codigoCompuesto = "$($dep.Codigo)-$empCorto"
        $body = @{
            pas_nombre      = "$($dep.Nombre) [$empCorto]"
            pas_codigo      = $codigoCompuesto
            pas_descripcion = "Departamento placeholder para $empCorto. Reemplazar via M11 Admin con catalogo real del cliente."
            pas_activo      = $true
            'pas_Empresa@odata.bind' = "/pas_empresas($empId)"
        }
        # pas_departamento NO tiene pas_codigo como Primary; usar pas_nombre como filtro
        $filterName = "$($dep.Nombre) [$empCorto]".Replace("'", "''")
        Upsert-Record -EntitySet 'pas_departamentos' `
            -KeyFilter ("pas_nombre eq '$filterName'") `
            -Label "Depto $codigoCompuesto" `
            -Body $body -IdProperty 'pas_departamentoid' | Out-Null
    }
}

# ==============================================================================
# 4) Sistemas (3 por empresa, consume G2)
# ==============================================================================

Write-Host "`n--- pas_sistema (9 placeholders: 3 x empresa) ---" -ForegroundColor Cyan

$sistemasPorEmpresa = @(
    @{ Codigo = 'SYS-ERP';  Nombre = 'ERP Corporativo (placeholder)' }
    @{ Codigo = 'SYS-CRM';  Nombre = 'CRM (placeholder)' }
    @{ Codigo = 'SYS-DW';   Nombre = 'Data Warehouse (placeholder)' }
)

foreach ($empCorto in $empresaIds.Keys) {
    $empId = $empresaIds[$empCorto]
    foreach ($sys in $sistemasPorEmpresa) {
        $codigoCompuesto = "$($sys.Codigo)-$empCorto"
        $body = @{
            pas_nombre      = "$($sys.Nombre) [$empCorto]"
            pas_codigo      = $codigoCompuesto
            pas_descripcion = "Sistema placeholder para $empCorto. Reemplazar via M11 Admin con catalogo real."
            pas_activo      = $true
            'pas_Empresa@odata.bind' = "/pas_empresas($empId)"
        }
        $filterName = "$($sys.Nombre) [$empCorto]".Replace("'", "''")
        Upsert-Record -EntitySet 'pas_sistemas' `
            -KeyFilter ("pas_nombre eq '$filterName'") `
            -Label "Sistema $codigoCompuesto" `
            -Body $body -IdProperty 'pas_sistemaid' | Out-Null
    }
}

# ==============================================================================
# 5) Plantillas de correo (5 genericas)
# ==============================================================================

Write-Host "`n--- pas_plantillacorreo (5 plantillas placeholder) ---" -ForegroundColor Cyan

# Tipo en pas_parametro_tipo NO aplica aqui. La plantilla tiene su propio shape.
$plantillas = @(
    @{
        Clave   = 'iniciativa_creada_pmo'
        Display = 'Notificacion al PMO de nueva iniciativa'
        Asunto  = '[INNOVA] Nueva iniciativa requiere evaluacion - {consecutivo}'
        Cuerpo  = @'
<p>Hola PMO,</p>
<p>La iniciativa <b>{consecutivo}</b> "<b>{titulo}</b>" fue enviada por {solicitante} y requiere tu evaluacion.</p>
<p><a href="{urlIniciativa}">Abrir en INNOVA</a></p>
<p style="color:#888;font-size:11px">Esta es una plantilla PLACEHOLDER. Editar via M11 Admin con la voz/tono del cliente.</p>
'@
        Descripcion = 'Disparada por flow al crear iniciativa o pasar a Revision inicial PMO.'
        Variables   = '{consecutivo}, {titulo}, {solicitante}, {urlIniciativa}'
    }
    @{
        Clave   = 'iniciativa_estimacion_jefatura'
        Display = 'Notificacion a Jefatura para revisar estimacion'
        Asunto  = '[INNOVA] Estimacion lista para tu revision - {consecutivo}'
        Cuerpo  = @'
<p>Hola {jefatura},</p>
<p>La iniciativa <b>{consecutivo}</b> "<b>{titulo}</b>" ya tiene la estimacion de Desarrollo lista para tu revision.</p>
<p>Monto estimado: <b>{montoEstimado}</b></p>
<p><a href="{urlIniciativa}">Revisar y decidir</a></p>
<p style="color:#888;font-size:11px">Placeholder. Editar via M11.</p>
'@
        Descripcion = 'Disparada al pasar a Revision Estimacion de la Jefatura.'
        Variables   = '{consecutivo}, {titulo}, {jefatura}, {montoEstimado}, {urlIniciativa}'
    }
    @{
        Clave   = 'iniciativa_aprobada_gerencia'
        Display = 'Notificacion al solicitante - aprobada por Gerencia'
        Asunto  = '[INNOVA] Tu iniciativa fue aprobada - {consecutivo}'
        Cuerpo  = @'
<p>Hola {solicitante},</p>
<p>Tu iniciativa <b>{consecutivo}</b> "<b>{titulo}</b>" fue <b style="color:green">APROBADA por Gerencia General</b>.</p>
<p>Proximo paso: el PMO coordinara la ejecucion.</p>
<p><a href="{urlIniciativa}">Ver detalle</a></p>
<p style="color:#888;font-size:11px">Placeholder. Editar via M11.</p>
'@
        Descripcion = 'Disparada al pasar a Aprobada por Gerencia General de Negocio.'
        Variables   = '{consecutivo}, {titulo}, {solicitante}, {urlIniciativa}'
    }
    @{
        Clave   = 'iniciativa_recordatorio_3dias'
        Display = 'Recordatorio de inactividad'
        Asunto  = '[INNOVA] Recordatorio: iniciativa {consecutivo} pendiente desde hace {diasPendiente} dias'
        Cuerpo  = @'
<p>Hola {duenioActual},</p>
<p>La iniciativa <b>{consecutivo}</b> "<b>{titulo}</b>" lleva <b>{diasPendiente}</b> dias en estado <b>{estado}</b> sin cambios.</p>
<p><a href="{urlIniciativa}">Atender</a></p>
<p style="color:#888;font-size:11px">Placeholder. Frecuencia configurable en pas_parametro.DiasRecordatorio.</p>
'@
        Descripcion = 'Disparada por flow scheduled si la iniciativa no cambia de estado en DiasRecordatorio dias.'
        Variables   = '{consecutivo}, {titulo}, {duenioActual}, {diasPendiente}, {estado}, {urlIniciativa}'
    }
    @{
        Clave   = 'iniciativa_comite_voto'
        Display = 'Solicitud de voto al Comite'
        Asunto  = '[INNOVA] Solicitud de voto - {consecutivo}'
        Cuerpo  = @'
<p>Estimado(a) miembro del Comite,</p>
<p>La iniciativa <b>{consecutivo}</b> "<b>{titulo}</b>" escala al Comite por {razonEscalamiento}.</p>
<p>Monto: <b>{montoEstimado}</b> | Multi-empresa: <b>{esMultiEmpresa}</b></p>
<p>Tienes {diasMaxVoto} dias para votar.</p>
<p><a href="{urlIniciativa}">Revisar y votar</a></p>
<p style="color:#888;font-size:11px">Placeholder. Editar via M11.</p>
'@
        Descripcion = 'Disparada al pasar a Revision Comite de Proyectos.'
        Variables   = '{consecutivo}, {titulo}, {razonEscalamiento}, {montoEstimado}, {esMultiEmpresa}, {diasMaxVoto}, {urlIniciativa}'
    }
)

foreach ($p in $plantillas) {
    $body = @{
        pas_nombre_clave            = $p.Clave
        pas_nombre_display          = $p.Display
        pas_asunto                  = $p.Asunto
        pas_cuerpo_html             = $p.Cuerpo
        pas_descripcion             = $p.Descripcion
        pas_variables_documentadas  = $p.Variables
        pas_activa                  = $true
    }
    Upsert-Record -EntitySet 'pas_plantillacorreos' `
        -KeyFilter ("pas_nombre_clave eq '" + $p.Clave + "'") `
        -Label "Plantilla $($p.Clave)" `
        -Body $body -IdProperty 'pas_plantillacorreoid' | Out-Null
}

# ==============================================================================
# 6) Miembros del Comite (3 placeholders)
# ==============================================================================

if ($SkipMiembrosComite) {
    Write-Host "`n--- pas_miembrocomite SKIPPED por flag -SkipMiembrosComite ---" -ForegroundColor DarkGray
} else {
    Write-Host "`n--- pas_miembrocomite (3 placeholders) ---" -ForegroundColor Cyan

    # Para placeholders: usa el usuario que esta corriendo el script como titular de los 3.
    # Trivialmente editable via M11 con los usuarios reales del comite.
    $whoami = Invoke-DataverseApi -Environment $Environment -Method GET -Path 'WhoAmI'
    $miUserId = $whoami.UserId
    if (-not $miUserId) {
        Write-Host "  [WARN] No se pudo obtener UserId via WhoAmI; saltando miembros." -ForegroundColor Yellow
    } else {
        Write-Host "  Usuario para placeholders: $miUserId" -ForegroundColor DarkGray

        $miembros = @(
            @{ Nombre = 'Miembro Comite 1 (placeholder)'; Cargo = 'Director Ejecutivo';  DiasMax = 3 }
            @{ Nombre = 'Miembro Comite 2 (placeholder)'; Cargo = 'Gerente Operaciones'; DiasMax = 3 }
            @{ Nombre = 'Miembro Comite 3 (placeholder)'; Cargo = 'Gerente Finanzas';    DiasMax = 5 }
        )

        $hoy = (Get-Date).ToString('yyyy-MM-dd')

        foreach ($m in $miembros) {
            $body = @{
                pas_nombre                  = $m.Nombre
                pas_cargo                   = $m.Cargo
                pas_fecha_inicio_vigencia   = $hoy
                pas_activo                  = $true
                pas_dias_max_voto           = $m.DiasMax
                'pas_Titular@odata.bind'    = "/systemusers($miUserId)"
            }
            $filterName = $m.Nombre.Replace("'", "''")
            Upsert-Record -EntitySet 'pas_miembrocomites' `
                -KeyFilter ("pas_nombre eq '$filterName'") `
                -Label "Miembro $($m.Nombre)" `
                -Body $body -IdProperty 'pas_miembrocomiteid' | Out-Null
        }
    }
}

Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
Write-Host "Catalogos sembrados. Re-ejecutar para verificar idempotencia." -ForegroundColor DarkGray
Write-Host "Nota: parametros operacionales viven en 06-seed-parametros.ps1 (G8)." -ForegroundColor DarkGray
Write-Host "=== OK ===`n" -ForegroundColor Green
