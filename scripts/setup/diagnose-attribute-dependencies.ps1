#Requires -Version 7.0
<#
.SYNOPSIS
    Diagnostica que componentes (forms, views, charts, business rules, flows, etc.)
    estan referenciando un attribute, impidiendo su DELETE.

.DESCRIPTION
    Cuando el Web API responde con error 0x8004f01f al intentar borrar un attribute,
    significa que hay 1+ componentes que dependen de el. Este script usa la accion
    RetrieveDependenciesForDeleteRequest para listarlos con info accionable (tipo,
    GUID, nombre del owner, solution donde vive).

    Tipos comunes que aparecen:
      SystemForm (componenttype=60)       -> form del model-driven app
      SavedQuery (componenttype=26)       -> view publica
      UserQuery  (componenttype=4230)     -> view personal
      Chart      (componenttype=59)       -> chart en form
      Workflow   (componenttype=29)       -> classic workflow o cloud flow
      Process    (componenttype=29 misc)  -> business rule
      ViewAttribute(?)                    -> referencias dentro de columnas de view
    Si la dependencia es un form: abrir el form en make.powerapps.com, remover el campo,
    Save + Publish, re-correr migrate.

.PARAMETER Environment
    'dev' o 'qa'. Default 'dev'.

.PARAMETER Entity
    LogicalName de la tabla (ej. pas_iniciativa).

.PARAMETER Attribute
    LogicalName del attribute (ej. pas_clasificacion).

.EXAMPLE
    pwsh ./scripts/setup/diagnose-attribute-dependencies.ps1 -Entity pas_iniciativa -Attribute pas_clasificacion
