<#
.SYNOPSIS
    Librería helper para llamadas Web API contra Dataverse.

.DESCRIPTION
    Provee funciones reusables para todos los scripts de provisioning en scripts/setup/.
    Asume que el usuario tiene Az.Accounts instalado y autenticado al tenant correcto
    via Connect-AzAccount (ver docs/setup-mcp.md para setup inicial).

.NOTES
    Cargar via: . "$PSScriptRoot\lib\dataverse.ps1"
#>

# ==============================================================================
# Constantes del proyecto
# ==============================================================================

$script:DataverseEnvironments = @{
    'dev' = 'https://org93905a7d.crm.dynamics.com'
    'qa'  = 'https://org8b65c4d6.crm.dynamics.com'
}

# ==============================================================================
# Auth
# ==============================================================================

function Initialize-DataverseSession {
    <#
    .SYNOPSIS
        Asegura que Az.Accounts esta cargado y conectado al tenant correcto.
    #>
    if (-not (Get-Module -ListAvailable Az.Accounts)) {
        throw "Az.Accounts no instalado. Ejecuta: Install-Module Az.Accounts -Scope CurrentUser"
    }
    Import-Module Az.Accounts -ErrorAction Stop

    $ctx = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $ctx) {
        throw "No hay sesion Az activa. Ejecuta: Connect-AzAccount -UseDeviceAuthentication"
    }

    Write-Host "  Az session: $($ctx.Account.Id) @ tenant $($ctx.Tenant.Id)" -ForegroundColor DarkGray
    return $ctx
}

function Get-DataverseToken {
    <#
    .SYNOPSIS
        Obtiene un bearer token para llamar al Web API del environment indicado.
    .PARAMETER Environment
        Nombre del environment: 'dev' o 'qa'.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('dev','qa')]
        [string]$Environment
    )

    $url = $script:DataverseEnvironments[$Environment]
    $tokenObj = Get-AzAccessToken -ResourceUrl "$url/" -ErrorAction Stop

    # Az 5.x devuelve SecureString por default; Az 4.x devuelve string plano.
    if ($tokenObj.Token -is [System.Security.SecureString]) {
        return (New-Object System.Net.NetworkCredential('', $tokenObj.Token)).Password
    }
    return $tokenObj.Token
}

# ==============================================================================
# Web API helpers
# ==============================================================================

function Invoke-DataverseApi {
    <#
    .SYNOPSIS
        Llama al Web API de Dataverse con headers OData estandar.
    .PARAMETER Environment
        Nombre del environment: 'dev' o 'qa'.
    .PARAMETER Method
        GET / POST / PATCH / DELETE.
    .PARAMETER Path
        Path relativo despues de /api/data/v9.2/  (ej: 'businessunits', 'WhoAmI').
    .PARAMETER Body
        Para POST/PATCH: hashtable o PSCustomObject (se serializa a JSON).
    .PARAMETER PreferReturn
        Si se incluye, agrega Prefer: return=representation para que POST devuelva el registro creado.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('dev','qa')]
        [string]$Environment,

        [Parameter(Mandatory)]
        [ValidateSet('GET','POST','PATCH','DELETE')]
        [string]$Method,

        [Parameter(Mandatory)]
        [string]$Path,

        [object]$Body = $null,

        [switch]$PreferReturn
    )

    $token = Get-DataverseToken -Environment $Environment
    $url = $script:DataverseEnvironments[$Environment]
    $fullUrl = "$url/api/data/v9.2/$Path"

    $headers = @{
        'Authorization' = "Bearer $token"
        'OData-MaxVersion' = '4.0'
        'OData-Version' = '4.0'
        'Accept' = 'application/json'
        'Content-Type' = 'application/json; charset=utf-8'
    }
    if ($PreferReturn) {
        $headers['Prefer'] = 'return=representation'
    }

    $params = @{
        Uri = $fullUrl
        Method = $Method
        Headers = $headers
        ErrorAction = 'Stop'
    }

    if ($Body -ne $null) {
        $params['Body'] = ($Body | ConvertTo-Json -Depth 20 -Compress)
    }

    try {
        return Invoke-RestMethod @params
    } catch {
        $errMsg = $_.Exception.Message
        $errBody = $null
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            try {
                $errBody = ($_.ErrorDetails.Message | ConvertFrom-Json).error.message
            } catch {
                $errBody = $_.ErrorDetails.Message
            }
        }
        $detail = if ($errBody) { $errBody } else { $errMsg }
        throw "Dataverse API call failed [$Method $Path]: $detail"
    }
}

# ==============================================================================
# Idempotencia
# ==============================================================================

function Get-DataverseBusinessUnit {
    <#
    .SYNOPSIS
        Busca una Business Unit por nombre. Devuelve $null si no existe.
    #>
    param(
        [Parameter(Mandatory)] [ValidateSet('dev','qa')] [string]$Environment,
        [Parameter(Mandatory)] [string]$Name
    )

    $escaped = $Name -replace "'", "''"
    $filter = "`$filter=name eq '$escaped'"
    $select = "`$select=businessunitid,name,parentbusinessunitid"
    $result = Invoke-DataverseApi -Environment $Environment -Method GET -Path "businessunits?$select&$filter"
    if ($result.value -and $result.value.Count -gt 0) {
        return $result.value[0]
    }
    return $null
}

function Get-DataverseRootBusinessUnit {
    <#
    .SYNOPSIS
        Devuelve la BU raiz del environment (la que tiene parentbusinessunitid null).
    #>
    param(
        [Parameter(Mandatory)] [ValidateSet('dev','qa')] [string]$Environment
    )
    $filter = "`$filter=parentbusinessunitid eq null"
    $select = "`$select=businessunitid,name"
    $result = Invoke-DataverseApi -Environment $Environment -Method GET -Path "businessunits?$select&$filter"
    if (-not $result.value -or $result.value.Count -eq 0) {
        throw "No se encontro Business Unit raiz en $Environment"
    }
    return $result.value[0]
}
