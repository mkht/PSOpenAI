# One client per module instance. Authentication belongs to individual requests.
Add-Type -AssemblyName System.Net.Http
# Cleanup may run after the PowerShell pipeline has stopped. Use a CLR callback,
# rather than a scriptblock delegate which requires a runspace on that thread.
if (-not ('PSOpenAI.HttpTaskCleanup' -as [type])) {
    Add-Type -ReferencedAssemblies System.Net.Http -TypeDefinition @'
using System.Threading;
using System.Threading.Tasks;
using System.Net.Http;
namespace PSOpenAI {
    public static class HttpTaskCleanup {
        public static void DisposeResponse(Task<HttpResponseMessage> task) {
            task.ContinueWith(completed => {
                if (completed.Status == TaskStatus.RanToCompletion) {
                    if (completed.Result != null) {
                        try { completed.Result.Dispose(); } catch { }
                    }
                } else {
                    // Observe faults from requests abandoned by the caller.
                    var exception = completed.Exception;
                }
            }, CancellationToken.None, TaskContinuationOptions.ExecuteSynchronously, TaskScheduler.Default);
        }
    }
}
'@
}
$script:OpenAIHttpTransport = @{ Client = $null }

function Get-OpenAIHttpClient {
    param ([uri]$Uri)

    if ($null -eq $script:OpenAIHttpTransport.Client) {
        if ('System.Net.Http.SocketsHttpHandler' -as [type]) {
            $Handler = New-Object System.Net.Http.SocketsHttpHandler
            $Handler.PooledConnectionLifetime = [timespan]::FromMinutes(5)
        }
        else {
            $Handler = [System.Net.Http.HttpClientHandler]::new()
        }
        $Handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
        $Handler.UseCookies = $false
        $Handler.AllowAutoRedirect = $false
        $script:OpenAIHttpTransport.Client = [System.Net.Http.HttpClient]::new($Handler)
        $script:OpenAIHttpTransport.Client.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
    }
    if ($PSVersionTable.PSVersion.Major -le 5) {
        # Framework has no PooledConnectionLifetime. Recycle connections, not active clients.
        [System.Net.ServicePointManager]::FindServicePoint($Uri).ConnectionLeaseTimeout = 300000
    }
    return $script:OpenAIHttpTransport.Client
}

function Wait-OpenAIHttpTask {
    param (
        [System.Threading.Tasks.Task]$Task,
        [System.Threading.CancellationToken]$CancellationToken
    )

    $Delivered = $false
    try {
        # Polling also lets PowerShell stop the pipeline on runtimes without cancellable reads.
        while (-not $Task.IsCompleted) {
            $CancellationToken.ThrowIfCancellationRequested()
            try { $null = $Task.Wait(100, $CancellationToken) }
            catch [AggregateException] { break }
        }
        $CancellationToken.ThrowIfCancellationRequested()
        $Result = $Task.GetAwaiter().GetResult()
        if ($null -ne $Result) { Write-Output (, $Result) }
        $Delivered = $true
    }
    finally {
        if (-not $Delivered -and $Task -is [System.Threading.Tasks.Task[System.Net.Http.HttpResponseMessage]]) {
            [PSOpenAI.HttpTaskCleanup]::DisposeResponse($Task)
        }
    }
}

function Send-OpenAIHttpRequest {
    param (
        [System.Net.Http.HttpRequestMessage]$Request,
        [System.Threading.CancellationToken]$CancellationToken
    )

    $CurrentRequest = $Request
    try {
        # Framework HttpClient disposes request content after sending it.
        $RequestBytes = if ($null -ne $Request.Content) {
            Wait-OpenAIHttpTask -Task ($Request.Content.ReadAsByteArrayAsync()) -CancellationToken $CancellationToken
        }
        $ContentHeaders = if ($null -ne $Request.Content) { @($Request.Content.Headers) }
        for ($RedirectCount = 0; ; $RedirectCount++) {
            $Client = Get-OpenAIHttpClient -Uri $CurrentRequest.RequestUri
            $Response = Wait-OpenAIHttpTask -Task ($Client.SendAsync($CurrentRequest, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $CancellationToken)) -CancellationToken $CancellationToken
            if ([int]$Response.StatusCode -notin @(301, 302, 303, 307, 308) -or $null -eq $Response.Headers.Location) {
                return $Response
            }
            try {
                if ($RedirectCount -ge 5) { throw [System.Net.Http.HttpRequestException]::new('Too many HTTP redirects.') }
                $NextUri = [uri]::new($CurrentRequest.RequestUri, $Response.Headers.Location)
                if ($NextUri.Scheme -notin @('http', 'https') -or ($CurrentRequest.RequestUri.Scheme -eq 'https' -and $NextUri.Scheme -ne 'https')) {
                    throw [System.Net.Http.HttpRequestException]::new('Unsafe HTTP redirect.')
                }
                $Method = $CurrentRequest.Method
                if (([int]$Response.StatusCode -eq 303 -and $Method.Method -ne 'HEAD') -or ([int]$Response.StatusCode -in @(301, 302) -and $Method.Method -eq 'POST')) {
                    $Method = [System.Net.Http.HttpMethod]::Get
                }
                $NextRequest = [System.Net.Http.HttpRequestMessage]::new($Method, $NextUri)
                try {
                    $NextRequest.Version = $CurrentRequest.Version
                    foreach ($Header in $CurrentRequest.Headers) {
                        # Never forward credentials (including Azure keys) to another origin.
                        if ($NextUri.GetLeftPart([System.UriPartial]::Authority) -ne $CurrentRequest.RequestUri.GetLeftPart([System.UriPartial]::Authority) -and $Header.Key -in @('Authorization', 'api-key', 'Cookie', 'Proxy-Authorization', 'Host', 'OpenAI-Organization')) { continue }
                        $null = $NextRequest.Headers.TryAddWithoutValidation($Header.Key, $Header.Value)
                    }
                    if ($Method -eq $CurrentRequest.Method -and $null -ne $CurrentRequest.Content) {
                        $NextRequest.Content = [System.Net.Http.ByteArrayContent]::new([byte[]]$RequestBytes)
                        foreach ($Header in $ContentHeaders) {
                            $null = $NextRequest.Content.Headers.TryAddWithoutValidation($Header.Key, $Header.Value)
                        }
                    }
                }
                catch { $NextRequest.Dispose(); throw }
                if ($CurrentRequest -ne $Request) { $CurrentRequest.Dispose() }
                $CurrentRequest = $NextRequest
            }
            finally { $Response.Dispose() }
        }
    }
    finally {
        if ($CurrentRequest -ne $Request) { $CurrentRequest.Dispose() }
    }
}
