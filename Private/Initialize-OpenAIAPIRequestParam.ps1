using namespace System.Collections

function Initialize-OpenAIAPIRequestParam {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter()]
        [string]$Method = 'Post',

        [Parameter(Mandatory)]
        [System.Uri]$Uri,

        [Parameter()]
        [string]$ContentType = 'application/json',

        [Parameter()]
        [IDictionary]$AdditionalQuery,

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [object]$AdditionalBody,

        [Parameter()]
        [IDictionary]$Headers,

        [Parameter()]
        [IDictionary]$AdditionalHeaders,

        [Parameter()]
        [string]$AuthType = 'openai',

        [Parameter(ValueFromRemainingArguments)]$ArgList
    )

    $InternalParams = @{
        ServiceName = ''
        Method      = $Method
        ContentType = $ContentType
        Uri         = $Uri
        Body        = $null
        Headers     = $null
        UserAgent   = $null
        IsDebug     = $false
    }

    # Set service name based on AuthType
    $InternalParams.ServiceName = switch -Wildcard ($AuthType) {
        'openai*' { 'OpenAI' }
        'azure*' { 'Azure OpenAI' }
    }

    # Assert selected model is discontinued
    if ($null -ne $Body -and $null -ne $Body.model) {
        Assert-DeprecationModel -Model $Body.model
    }

    # Construct URI with Query Parameters
    if ($PSBoundParameters.ContainsKey('AdditionalQuery') -and $null -ne $AdditionalQuery) {
        $UriBuilder = [System.UriBuilder]::new($Uri)
        $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
        foreach ($s in $AdditionalQuery.GetEnumerator()) {
            $QueryParam.Add($s.Key, $s.Value)
        }
        $UriBuilder.Query = $QueryParam.ToString()
        $Uri = $UriBuilder.Uri
    }
    $InternalParams.Uri = $Uri

    # Construct Headers
    $RequestHeaders = @{}
    if ($PSBoundParameters.ContainsKey('Headers') -and $null -ne $Headers) {
        $RequestHeaders = Merge-Dictionary $Headers $RequestHeaders
    }
    if ($PSBoundParameters.ContainsKey('AdditionalHeaders') -and $null -ne $AdditionalHeaders) {
        $RequestHeaders = Merge-Dictionary $RequestHeaders $AdditionalHeaders
    }
    $InternalParams.Headers = $RequestHeaders

    # Set UserAgent
    if ($RequestHeaders.ContainsKey('User-Agent')) {
        $UserAgent = $RequestHeaders.'User-Agent'
    }
    elseif (-not $script:UserAgent) {
        $UserAgent = Get-UserAgent
        $script:UserAgent = $UserAgent
    }
    $InternalParams.UserAgent = $UserAgent

    # Set debug flag
    $InternalParams.IsDebug = Test-Debug
    if ($InternalParams.IsDebug) {
        $InternalParams.Headers['OpenAI-Debug'] = 'true'
    }

    # Construct Body
    if ($null -ne $Body) {
        if ($Body -is [pscustomobject]) {
            $Body = ObjectToHashTable $Body
        }
        if ($PSBoundParameters.ContainsKey('AdditionalBody') -and $null -ne $AdditionalBody) {
            if ($AdditionalBody -is [string]) {
                try {
                    $AdditionalBody = ConvertFrom-Json $AdditionalBody -Depth 100
                }
                catch {
                    Write-Error -Exception ([System.InvalidOperationException]::new('Failed to parse AdditionalBody as JSON.'))
                }
            }
            if ($AdditionalBody -is [pscustomobject]) {
                $AdditionalBody = ObjectToHashTable $AdditionalBody
            }
            $Body = Merge-Dictionary $Body $AdditionalBody
        }

        if ($ContentType -match 'multipart/form-data') {
            $Boundary = New-MultipartFormBoundary
            $Body = New-MultipartFormContent -FormData $Body -Boundary $Boundary
            $ContentType = ('multipart/form-data; boundary="{0}"' -f $Boundary)
        }
    }
    $InternalParams.Body = $Body
    $InternalParams.ContentType = $ContentType

    return $InternalParams
}
