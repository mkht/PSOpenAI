using namespace System.Text
using namespace System.Net
using namespace System.Net.Http
using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands

# Workaround for assemblies loading issue on PS5.1
if ($PSVersionTable.PSVersion.Major -le 5) {
    Add-Type -AssemblyName System.Net.Http
}

function Invoke-OpenAIAPIRequestSSE {
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
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai'
    )

    #region Set variables
    $IsDebug = Test-Debug
    $ServiceName = switch -Wildcard ($AuthType) {
        'openai*' { 'OpenAI' }
        'azure*' { 'Azure' }
    }
    #endregion

    # Decrypt securestring
    $bstr = [Marshal]::SecureStringToBSTR($ApiKey)
    $PlainToken = [Marshal]::PtrToStringBSTR($bstr)
    # Create HttpClient and messages
    $HttpClient = [System.Net.Http.HttpClient]::new()
    $RequestMessage = [System.Net.Http.HttpRequestMessage]::new($Method, $Uri)
    # Use HTTP/2
    if ($null -ne [System.Net.HttpVersion]::Version20) {
        $RequestMessage.Version = [System.Net.HttpVersion]::Version20
    }
    if ($null -ne $Body) {
        $RequestMessage.Content = [System.Net.Http.StringContent]::new(($Body | ConvertTo-Json -Compress), [Encoding]::UTF8, $ContentType)
    }

    # Set User-Agent
    if (-not $script:UserAgent) {
        $script:UserAgent = Get-UserAgent
    }
    $RequestMessage.Headers.Add('User-Agent', $script:UserAgent)

    # Set debug header
    if ($IsDebug) {
        $RequestMessage.Headers.Add('OpenAI-Debug', 'true')
    }

    switch ($AuthType) {
        'openai' {
            $RequestMessage.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $PlainToken)
            if (-not [string]::IsNullOrWhiteSpace($Organization)) {
                $RequestMessage.Headers.Add('OpenAI-Organization', $Organization.Trim())
            }
        }
        'azure' {
            $RequestMessage.Headers.Add('api-key', $PlainToken)
        }
        'azure_ad' {
            $RequestMessage.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $PlainToken)
        }
    }

    # Set timeout
    $cts = [System.Threading.CancellationTokenSource]::new()
    if ($TimeoutSec -gt 0 -and $TimeoutSec -lt ([int]::MaxValue / 1000)) {
        $cts.CancelAfter($TimeoutSec * 1000)
    }
    $CancelToken = $cts.Token

    # Verbose / Debug output
    Write-Verbose -Message "Request to $ServiceName API"
    Write-Verbose -Message ('Request HTTP/{0} {1} with {2}-byte payload' -f `
            $RequestMessage.Version, $RequestMessage.Method, `
        $($RequestMessage.Content.Headers.ContentLength -as [Int64]))
    if ($IsDebug) {
        $startIdx = $lastIdx = 2
        if ($AuthType -eq 'openai') { $startIdx += 4 } # 'org-'
        Write-Debug -Message (Get-MaskedString `
            ('Request parameters: ' + ($RequestMessage | fl `
                        Method, `
                        RequestUri, `
                    @{name = 'Headers'; expression = { $_.Headers.ToString() } } `
                    | Out-String)).TrimEnd() `
                -Target ($ApiKey, $Organization) -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
    }

    # Send API Request
    try {
        $HttpResponse = $HttpClient.SendAsync($RequestMessage, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $CancelToken).GetAwaiter().GetResult()

        #region On HTTP error
        if (-not $HttpResponse.IsSuccessStatusCode) {
            $ErrorCode = $HttpResponse.StatusCode.value__
            $ErrorReason = $HttpResponse.ReasonPhrase
            $ErrorResponse = $HttpResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $ErrorMessage = try { ($ErrorResponse | ConvertFrom-Json -ErrorAction Ignore).error.message }catch {}

            # Retry on [429] or [5xx]
            if (($ErrorCode -ge 500 -and $ErrorCode -le 599) -or ($ErrorCode -eq 429 -and ($ErrorMessage -notmatch 'quota'))) {
                if ($RetryCount -lt $MaxRetryCount) {
                    $Delay = Get-RetryDelay -RetryCount $RetryCount
                    Write-Warning ('{3} API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage, $ServiceName)
                    Write-Warning ('Retry the request after waiting {0} ms (retry count: {1})' -f $Delay, $RetryCount)
                    Start-Sleep -Milliseconds $Delay
                    $PSBoundParameters.RetryCount = (++$RetryCount)
                    Invoke-OpenAIAPIRequestSSE @PSBoundParameters
                    return
                }
            }

            # Throw exception
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                $detailMessage = ('{3} API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage, $ServiceName)
                $ex = ([Microsoft.PowerShell.Commands.HttpResponseException]::new($detailMessage, $HttpResponse))
            }
            else {
                # Throws Webexception (Not HttpRequestException) for consistency with
                # exceptions thrown by Invoke-WebRequest on Windows PowerShell 5.1
                # (this may change in the future)
                $detailMessage = ('{3} API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage, $ServiceName)
                $ex = ([WebException]::new($detailMessage))
            }
            $er = [ErrorRecord]::new(
                $ex,
                'PSOpenAI.APIRequest.HttpResponseException',
                [ErrorCategory]::InvalidOperation,
                $RequestMessage
            )
            $er.ErrorDetails = $detailMessage
            $PSCmdlet.ThrowTerminatingError($er)
            return
        }
        #endregion

        $ResponseStream = $HttpResponse.Content.ReadAsStreamAsync().Result
        $StreamReader = [System.IO.StreamReader]::new($ResponseStream, [Encoding]::UTF8)

        # Verbose / Debug output
        Write-Verbose -Message ('Received HTTP/{0} response of content type {1}' -f $HttpResponse.Version, $HttpResponse.Content.Headers.ContentType.MediaType)
        Write-Verbose -Message ("$ServiceName API response: " + ($HttpResponse | fl `
                    StatusCode, `
                @{name = 'processing_ms'; expression = { $_.Headers.GetValues('openai-processing-ms')[0] } }, `
                @{name = 'request_id'; expression = { $_.Headers.GetValues('X-Request-Id')[0] } } `
                | Out-String)).TrimEnd()
        # Don't read the whole stream for debug logging unless necessary.
        if ($IsDebug) {
            $startIdx = $lastIdx = 2
            if ($AuthType -eq 'openai') { $startIdx += 4 } # 'org-'
            Write-Debug -Message (Get-MaskedString `
                ('API response header: ' + ($HttpResponse.Headers | ft -Hide | Out-String)).TrimEnd() `
                    -Target ($ApiKey, $Organization) -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
        }

        while (-not $StreamReader.EndOfStream) {
            $data = $null
            #Timeout
            $CancelToken.ThrowIfCancellationRequested()
            #Retrive response content
            $data = [string]$StreamReader.ReadLine()
            # Skip on empty
            if (-not $data.StartsWith('data: ')) { continue }
            # Debug output
            if ($IsDebug) {
                Write-Debug -Message ('API response body: ' + ($data | Out-String)).TrimEnd()
            }
            # End of stream
            if ($data -eq 'data: [DONE]') { break }
            #Output
            Write-Output $data.Substring(6)    # ("data: ").Length -> 6
        }

    }
    catch [OperationCanceledException] {
        # Convert OperationCanceledException to TimeoutException
        $er = [ErrorRecord]::new(
            ([TimeoutException]::new('The operation was canceled due to timeout.', $_.Exception)),
            'PSOpenAI.APIRequest.TimeoutException',
            [ErrorCategory]::OperationTimeout,
            $RequestMessage
        )
        $er.ErrorDetails = $_.Exception.Message
        $PSCmdlet.ThrowTerminatingError($er)
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        $bstr = $PlainToken = $null
        try {
            if ($null -ne $cts) { $cts.Dispose() }
            if ($null -ne $HttpClient) { $HttpClient.Dispose() }
            if ($null -ne $HttpResponse) { $HttpResponse.Dispose() }
            if ($null -ne $ResponseStream) { $ResponseStream.Dispose() }
            if ($null -ne $RequestMessage) { $RequestMessage.Dispose() }
        }
        catch {}
    }
}
