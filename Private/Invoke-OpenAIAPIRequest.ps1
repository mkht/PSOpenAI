using namespace System.Collections
using namespace System.Text
using namespace System.Net
using namespace System.Net.Http
using namespace System.Runtime.InteropServices
using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands

$script:HttpClientHandler = @{
    WebSession = $null
    Expires    = $null
}

function Invoke-OpenAIAPIRequest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Method = 'Post',

        [Parameter(Mandatory)]
        [System.Uri]$Uri,

        [Parameter()]
        [string]$ContentType = 'application/json',

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [securestring]$ApiKey,

        [Parameter()]
        [IDictionary]$AdditionalQuery,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Organization,

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [object]$AdditionalBody,

        [Parameter()]
        [IDictionary]$Headers,

        [Parameter()]
        [IDictionary]$AdditionalHeaders,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [int]$RetryCount = 0,

        [Parameter()]
        # [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [bool]$ReturnRawResponse = $false
    )

    $InternalParams = Initialize-OpenAIAPIRequestParam @PSBoundParameters

    #region Set variables
    $IsDebug = $InternalParams.IsDebug
    $ServiceName = $InternalParams.ServiceName
    #endregion

    #region API request
    # Construct parameter for Invoke-WebRequest
    $PlainToken = DecryptSecureString $ApiKey
    $IwrParam = @{
        Method          = $InternalParams.Method
        Uri             = $InternalParams.Uri
        ContentType     = $InternalParams.ContentType
        UserAgent       = $InternalParams.UserAgent
        TimeoutSec      = $TimeoutSec
        UseBasicParsing = $true
    }

    # Don't send Content-Type header on GET requests
    if ($IwrParam.Method -eq 'Get') {
        $IwrParam.Remove('ContentType')
    }

    # Use HTTP/2 (if possible)
    if ($null -ne (Get-Command 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.HttpVersion) {
        $IwrParam.HttpVersion = [version]::new(2, 0)
    }

    # Reuse WebSession (HttpClient)
    # Note: This method is only available on PS7.4+
    if ($PSVersionTable.PSVersion -ge 7.4) {
        if ($null -eq $script:HttpClientHandler.WebSession -or $script:HttpClientHandler.Expires -lt [datetime]::Now) {
            # Reset Session
            $script:HttpClientHandler.WebSession = $null
            $script:HttpClientHandler.Expires = $null
            $IwrParam.SessionVariable = 'WebSession'
        }
        else {
            # Reuse Session
            $IwrParam.WebSession = $script:HttpClientHandler.WebSession
        }
    }

    switch ($AuthType) {
        'openai' {
            $UseBearer = $true
            # Set Organization-ID
            if (-not [string]::IsNullOrWhiteSpace($Organization)) {
                $InternalParams.Headers['OpenAI-Organization'] = $Organization.Trim()
            }
        }
        'azure' {
            $UseBearer = $false
            $InternalParams.Headers['api-key'] = $PlainToken
        }
        'azure_ad' {
            $UseBearer = $true
        }
        default {
            # covers null
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
            $InternalParams.Headers['Authorization'] = "Bearer $PlainToken"
        }
    }

    if ($null -ne $InternalParams.Body) {
        if ($InternalParams.ContentType -match 'application/json') {
            try { $InternalParams.Body = ($InternalParams.Body | ConvertTo-Json -Compress -Depth 100) }catch { Write-Error -Exception $_.Exception }
            $IwrParam.Body = ([System.Text.Encoding]::UTF8.GetBytes($InternalParams.Body))
        }
        else {
            $IwrParam.Body = $InternalParams.Body
        }
    }

    # Set http request headers
    if ($InternalParams.Headers.Keys.Count -ne 0) {
        $IwrParam.Headers = $InternalParams.Headers
    }

    # Verbose / Debug output
    Write-Verbose -Message "Request to $ServiceName API"
    Write-Verbose -Message "Method = $Method, Path = $($InternalParams.Uri)"
    if ($IsDebug) {
        $startIdx = $lastIdx = 2
        if ($AuthType -eq 'openai') { $startIdx += 4 } # 'org-'
        $params1 = @{
            Source               = 'Request parameters: ' + (([pscustomobject]$IwrParam) | Format-List Method, Uri, ContentType, Headers, Authentication | Out-String).TrimEnd()
            Target               = ($ApiKey, $Organization)
            First                = $startIdx
            Last                 = $lastIdx
            MaxNumberOfAsterisks = 45
        }
        $maskedString1 = Get-MaskedString @params1
        Write-Debug -Message $maskedString1

        $params2 = @{
            Source               = 'Post body: ' + $InternalParams.Body
            Target               = ($ApiKey, $Organization)
            First                = $startIdx
            Last                 = $lastIdx
            MaxNumberOfAsterisks = 45
        }
        $maskedString2 = Get-MaskedString @params2
        Write-Debug -Message $maskedString2
    }

    #region Send API Request
    try {
        $Response = Microsoft.PowerShell.Utility\Invoke-WebRequest @IwrParam
    }
    catch [HttpRequestException], [WebException] {
        # Trash last error from cmdlet
        if ($global:Error[0].FullyQualifiedErrorId.StartsWith('WebCmdletWebResponseException', [StringComparison]::Ordinal)) { $global:Error.RemoveAt(0) }

        # Parse error details
        $ErrorObject = Parse-WebExceptionResponse -ErrorRecord $_ -ServiceName $ServiceName
        if (-not $ErrorObject) {
            $PSCmdlet.ThrowTerminatingError($_)
        }

        # Retry
        if (Should-Retry -ErrorCode $ErrorObject.StatusCode -ErrorMessage $ErrorObject.Message -Headers $ErrorObject.Response.Headers -RetryCount $RetryCount -MaxRetryCount $MaxRetryCount) {
            $Delay = Get-RetryDelay -RetryCount $RetryCount -ResponseHeaders $ErrorObject.Response.Headers
            Write-Warning $ErrorObject.Message
            Write-Warning ('Retry the request after waiting {0} ms (retry count: {1})' -f $Delay, $RetryCount)
            Start-Sleep -Milliseconds $Delay
            $PSBoundParameters.RetryCount = (++$RetryCount)
            Invoke-OpenAIAPIRequest @PSBoundParameters
            return
        }

        $er = [ErrorRecord]::new(
            $ErrorObject,
            ('PSOpenAI.APIRequest.{0}' -f $ErrorObject.GetType().Name),
            [ErrorCategory]::InvalidOperation,
            $null
        )
        $er.ErrorDetails = $ErrorObject.Message
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
    $verboseMessage = "$ServiceName API response: " + ($Response |
            Format-List StatusCode,
            @{
                name       = 'processing_ms'
                expression = { $_.Headers['openai-processing-ms'] }
            },
            @{
                name       = 'request_id'
                expression = { $_.Headers['X-Request-Id'] }
            } | Out-String).TrimEnd()
    Write-Verbose -Message $verboseMessage

    # Don't read the whole stream for debug logging unless necessary.
    if ($IsDebug) {
        $startIdx = $lastIdx = 2
        if ($AuthType -eq 'openai') { $startIdx += 4 } # 'org-'
        $params1 = @{
            Source               = 'API response header: ' + ($Response.Headers | Format-Table -HideTableHeaders | Out-String).TrimEnd()
            Target               = ($ApiKey, $Organization)
            First                = $startIdx
            Last                 = $lastIdx
            MaxNumberOfAsterisks = 45
        }
        $maskedString1 = Get-MaskedString @params1
        Write-Debug -Message $maskedString1

        $params2 = @{
            Source               = 'API response body: ' + ($Response.Content | Out-String).TrimEnd()
            Target               = ($ApiKey, $Organization)
            First                = $startIdx
            Last                 = $lastIdx
            MaxNumberOfAsterisks = 45
        }
        $maskedString2 = Get-MaskedString @params2
        Write-Debug -Message $maskedString2
    }

    # Save WebSession
    if ($WebSession) {
        $script:HttpClientHandler.WebSession = $WebSession
        $script:HttpClientHandler.Expires = [datetime]::Now.AddMinutes(5)
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
