using namespace System.Collections
using namespace System.Text
using namespace System.Net
using namespace System.Net.Http
using namespace System.Runtime.InteropServices

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
        [int]$TimeoutSec = 0,

        [Parameter()]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [int]$RetryCount = 0,

        [Parameter()]
        [bool]$Stream = $false,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai'
    )

    $IsDebug = Test-Debug

    #region Assert selected model is discontinued
    if ($null -ne $Body -and $null -ne $Body.model) {
        Assert-UnsupportedModels -Model $Body.model
    }
    #endregion

    # Headers dictionary
    $RequestHeaders = @{}

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
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount
    }
    #endregion

    #region PowerShell 6 and higher
    elseif ($PSVersionTable.PSVersion.Major -ge 6) {
        # Construct parameter for Invoke-WebRequest
        $IwrParam = @{
            Method      = $Method
            Uri         = $Uri
            ContentType = $ContentType
            TimeoutSec  = $TimeoutSec
        }

        switch ($AuthType) {
            'openai' {
                $IwrParam.Authentication = 'Bearer'
                $IwrParam.Token = $ApiKey
                # Set an Organization-ID
                if (-not [string]::IsNullOrWhiteSpace($Organization)) {
                    $RequestHeaders['OpenAI-Organization'] = $Organization.Trim()
                }
            }
            'azure' {
                # decrypt securestring
                $bstr = [Marshal]::SecureStringToBSTR($ApiKey)
                $PlainToken = [Marshal]::PtrToStringBSTR($bstr)
                $RequestHeaders['api-key'] = $PlainToken
                $bstr = $PlainToken = $null
            }
            'azure_ad' {
                $IwrParam.Authentication = 'Bearer'
                $IwrParam.Token = $ApiKey
            }
        }

        if ($null -ne $Body) {
            $RawBody = $Body
            if ($ContentType -match 'multipart/form-data') {
                $IwrParam.Form = $Body
            }
            elseif ($ContentType -match 'application/json') {
                try { $RawBody = ($Body | ConvertTo-Json -Compress) }catch { Write-Error -Exception $_.Exception }
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
        Write-Verbose -Message 'Request to OpenAI API'
        if ($IsDebug) {
            $startIdx = $lastIdx = 2
            if ($AuthType -eq 'openai') { $startIdx += 3 } # 'sk-'
            Write-Debug -Message (Get-MaskedString `
                ('Request parameters: ' + (([pscustomobject]$IwrParam) | fl Method, Uri, ContentType, Headers, Authentication | Out-String)).TrimEnd() `
                    -Target $ApiKey -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
            Write-Debug -Message (Get-MaskedString `
                ('Post body: ' + $RawBody) `
                    -Target $ApiKey -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
        }

        #region Send API Request
        try {
            $Response = Microsoft.PowerShell.Utility\Invoke-WebRequest @IwrParam
        }
        catch [HttpRequestException] {
            $ErrorCode = $_.Exception.Response.StatusCode.value__
            $ErrorReason = $_.Exception.Response.ReasonPhrase
            $ErrorMessage = try { ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Ignore).error.message }catch {}
            if (-not $ErrorMessage) {
                $ErrorMessage = $_.Exception.Message
            }

            # Retry on [429] or [5xx]
            if (($ErrorCode -ge 500 -and $ErrorCode -le 599) -or ($ErrorCode -eq 429 -and ($ErrorMessage -notmatch 'quota'))) {
                if ($RetryCount -lt $MaxRetryCount) {
                    $Delay = Get-RetryDelay -RetryCount $RetryCount
                    Write-Warning ('OpenAI API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage)
                    Write-Warning ('Retry the request after waiting {0} ms (retry count: {1})' -f $Delay, $RetryCount)
                    Start-Sleep -Milliseconds $Delay
                    $PSBoundParameters.RetryCount = (++$RetryCount)
                    Invoke-OpenAIAPIRequest @PSBoundParameters
                    return
                }
            }

            Write-Error ('OpenAI API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage)
            return
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        #endregion

        # Verbose / Debug output
        Write-Verbose -Message ('OpenAI API response: ' + ($Response | fl `
                    StatusCode, `
                @{name = 'processing_ms'; expression = { $_.Headers['openai-processing-ms'] } }, `
                @{name = 'request_id'; expression = { $_.Headers['X-Request-Id'] } } `
                | Out-String)).TrimEnd()
        # Don't read the whole stream for debug logging unless necessary.
        if ($IsDebug) {
            $startIdx = $lastIdx = 2
            if ($AuthType -eq 'openai') { $startIdx += 3 } # 'sk-'
            Write-Debug -Message (Get-MaskedString `
                ('API response header: ' + ($Response.Headers | ft -Hide | Out-String)).TrimEnd() `
                    -Target $ApiKey -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
            Write-Debug -Message (Get-MaskedString `
                ('API response body: ' + ($Response.Content | Out-String)).TrimEnd() `
                    -Target $ApiKey -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
        }

        # Output
        Write-Output $Response.Content
    }
    #endregion

    #region Windows PowerShell 5
    elseif ($PSVersionTable.PSVersion.Major -eq 5) {
        # decrypt securestring
        $bstr = [Marshal]::SecureStringToBSTR($ApiKey)
        $PlainToken = [Marshal]::PtrToStringBSTR($bstr)

        # Construct parameter for Invoke-WebRequest
        $IwrParam = @{
            Method          = $Method
            Uri             = $Uri
            ContentType     = $ContentType
            TimeoutSec      = $TimeoutSec
            UseBasicParsing = $true
        }

        switch ($AuthType) {
            'openai' {
                $RequestHeaders['Authorization'] = "Bearer $PlainToken"
                # Set an Organization-ID
                if (-not [string]::IsNullOrWhiteSpace($Organization)) {
                    $RequestHeaders['OpenAI-Organization'] = $Organization.Trim()
                }
            }
            'azure' {
                $RequestHeaders['api-key'] = $PlainToken
            }
            'azure_ad' {
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
                try { $RawBody = ($Body | ConvertTo-Json -Compress) }catch { Write-Error -Exception $_.Exception }
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
        Write-Verbose -Message 'Request to OpenAI API'
        if ($IsDebug) {
            $startIdx = $lastIdx = 2
            if ($AuthType -eq 'openai') { $startIdx += 3 } # 'sk-'
            Write-Debug -Message (Get-MaskedString `
                ('Request parameters: ' + (([pscustomobject]$IwrParam) | fl Method, Uri, ContentType, Headers, Authentication | Out-String)).TrimEnd() `
                    -Target $ApiKey -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
            Write-Debug -Message (Get-MaskedString `
                ('Post body: ' + $RawBody) `
                    -Target $ApiKey -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
        }

        #region Send API Request
        try {
            $Response = Microsoft.PowerShell.Utility\Invoke-WebRequest @IwrParam
        }
        catch [WebException] {
            $ErrorCode = $_.Exception.Response.StatusCode.value__
            $ErrorReason = $_.Exception.Response.StatusCode.ToString()
            $ErrorMessage = try { ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Ignore).error.message }catch {}
            if (-not $ErrorMessage) {
                $ErrorMessage = $_.Exception.Message
            }

            # Retry on [429] or [5xx]
            if (($ErrorCode -ge 500 -and $ErrorCode -le 599) -or ($ErrorCode -eq 429 -and ($ErrorMessage -notmatch 'quota'))) {
                if ($RetryCount -lt $MaxRetryCount) {
                    $Delay = Get-RetryDelay -RetryCount $RetryCount
                    Write-Warning ('OpenAI API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage)
                    Write-Warning ('Retry the request after waiting {0} ms (retry count: {1})' -f $Delay, $RetryCount)
                    Start-Sleep -Milliseconds $Delay
                    $PSBoundParameters.RetryCount = (++$RetryCount)
                    Invoke-OpenAIAPIRequest @PSBoundParameters
                    return
                }
            }

            Write-Error ('OpenAI API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage)
            return
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        finally {
            $bstr = $PlainToken = $null
        }
        #endregion

        # Fix content charset from ISO-8859-1 to UTF-8 (only JSON)
        if ($Response.Headers.'Content-Type' -match 'application/json') {
            $Content = [Encoding]::UTF8.GetString([Encoding]::GetEncoding('ISO-8859-1').GetBytes($Response.Content))
        }
        else {
            $Content = $Response.Content
        }

        # Verbose / Debug output
        Write-Verbose -Message ('OpenAI API response: ' + ($Response | fl `
                    StatusCode, `
                @{name = 'processing_ms'; expression = { $_.Headers['openai-processing-ms'] } }, `
                @{name = 'request_id'; expression = { $_.Headers['X-Request-Id'] } } `
                | Out-String)).TrimEnd()
        # Don't read the whole stream for debug logging unless necessary.
        if ($IsDebug) {
            $startIdx = $lastIdx = 2
            if ($AuthType -eq 'openai') { $startIdx += 3 } # 'sk-'
            Write-Debug -Message (Get-MaskedString `
                ('API response header: ' + ($Response.Headers | ft -Hide | Out-String)).TrimEnd() `
                    -Target $ApiKey -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
            Write-Debug -Message (Get-MaskedString `
                ('API response body: ' + ($Content | Out-String)).TrimEnd() `
                    -Target $ApiKey -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
        }

        # Output
        Write-Output $Content
    }
    #endregion

    # Others (error)
    else {
        Write-Error 'This version of the PowerShell is not supported.'
        return
    }
}
