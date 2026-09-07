using namespace System.Collections

function Invoke-OpenAIHttpRequest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Method = 'Post',

        [Parameter(Mandatory)]
        [System.Uri]$Uri,

        [Parameter()]
        [string]$ContentType = 'application/json',

        [Parameter()]
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
        [bool]$ReturnRawResponse = $false,

        [Parameter()]
        [switch]$Stream,

        [Parameter()]
        [string]$OutFile,

        [Parameter()]
        [uint64]$First = [uint64]::MaxValue,

        [Parameter()]
        [Generic.List[Tuple[regex, string]]]$MaskPatterns = @()
    )

    $InternalParams = Initialize-OpenAIAPIRequestParam @PSBoundParameters
    $ServiceName = $InternalParams.ServiceName
    $PlainToken = if ($null -ne $ApiKey) { DecryptSecureString $ApiKey }
    if (-not [string]::IsNullOrWhiteSpace($PlainToken)) {
        $MaskPatterns.Add([Tuple[regex, string]]::new([regex]::Escape($PlainToken), '<OpenAI API Key>'))
    }
    if (-not [string]::IsNullOrWhiteSpace($Organization)) {
        $MaskPatterns.Add([Tuple[regex, string]]::new([regex]::Escape($Organization), '<OpenAI Organization ID>'))
    }
    $MaskPatterns.Add([Tuple[regex, string]]::new('(Authorization:\s*Bearer\s+)[a-zA-Z0-9\-_.~+/]+', '$1********'))

    try {
        while ($true) {
            $RequestMessage = $null
            $HttpResponse = $null
            $StreamReader = $null
            $cts = [System.Threading.CancellationTokenSource]::new()
            $Delay = $null
            try {
                if ($TimeoutSec -gt 0) {
                    $cts.CancelAfter([timespan]::FromSeconds($TimeoutSec))
                }
                $CancelToken = $cts.Token
                $RequestMessage = [System.Net.Http.HttpRequestMessage]::new($InternalParams.Method.ToUpperInvariant(), $InternalParams.Uri)
                # .NET Framework uses HTTP/1.1; modern .NET can negotiate down from HTTP/2.
                if ($PSVersionTable.PSVersion.Major -ge 7) {
                    $RequestMessage.Version = [version]::new(2, 0)
                }

                if ($null -ne $InternalParams.Body -and $InternalParams.Method -ne 'Get') {
                    if ($InternalParams.ContentType -match 'application/json') {
                        $Bytes = [System.Text.Encoding]::UTF8.GetBytes(($InternalParams.Body | ConvertTo-Json -Compress -Depth 100 -ErrorAction Stop))
                    }
                    elseif ($InternalParams.Body -is [byte[]]) {
                        $Bytes = $InternalParams.Body
                    }
                    else {
                        $Bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$InternalParams.Body)
                    }
                    $RequestMessage.Content = [System.Net.Http.ByteArrayContent]::new($Bytes)
                    $null = $RequestMessage.Content.Headers.TryAddWithoutValidation('Content-Type', $InternalParams.ContentType)
                }

                $RequestHeaders = @{}
                foreach ($h in $InternalParams.Headers.GetEnumerator()) { $RequestHeaders[$h.Key] = $h.Value }
                $RequestHeaders['User-Agent'] = $InternalParams.UserAgent
                if ($null -ne $ApiKey) {
                    if ($AuthType -eq 'azure') {
                        $RequestHeaders['api-key'] = $PlainToken
                    }
                    else {
                        $RequestHeaders['Authorization'] = "Bearer $PlainToken"
                    }
                    if ($AuthType -eq 'openai' -and -not [string]::IsNullOrWhiteSpace($Organization)) {
                        $RequestHeaders['OpenAI-Organization'] = $Organization.Trim()
                    }
                }
                foreach ($h in $RequestHeaders.GetEnumerator()) {
                    if (-not $RequestMessage.Headers.TryAddWithoutValidation($h.Key, [string[]]@($h.Value))) {
                        if ($InternalParams.Method -eq 'Get' -and $h.Key -eq 'Content-Type') { continue }
                        if ($null -eq $RequestMessage.Content) {
                            $RequestMessage.Content = [System.Net.Http.ByteArrayContent]::new([byte[]]@())
                        }
                        $null = $RequestMessage.Content.Headers.Remove($h.Key)
                        if (-not $RequestMessage.Content.Headers.TryAddWithoutValidation($h.Key, [string[]]@($h.Value))) {
                            throw [ArgumentException]::new("Invalid HTTP header: $($h.Key)")
                        }
                    }
                }

                Write-Verbose (("Request to $ServiceName API: " + $RequestMessage.Method + ' ' + $RequestMessage.RequestUri) | Get-MaskedString -MaskPatterns $MaskPatterns)
                if ($InternalParams.IsDebug) {
                    Write-Debug (($RequestMessage.ToString()) | Get-MaskedString -MaskPatterns $MaskPatterns)
                }
                $HttpResponse = Send-OpenAIHttpRequest -Request $RequestMessage -CancellationToken $CancelToken
                Write-Verbose ("$ServiceName API response: HTTP/{0} {1}" -f $HttpResponse.Version, [int]$HttpResponse.StatusCode)
                if ($InternalParams.IsDebug) {
                    Write-Debug (($HttpResponse.ToString()) | Get-MaskedString -MaskPatterns $MaskPatterns)
                }

                if (-not $HttpResponse.IsSuccessStatusCode) {
                    $ResponseBody = Wait-OpenAIHttpTask -Task ($HttpResponse.Content.ReadAsStringAsync()) -CancellationToken $CancelToken
                    $ErrorContent = try { $ResponseBody | ConvertFrom-Json -ErrorAction Stop } catch { $null }
                    $Reason = if ($HttpResponse.ReasonPhrase) { $HttpResponse.ReasonPhrase } else { $HttpResponse.StatusCode.ToString() }
                    $ErrorObject = Parse-WebExceptionResponse -ErrorCode ([int]$HttpResponse.StatusCode) -ErrorReason $Reason -ErrorResponse $HttpResponse -ErrorContent $ErrorContent -ServiceName $ServiceName
                    if (Should-Retry -ErrorCode $ErrorObject.StatusCode -ErrorMessage $ErrorObject.Message -Headers $ErrorObject.Response.Headers -RetryCount $RetryCount -MaxRetryCount $MaxRetryCount) {
                        $Delay = Get-RetryDelay -RetryCount $RetryCount -ResponseHeaders $ErrorObject.Response.Headers
                        Write-Warning $ErrorObject.Message
                        Write-Warning ('Retry the request after waiting {0} ms (retry count: {1})' -f $Delay, $RetryCount)
                    }
                    else {
                        $er = [System.Management.Automation.ErrorRecord]::new(
                            $ErrorObject,
                            ('PSOpenAI.APIRequest.{0}' -f $ErrorObject.GetType().Name),
                            [System.Management.Automation.ErrorCategory]::InvalidOperation,
                            $null
                        )
                        $er.ErrorDetails = $ErrorObject.Message
                        $PSCmdlet.ThrowTerminatingError($er)
                    }
                }
                elseif ($Stream) {
                    $ResponseStream = Wait-OpenAIHttpTask -Task ($HttpResponse.Content.ReadAsStreamAsync()) -CancellationToken $CancelToken
                    $StreamReader = [System.IO.StreamReader]::new($ResponseStream, [System.Text.Encoding]::UTF8)
                    [uint64]$DataCounter = 0
                    while ($DataCounter -lt $First) {
                        $data = Wait-OpenAIHttpTask -Task ($StreamReader.ReadLineAsync()) -CancellationToken $CancelToken
                        if ($null -eq $data) { break }
                        if ([string]::IsNullOrWhiteSpace($data)) { continue }
                        if ($InternalParams.IsDebug) {
                            Write-Debug ($data | Get-MaskedString -MaskPatterns $MaskPatterns)
                        }
                        if ($ReturnRawResponse) {
                            Write-Output $data
                            continue
                        }
                        if ($data.StartsWith('event: ', [StringComparison]::Ordinal)) {
                            Write-Verbose $data
                        }
                        elseif ($data.StartsWith('data: ', [StringComparison]::Ordinal)) {
                            if ($data -eq 'data: [DONE]') { break }
                            $DataCounter++
                            Write-Output $data.Substring(6)
                        }
                    }
                    return
                }
                else {
                    $MediaType = $HttpResponse.Content.Headers.ContentType.MediaType
                    if (-not $OutFile -and $MediaType -match '^(text/|application/(.*\+)?(json|xml|javascript))') {
                        $Content = Wait-OpenAIHttpTask -Task ($HttpResponse.Content.ReadAsStringAsync()) -CancellationToken $CancelToken
                    }
                    else {
                        $Content = Wait-OpenAIHttpTask -Task ($HttpResponse.Content.ReadAsByteArrayAsync()) -CancellationToken $CancelToken
                    }
                    if ($InternalParams.IsDebug) {
                        if ($Content -is [byte[]]) {
                            Write-Debug ("API response body: <binary data> (length: {0} bytes)" -f $Content.Length)
                        }
                        else {
                            Write-Debug (('API response body: ' + $Content) | Get-MaskedString -MaskPatterns $MaskPatterns)
                        }
                    }
                    if ($OutFile) {
                        Write-ByteContent -OutFile $OutFile -Bytes $Content
                    }
                    elseif ($ReturnRawResponse) {
                        # Private response snapshot: no live stream escapes the request lifetime.
                        $ResponseHeaders = @{}
                        foreach ($h in $HttpResponse.Headers) { $ResponseHeaders[$h.Key] = $h.Value }
                        foreach ($h in $HttpResponse.Content.Headers) { $ResponseHeaders[$h.Key] = $h.Value }
                        [pscustomobject]@{
                            StatusCode        = [int]$HttpResponse.StatusCode
                            StatusDescription = $HttpResponse.ReasonPhrase
                            Headers           = $ResponseHeaders
                            Content           = $Content
                        }
                    }
                    else {
                        Write-Output $Content
                    }
                    return
                }
            }
            catch {
                $Exception = $_.Exception
                while ($Exception.InnerException -and $Exception -isnot [OperationCanceledException]) {
                    $Exception = $Exception.InnerException
                }
                if ($Exception -is [OperationCanceledException]) {
                    $er = [System.Management.Automation.ErrorRecord]::new(
                        [TimeoutException]::new('The operation was canceled due to timeout.', $Exception),
                        'PSOpenAI.APIRequest.TimeoutException',
                        [System.Management.Automation.ErrorCategory]::OperationTimeout,
                        $null
                    )
                    $PSCmdlet.ThrowTerminatingError($er)
                }
                $PSCmdlet.ThrowTerminatingError($_)
            }
            finally {
                # Each attempt owns its messages/readers; the module owns the client.
                $cts.Cancel()
                if ($null -ne $StreamReader) { $StreamReader.Dispose() }
                if ($null -ne $HttpResponse) { $HttpResponse.Dispose() }
                if ($null -ne $RequestMessage) { $RequestMessage.Dispose() }
                $cts.Dispose()
            }
            Start-Sleep -Milliseconds $Delay
            $RetryCount++
        }
    }
    finally {
        $PlainToken = $null
    }
}
