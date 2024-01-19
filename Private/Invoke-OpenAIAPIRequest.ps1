using namespace System.Collections
using namespace System.Text
using namespace System.Net
using namespace System.Net.Http
using namespace System.Runtime.InteropServices
using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands

function Invoke-OpenAIAPIRequest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Method = 'Post',

        [Parameter(Mandatory = $true)]
        [System.Uri]$Uri,

        [Parameter()]
        [string]$ContentType = 'application/json',

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [securestring]$ApiKey,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Organization,

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [IDictionary]$Headers,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [int]$RetryCount = 0,

        [Parameter()]
        [bool]$Stream = $false,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [bool]$ReturnRawResponse = $false
    )

    #region Set variables
    $IsDebug = Test-Debug
    $ServiceName = switch -Wildcard ($AuthType) {
        'openai*' { 'OpenAI' }
        'azure*' { 'Azure' }
    }
    #endregion

    #region Assert selected model is discontinued
    if ($null -ne $Body -and $null -ne $Body.model) {
        Assert-UnsupportedModels -Model $Body.model
    }
    #endregion

    # Headers dictionary
    $RequestHeaders = @{}
    if ($PSBoundParameters.ContainsKey('Headers') -and $null -ne $Headers) {
        $RequestHeaders = Merge-Dictionary $Headers $RequestHeaders
    }

    # Set debug header
    if ($IsDebug) {
        $RequestHeaders['OpenAI-Debug'] = 'true'
    }

    #region Server-Sent-Events
    if ($Stream) {
        Invoke-OpenAIAPIRequestSSE `
            -Method $Method `
            -Uri $Uri `
            -ContentType $ContentType `
            -ApiKey $ApiKey `
            -Organization $Organization `
            -AuthType $AuthType `
            -Body $Body `
            -Headers $RequestHeaders `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount
        return
    }
    #endregion

    #region API request
    # Construct parameter for Invoke-WebRequest
    $PlainToken = DecryptSecureString $ApiKey
    $IwrParam = @{
        Method          = $Method
        Uri             = $Uri
        ContentType     = $ContentType
        TimeoutSec      = $TimeoutSec
        UseBasicParsing = $true
    }

    # Use HTTP/2 (if possible)
    if ($null -ne (Get-Command 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.HttpVersion) {
        $IwrParam.HttpVersion = [version]::new(2, 0)
    }

    switch ($AuthType) {
        'openai' {
            $UseBearer = $true
            # Set Organization-ID
            if (-not [string]::IsNullOrWhiteSpace($Organization)) {
                $RequestHeaders['OpenAI-Organization'] = $Organization.Trim()
            }
        }
        'azure' {
            $UseBearer = $false
            $RequestHeaders['api-key'] = $PlainToken
        }
        'azure_ad' {
            $UseBearer = $true
        }
    }

    # Absorb differences in PowerShell version
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $PlainToken = $null
        $IwrParam.AllowUnencryptedAuthentication = $true
        # Use Bearer Token Auth
        if ($UseBearer) {
            $IwrParam.Authentication = 'Bearer'
            $IwrParam.Token = $ApiKey
        }
    }
    else {
        # Use Bearer Token Auth
        if ($UseBearer) {
            $RequestHeaders['Authorization'] = "Bearer $PlainToken"
        }
    }

    if ($null -ne $Body) {
        $RawBody = $Body
        if ($ContentType -match 'multipart/form-data') {
            $Boundary = New-MultipartFormBoundary
            $RawBody = New-MultipartFormContent -FormData $Body -Boundary $Boundary
            $IwrParam.Body = $RawBody
            $IwrParam.ContentType = ('multipart/form-data; boundary="{0}"' -f $Boundary)
        }
        elseif ($ContentType -match 'application/json') {
            try { $RawBody = ($Body | ConvertTo-Json -Compress -Depth 100) }catch { Write-Error -Exception $_.Exception }
            $IwrParam.Body = ([System.Text.Encoding]::UTF8.GetBytes($RawBody))
        }
        else {
            $IwrParam.Body = $Body
        }
    }

    # Set http request headers
    if ($null -ne $RequestHeaders -and $RequestHeaders.Count -ne 0) {
        $IwrParam.Headers = $RequestHeaders
    }

    # Verbose / Debug output
    Write-Verbose -Message "Request to $ServiceName API"
    Write-Verbose -Message "Method = $Method, Path = $Uri"
    if ($IsDebug) {
        $startIdx = $lastIdx = 2
        if ($AuthType -eq 'openai') { $startIdx += 4 } # 'org-'
        Write-Debug -Message (Get-MaskedString `
            ('Request parameters: ' + (([pscustomobject]$IwrParam) | fl Method, Uri, ContentType, Headers, Authentication | Out-String)).TrimEnd() `
                -Target ($ApiKey, $Organization) -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
        Write-Debug -Message (Get-MaskedString `
            ('Post body: ' + $RawBody) `
                -Target ($ApiKey, $Organization) -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
    }

    #region Send API Request
    try {
        $Response = Microsoft.PowerShell.Utility\Invoke-WebRequest @IwrParam
    }
    catch [HttpRequestException], [WebException] {
        # Trash last error from cmdlet
        if ($global:Error[0].FullyQualifiedErrorId.StartsWith('WebCmdletWebResponseException')) { $global:Error.RemoveAt(0) }

        # Parse error details
        $ErrorResponse = Parse-WebExceptionResponse -ErrorRecord $_
        $detailMessage = ('{3} API returned an {0} ({1}) Error: {2}' -f $ErrorResponse.ErrorCode, $ErrorResponse.ErrorReason, $ErrorResponse.ErrorMessage, $ServiceName)

        # Retry
        if (Should-Retry -ErrorCode $ErrorResponse.ErrorCode -ErrorMessage $ErrorResponse.ErrorMessage -Headers $ErrorResponse.Headers -RetryCount $RetryCount -MaxRetryCount $MaxRetryCount) {
            $Delay = Get-RetryDelay -RetryCount $RetryCount
            Write-Warning $detailMessage
            Write-Warning ('Retry the request after waiting {0} ms (retry count: {1})' -f $Delay, $RetryCount)
            Start-Sleep -Milliseconds $Delay
            $PSBoundParameters.RetryCount = (++$RetryCount)
            Invoke-OpenAIAPIRequest @PSBoundParameters
            return
        }

        if ($_.Exception -is [HttpRequestException]) {
            $ex = ([Microsoft.PowerShell.Commands.HttpResponseException]::new($detailMessage, $_.Exception.Response))
        }
        else {
            $ex = ([WebException]::new($detailMessage, $_.Exception, $_.Exception.Status, $_.Exception.Response))
        }
        $er = [ErrorRecord]::new(
            $ex,
            'PSOpenAI.APIRequest.HttpResponseException',
            [ErrorCategory]::InvalidOperation,
            $IwrParam
        )
        $er.ErrorDetails = $detailMessage
        $PSCmdlet.ThrowTerminatingError($er)
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        $PlainToken = $null
    }
    #endregion

    # Fix content charset from ISO-8859-1 to UTF-8 (only JSON with PowerShell 5)
    if (($PSVersionTable.PSVersion.Major -le 5) -and `
        ($Response.Headers.'Content-Type' -match 'application/json')) {
        $Content = [Encoding]::UTF8.GetString([Encoding]::GetEncoding('ISO-8859-1').GetBytes($Response.Content))
    }
    else {
        $Content = $Response.Content
    }

    # Verbose / Debug output
    Write-Verbose -Message ("$ServiceName API response: " + ($Response | fl `
                StatusCode, `
            @{name = 'processing_ms'; expression = { $_.Headers['openai-processing-ms'] } }, `
            @{name = 'request_id'; expression = { $_.Headers['X-Request-Id'] } } `
            | Out-String)).TrimEnd()
    # Don't read the whole stream for debug logging unless necessary.
    if ($IsDebug) {
        $startIdx = $lastIdx = 2
        if ($AuthType -eq 'openai') { $startIdx += 4 } # 'org-'
        Write-Debug -Message (Get-MaskedString `
            ('API response header: ' + ($Response.Headers | ft -Hide | Out-String)).TrimEnd() `
                -Target ($ApiKey, $Organization) -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
        Write-Debug -Message (Get-MaskedString `
            ('API response body: ' + ($Response.Content | Out-String)).TrimEnd() `
                -Target ($ApiKey, $Organization) -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
    }

    # Output
    if ($ReturnRawResponse) {
        Write-Output $Response
    }
    else {
        Write-Output $Content
    }
    #endregion
}