#>
[CmdletBinding()]
param(
    [ValidateSet('dev','qa')]
    [string]$Environment = 'dev',
    [Parameter(Mandatory)]
    [string]$Entity,
    [Parameter(Mandatory)]
    [string]$Attribute
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$envFile  = Join-Path $repoRoot ".env.$Environment"
if (-not (Test-Path $envFile)) { throw "No existe $envFile" }

$envVars = @{}
Get-Content $envFile | Where-Object { $_ -and -not $_.StartsWith('#') -and $_ -match '=' } | ForEach-Object {
    $k,$v = $_ -split '=',2; $envVars[$k.Trim()] = $v.Trim()
}
$envUrl = $envVars["INNOVA_$($Environment.ToUpper())_URL"].TrimEnd('/')

$tokenRes = Invoke-RestMethod -Method POST `
    -Uri "https://login.microsoftonline.com/$($envVars['INNOVA_TENANT_ID'])/oauth2/v2.0/token" `
    -Body @{
        client_id     = $envVars['INNOVA_SP_CLIENT_ID']
        client_secret = $envVars['INNOVA_SP_CLIENT_SECRET']
        scope         = "$envUrl/.default"
        grant_type    = 'client_credentials'
    }
$apiBase = "$envUrl/api/data/v9.2"
$h = @{ Authorization = "Bearer $($tokenRes.access_token)"; Accept = 'application/json' }

# Map de componenttype id -> nombre legible (subset comun)
$componentTypeMap = @{
    1    = 'Entity'
    2    = 'Attribute'
    3    = 'Relationship'
    9    = 'OptionSet'
    10   = 'EntityRelationship'
    24   = 'Form (SystemForm legacy?)'
    26   = 'SavedQuery (Public view)'
    29   = 'Workflow / Business Rule / Cloud Flow'
    59   = 'SavedQueryVisualization (Chart)'
    60   = 'SystemForm (Form)'
    61   = 'WebResource'
    62   = 'SiteMap'
    65   = 'HierarchyRule'
    66   = 'CustomControl'
    79   = 'AppModule'
    80   = 'AppModuleComponent'
    300  = 'CustomControlDefaultConfig'
    4230 = 'UserQuery (Personal view)'
    7100 = 'PluginAssembly'
    7101 = 'SdkMessageProcessingStep'
}
function Get-ComponentTypeName { param([int]$t) if ($componentTypeMap.ContainsKey($t)) { return $componentTypeMap[$t] } else { return "Unknown ($t)" } }

Write-Host "`n=== Diagnostico dependencies: $Entity.$Attribute ===" -ForegroundColor Cyan

# 1. Obtener MetadataId del attribute
Write-Host "`n[1/2] Obteniendo MetadataId..." -ForegroundColor Yellow
try {
    $attr = Invoke-RestMethod -Uri "$apiBase/EntityDefinitions(LogicalName='$Entity')/Attributes(LogicalName='$Attribute')" -Headers $h
    $metaId = $attr.MetadataId
    Write-Host "  MetadataId: $metaId" -ForegroundColor DarkGray
    Write-Host "  AttributeType: $($attr.AttributeType)" -ForegroundColor DarkGray
} catch {
    Write-Host "  [FAIL] no existe el attribute $Entity.$Attribute" -ForegroundColor Red
    exit 1
}

# 2. Consultar RetrieveDependenciesForDeleteRequest
Write-Host "`n[2/2] Consultando RetrieveDependenciesForDeleteRequest..." -ForegroundColor Yellow
$url = "$apiBase/RetrieveDependenciesForDelete(ObjectId=@p1,ComponentType=@p2)?@p1=$metaId&@p2=2"
$deps = Invoke-RestMethod -Uri $url -Headers $h

if (-not $deps.value -or $deps.value.Count -eq 0) {
    Write-Host "  [OK] sin dependencias - el DELETE deberia funcionar." -ForegroundColor Green
    exit 0
}

Write-Host "`nDependencias encontradas: $($deps.value.Count)" -ForegroundColor Magenta
Write-Host ("-" * 100) -ForegroundColor DarkGray

$i = 0
foreach ($d in $deps.value) {
    $i++
    $depType   = Get-ComponentTypeName ([int]$d.dependentcomponenttype)
    $depName   = $d.dependentcomponentbasesolutionid
    Write-Host "`n[Dependencia $i de $($deps.value.Count)]" -ForegroundColor Cyan
    Write-Host "  dependentcomponenttype:   $($d.dependentcomponenttype) ($depType)" -ForegroundColor White
    Write-Host "  dependentcomponentobjectid: $($d.dependentcomponentobjectid)" -ForegroundColor White
    Write-Host "  dependentcomponentbasesolutionid: $depName" -ForegroundColor DarkGray

    # Lookup amistoso del componente segun tipo
    switch ([int]$d.dependentcomponenttype) {
        60 {
            # SystemForm -> obtener Name del form
            try {
                $form = Invoke-RestMethod -Uri "$apiBase/systemforms($($d.dependentcomponentobjectid))?`$select=name,type,objecttypecode,formid" -Headers $h
                Write-Host "  [INFO] form: '$($form.name)' (objecttypecode=$($form.objecttypecode), type=$($form.type))" -ForegroundColor Yellow
                Write-Host "  FIX: abrir https://make.powerapps.com -> Solutions -> entidad $($form.objecttypecode) -> Forms -> '$($form.name)' -> remover campo $Attribute -> Save -> Publish" -ForegroundColor Green
            } catch {
                Write-Host "  [WARN] no pude leer systemform $($d.dependentcomponentobjectid): $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
        26 {
            try {
                $view = Invoke-RestMethod -Uri "$apiBase/savedqueries($($d.dependentcomponentobjectid))?`$select=name,returnedtypecode,querytype" -Headers $h
                Write-Host "  [INFO] view publica: '$($view.name)' (entidad=$($view.returnedtypecode))" -ForegroundColor Yellow
                Write-Host "  FIX: abrir Solutions -> entidad -> Views -> '$($view.name)' -> remover columna $Attribute -> Save -> Publish" -ForegroundColor Green
            } catch {
                Write-Host "  [WARN] no pude leer savedquery: $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
        29 {
            try {
                $wf = Invoke-RestMethod -Uri "$apiBase/workflows($($d.dependentcomponentobjectid))?`$select=name,category,type,statecode" -Headers $h
                $catMap = @{ 0='Workflow'; 1='Dialog'; 2='Business Rule'; 3='Action'; 4='Business Process Flow'; 5='Modern Flow'; 6='Desktop Flow' }
                $catName = if ($catMap.ContainsKey([int]$wf.category)) { $catMap[[int]$wf.category] } else { "category=$($wf.category)" }
                Write-Host "  [INFO] workflow: '$($wf.name)' ($catName, statecode=$($wf.statecode))" -ForegroundColor Yellow
                Write-Host "  FIX: si es Business Rule o Flow que usa $Attribute, edita y remueve la referencia o desactivalo." -ForegroundColor Green
            } catch {
                Write-Host "  [WARN] no pude leer workflow: $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
        59 {
            Write-Host "  [INFO] chart - remover desde Solutions -> entidad -> Charts" -ForegroundColor Yellow
        }
        default {
            Write-Host "  [INFO] tipo $($d.dependentcomponenttype) - lookup manual via Advanced Find / make.powerapps.com" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=== Resumen ===" -ForegroundColor Cyan
Write-Host "Total dependencias: $($deps.value.Count). Hay que resolver cada una antes de re-correr migrate-pas-clasificacion-to-multiselect.ps1." -ForegroundColor White
