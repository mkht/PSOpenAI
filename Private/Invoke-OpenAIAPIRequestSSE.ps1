using namespace System.Text
using namespace System.Net
using namespace System.Net.Http

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
        [securestring]$Token,

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [int]$RetryCount = 0
    )

    # Decrypt securestring
    $bstr = [Marshal]::SecureStringToBSTR($Token)
    $PlainToken = [Marshal]::PtrToStringBSTR($bstr)
    # Create HttpClient and messages
    $HttpClient = [System.Net.Http.HttpClient]::new()
    $RequestMessage = [System.Net.Http.HttpRequestMessage]::new($Method, $Uri)
    $RequestMessage.Content = [System.Net.Http.StringContent]::new(($Body | ConvertTo-Json -Compress), [Encoding]::UTF8, $ContentType)
    $RequestMessage.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $PlainToken)
    # Set timeout
    $cts = [System.Threading.CancellationTokenSource]::new()
    if ($TimeoutSec -gt 0 -and $TimeoutSec -lt ([int]::MaxValue / 1000)) {
        $cts.CancelAfter($TimeoutSec * 1000)
    }
    $CancelToken = $cts.Token

    # Send API Request
    try {
        $HttpResponse = $HttpClient.SendAsync($RequestMessage, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $CancelToken).GetAwaiter().GetResult()
        if (-not $HttpResponse.IsSuccessStatusCode) {
            $ErrorCode = $HttpResponse.StatusCode.value__
            $ErrorReason = $HttpResponse.ReasonPhrase

            # Retry on [429] or [5xx]
            if (($ErrorCode -ge 500 -and $ErrorCode -le 599) -or ($ErrorCode -eq 429)) {
                if ($RetryCount -lt $MaxRetryCount) {
                    $Delay = Get-RetryDelay -RetryCount $RetryCount
                    Write-Warning ('OpenAI API returned an {0} ({1})' -f $ErrorCode, $ErrorReason)
                    Write-Warning ('Retry the request after waiting {0} ms (retry count: {1})' -f $Delay, $RetryCount)
                    Start-Sleep -Milliseconds $Delay
                    $PSBoundParameters.RetryCount = (++$RetryCount)
                    Invoke-OpenAIAPIRequestSSE @PSBoundParameters
                    return
                }
            }

            throw ([System.Net.Http.HttpRequestException]::new(('OpenAI API returned an {0} ({1})' -f $ErrorCode, $ErrorReason)))
            return
        }
        $ResponseStream = $HttpResponse.Content.ReadAsStreamAsync().Result
        $StreamReader = [System.IO.StreamReader]::new($ResponseStream, [Encoding]::UTF8)

        while (-not $StreamReader.EndOfStream) {
            $data = $null
            #Timeout
            $CancelToken.ThrowIfCancellationRequested()
            #Retrive response content
            $data = [string]$StreamReader.ReadLine()
            if (-not $data.StartsWith('data: ')) { continue }
            if ($data -eq 'data: [DONE]') { break }
            #Output
            Write-Output $data.Substring(6)    # ("data: ").Length -> 6
        }

    }
    catch [OperationCanceledException] {
        # Convert OperationCanceledException to TimeoutException
        Write-Error -Exception ([TimeoutException]::new('The operation was canceled due to timeout.', $_.Exception))
        return
    }
    catch {
        Write-Error -Exception $_.Exception
        return
    }
    finally {
        $bstr = $PlainToken = $null
        try {
            $cts.Dispose()
            $HttpClient.Dispose()
            $HttpResponse.Dispose()
            $ResponseStream.Dispose()
            $RequestMessage.Dispose()
        }
        catch {}
    }
}
