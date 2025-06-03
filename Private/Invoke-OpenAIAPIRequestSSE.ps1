using namespace System.Text
using namespace System.Net
using namespace System.Net.Http
using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands

# Workaround for assemblies loading issue on PS5.1
if ($PSVersionTable.PSVersion.Major -le 5) {
    Add-Type -AssemblyName System.Net.Http
}

$script:HttpStreamClientHandler = @{
    HttpClient = $null
    Expires    = $null
}

function Invoke-OpenAIAPIRequestSSE {
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
        [bool]$ReturnRawResponse = $false,

        [Parameter()]
        [uint64]$First = [uint64]::MaxValue
    )

    $InternalParams = Initialize-OpenAIAPIRequestParam @PSBoundParameters

    #region Set variables
    $IsDebug = $InternalParams.IsDebug
    $ServiceName = $InternalParams.ServiceName
    #endregion

    # Decrypt securestring
    $PlainToken = DecryptSecureString $ApiKey

    # Create HttpClient that has 5 min lifetime to reuse
    if ($null -eq $script:HttpClientHandler.HttpClient -or $script:HttpClientHandler.Expires -lt [datetime]::Now) {
        $script:HttpClientHandler.HttpClient = [System.Net.Http.HttpClient]::new()
        if ($TimeoutSec -gt 0) {
            $script:HttpClientHandler.HttpClient.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)
        }
        $script:HttpClientHandler.Expires = [datetime]::Now.AddMinutes(5)
    }

    # Create HttpRequestMessage
    $RequestMessage = [System.Net.Http.HttpRequestMessage]::new($InternalParams.Method, $InternalParams.Uri)

    # Use HTTP/2
    if ($null -ne [System.Net.HttpVersion]::Version20) {
        $RequestMessage.Version = [System.Net.HttpVersion]::Version20
    }

    # Set Content
    if ($null -ne $InternalParams.Body) {
        if ($ContentType -eq 'application/json') {
            $RequestMessage.Content = [System.Net.Http.StringContent]::new(($InternalParams.Body | ConvertTo-Json -Compress -Depth 100), [Encoding]::UTF8, $InternalParams.ContentType)
        }
        elseif ($InternalParams.Body -is [byte[]]) {
            $RequestMessage.Content = [System.Net.Http.ByteArrayContent]::new($InternalParams.Body)
            $null = $RequestMessage.Content.Headers.TryAddWithoutValidation('Content-Type', $InternalParams.ContentType)
        }
    }

    # Set User-Agent
    $RequestMessage.Headers.Add('User-Agent', $InternalParams.UserAgent)

    # Set other headers
    if ($InternalParams.Headers.Keys.Count -ne 0) {
        foreach ($h in $InternalParams.Headers.GetEnumerator()) {
            if (-not $RequestMessage.Headers.Contains($h.Key)) {
                $RequestMessage.Headers.Add($h.Key, $h.Value)
            }
        }
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
        default {
            # covers null
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
    Write-Verbose -Message "Method = $Method, Path = $($InternalParams.Uri), Streaming = True"
    Write-Verbose -Message ('Request HTTP/{0} {1} with {2}-byte payload' -f `
            $RequestMessage.Version, $RequestMessage.Method, `
        $($RequestMessage.Content.Headers.ContentLength -as [Int64]))
    if ($IsDebug) {
        $startIdx = $lastIdx = 2
        if ($AuthType -eq 'openai') { $startIdx += 4 } # 'org-'
        $MaskedMessage = Get-MaskedString `
        ('Request parameters: ' + ($RequestMessage | Format-List  Method, RequestUri, @{name = 'Headers'; expression = { $_.Headers.ToString() } } | Out-String)).TrimEnd() `
            -Target ($ApiKey, $Organization) -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45
        Write-Debug -Message $MaskedMessage
        $MaskedMessage = $null
    }

    # Send API Request
    try {
        $HttpResponse = $script:HttpClientHandler.HttpClient.SendAsync($RequestMessage, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $CancelToken).GetAwaiter().GetResult()

        #region On HTTP error
        if (-not $HttpResponse.IsSuccessStatusCode) {
            $ErrorCode = $HttpResponse.StatusCode.value__
            $ErrorReason = $HttpResponse.ReasonPhrase
            $ResponseBody = $HttpResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            $ErrorContent = try { ($ResponseBody | ConvertFrom-Json -ErrorAction Ignore) }catch {}
            $ErrorObject = Parse-WebExceptionResponse -ErrorCode $ErrorCode -ErrorReason $ErrorReason -ErrorResponse $HttpResponse -ErrorContent $ErrorContent

            # Retry
            if (Should-Retry -ErrorCode $ErrorObject.StatusCode -ErrorMessage $ErrorObject.Message -Headers $ErrorObject.Response.Headers -RetryCount $RetryCount -MaxRetryCount $MaxRetryCount) {
                $Delay = Get-RetryDelay -RetryCount $RetryCount -ResponseHeaders $ErrorObject.Response.Headers
                Write-Warning $ErrorObject.Message
                Write-Warning ('Retry the request after waiting {0} ms (retry count: {1})' -f $Delay, $RetryCount)
                Start-Sleep -Milliseconds $Delay
                $PSBoundParameters.RetryCount = (++$RetryCount)
                Invoke-OpenAIAPIRequestSSE @PSBoundParameters
                return
            }

            # Throw exception
            $er = [ErrorRecord]::new(
                $ErrorObject,
                ('PSOpenAI.APIRequest.{0}' -f $ErrorObject.GetType().Name),
                [ErrorCategory]::InvalidOperation,
                $null
            )
            $er.ErrorDetails = $ErrorObject.Message
            $PSCmdlet.ThrowTerminatingError($er)
            return
        }
        #endregion

        $ResponseStream = $HttpResponse.Content.ReadAsStreamAsync().Result
        $StreamReader = [System.IO.StreamReader]::new($ResponseStream, [Encoding]::UTF8)

        # Verbose / Debug output
        Write-Verbose -Message ('Received HTTP/{0} response of content type {1}' -f $HttpResponse.Version, $HttpResponse.Content.Headers.ContentType.MediaType)
        Write-Verbose -Message ("$ServiceName API response: " + ($HttpResponse | Format-List `
                    StatusCode, `
                @{name = 'processing_ms'; expression = { $_.Headers.GetValues('openai-processing-ms')[0] } }, `
                @{name = 'request_id'; expression = { $_.Headers.GetValues('X-Request-Id')[0] } } | Out-String)).TrimEnd()
        # Don't read the whole stream for debug logging unless necessary.
        if ($IsDebug) {
            $startIdx = $lastIdx = 2
            if ($AuthType -eq 'openai') { $startIdx += 4 } # 'org-'
            Write-Debug -Message (Get-MaskedString `
                ('API response header: ' + ($HttpResponse.Headers | Format-Table -Hide | Out-String)).TrimEnd() `
                    -Target ($ApiKey, $Organization) -First $startIdx -Last $lastIdx -MaxNumberOfAsterisks 45)
        }

        [uint64]$DataCounter = 0
        while ($DataCounter -lt $First) {
            $data = $null
            #Timeout
            $CancelToken.ThrowIfCancellationRequested()

            # Note:
            # In some situations, the server may unilaterally close the connection without sending any data.
            # To avoid long blocking waits that prevent user cancellation, we use a polling interval.
            # We allow a maximum total wait of 30 seconds while checking for cancellation every 500 ms.
            $timeoutMs = 30000
            $pollInterval = 500  # milliseconds
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            $readTask = $StreamReader.ReadLineAsync()
            while (-not $CancelToken.IsCancellationRequested -and $stopwatch.ElapsedMilliseconds -lt $timeoutMs) {
                if ($readTask.Wait($pollInterval, $CancelToken)) {
                    break
                }
            }

            if (-not $readTask.IsCompleted) {
                Write-Warning 'Timeout while waiting for response. It seems that the server is not sending any data.'
                $cts.Cancel()  # Cancel the request
                $CancelToken.ThrowIfCancellationRequested()
                break
            }

            # Read data
            $data = $readTask.Result
            # Check end of stream
            if ($null -eq $data) {
                Write-Verbose -Message ('End of stream signal received.')
                break
            }
            # Skip on empty
            elseif ([string]::IsNullOrWhiteSpace($data)) {
                continue
            }
            else {
                # Debug output
                if ($IsDebug) {
                    Write-Debug -Message ('API response body: ' + ($data | Out-String)).TrimEnd()
                }

                # Return raw response
                if ($ReturnRawResponse) {
                    Write-Output $data
                    continue
                }

                # Event
                if ($data.StartsWith('event: ', [StringComparison]::Ordinal)) {
                    #Verbose output
                    Write-Verbose -Message $data
                }
                # Data
                elseif ($data.StartsWith('data: ', [StringComparison]::Ordinal)) {
                    # End of stream
                    if ($data -eq 'data: [DONE]') {
                        Write-Verbose -Message ('End of data received.')
                        break
                    }
                    else {
                        # Increment counter
                        $DataCounter++

                        #Output
                        Write-Output $data.Substring(6)    # ("data: ").Length -> 6
                    }
                }
            }
        }
    }
    catch [OperationCanceledException] {
        # Convert OperationCanceledException to TimeoutException
        $er = [ErrorRecord]::new(
            ([TimeoutException]::new('The operation was canceled due to timeout.', $_.Exception)),
            'PSOpenAI.APIRequest.TimeoutException',
            [ErrorCategory]::OperationTimeout,
            $null
        )
        $er.ErrorDetails = $_.Exception.Message
        $PSCmdlet.ThrowTerminatingError($er)
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        $PlainToken = $null
        try {
            if ($null -ne $cts) { $cts.Dispose() }
            if ($null -ne $HttpResponse) { $HttpResponse.Dispose() }
            if ($null -ne $StreamReader) { $StreamReader.Dispose() }
            if ($null -ne $RequestMessage) { $RequestMessage.Dispose() }
        }
        catch {}
    }
}
