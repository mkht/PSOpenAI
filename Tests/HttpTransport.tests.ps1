#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.3.0' }
BeforeDiscovery { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'PSOpenAI.psd1') -Force }

BeforeAll {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'PSOpenAI.psd1') -Force
    if (-not ('PSOpenAI.Tests.HttpHandler' -as [type])) {
        $references = @{}
        if ($PSVersionTable.PSVersion.Major -le 5) { $references.ReferencedAssemblies = @('System.Net.Http', 'System.dll') }
        Add-Type -Path (Join-Path $PSScriptRoot 'TestData/HttpTransport.cs') @references
    }
}

Describe 'Shared HTTP transport' -Tag Offline {
    InModuleScope PSOpenAI {
        BeforeAll {
            function Add-TestResponse {
                param ([int]$Status = 200, [string]$Text = '{"ok":true}', [string]$MediaType = 'application/json', [byte[]]$Bytes)
                if ($null -eq $Bytes) { $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Text) }
                $response = [System.Net.Http.HttpResponseMessage]::new([Enum]::ToObject([System.Net.HttpStatusCode], $Status))
                $response.Content = [PSOpenAI.Tests.TrackedContent]::new($Bytes)
                if ($MediaType) { $null = $response.Content.Headers.TryAddWithoutValidation('Content-Type', $MediaType) }
                $script:TestHandler.Responses.Enqueue($response)
                return $response
            }
        }
        BeforeEach {
            $script:TestHandler = [PSOpenAI.Tests.HttpHandler]::new()
            $script:OpenAIHttpTransport.Client = [System.Net.Http.HttpClient]::new($script:TestHandler)
            $script:OpenAIHttpTransport.Client.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
            $script:RequestParams = @{
                Uri = [uri]'https://api.example.test/v1/test'
                ApiKey = ConvertTo-SecureString 'test-secret' -AsPlainText -Force
            }
        }
        AfterEach {
            $script:OpenAIHttpTransport.Client.Dispose()
            $script:OpenAIHttpTransport.Client = $null
        }

        It 'Disposes an abandoned response completing <Timing> cancellation' -TestCases @(
            @{ Timing = 'before' }; @{ Timing = 'after' }
        ) {
            param ($Timing)
            $response = Add-TestResponse
            $source = [System.Threading.Tasks.TaskCompletionSource[System.Net.Http.HttpResponseMessage]]::new()
            $cts = [System.Threading.CancellationTokenSource]::new()
            try {
                if ($Timing -eq 'before') { $source.SetResult($response) }
                $cts.Cancel()
                { Wait-OpenAIHttpTask -Task $source.Task -CancellationToken $cts.Token } | Should -Throw
                if ($Timing -eq 'after') {
                    # Simulate a handler completing after cancellation has already returned.
                    $response.Content.Disposed | Should -BeFalse
                    [PSOpenAI.Tests.HttpHandler]::CompleteOnWorker($source, $response).GetAwaiter().GetResult()
                }
                $response.Content.Disposed | Should -BeTrue
            }
            finally {
                $response.Dispose()
                $cts.Dispose()
            }
        }

        It 'Transfers a successful response to the caller without disposing it' {
            $response = Add-TestResponse
            $source = [System.Threading.Tasks.TaskCompletionSource[System.Net.Http.HttpResponseMessage]]::new()
            $source.SetResult($response)
            try {
                $result = Wait-OpenAIHttpTask -Task $source.Task -CancellationToken ([System.Threading.CancellationToken]::None)
                [object]::ReferenceEquals($result, $response) | Should -BeTrue
                $response.Content.Disposed | Should -BeFalse
            }
            finally { $response.Dispose() }
        }

        It 'Preserves UTF-8 JSON and request-local authentication across calls' {
            $response = Add-TestResponse -Text '{"text":"日本語"}'
            $result = Invoke-OpenAIHttpRequest @RequestParams -Body @{ text = '日本語' } -Organization ' org-test '
            $result | Should -BeExactly '{"text":"日本語"}'
            [System.Text.Encoding]::UTF8.GetString($TestHandler.Requests[0].Body) | Should -BeExactly '{"text":"日本語"}'
            $TestHandler.Requests[0].Headers | Should -Match 'Authorization: Bearer test-secret'
            $TestHandler.Requests[0].Headers | Should -Match 'OpenAI-Organization: org-test'
            $response.Content.Disposed | Should -BeTrue
            $null = Add-TestResponse
            $null = Invoke-OpenAIHttpRequest -Uri https://download.example.test/file -Method Get
            $TestHandler.Requests[1].Headers | Should -Not -Match 'test-secret|org-test|Authorization'
            $TestHandler.Requests[1].Headers | Should -Match 'User-Agent:'
            $TestHandler.Requests[1].Body | Should -BeNullOrEmpty
            $TestHandler.Disposed | Should -BeFalse
        }

        It 'Uses Bearer authentication with additional headers' {
            $null = Add-TestResponse
            $null = Invoke-OpenAIHttpRequest @RequestParams -Body @{ n = 1 } -AdditionalHeaders @{ 'X-Test' = 'value'; 'Content-Type' = 'application/json; charset=utf-8' }
            $TestHandler.Requests[0].Headers | Should -Match 'Authorization: Bearer test-secret'
            $TestHandler.Requests[0].Headers | Should -Not -Match 'api-key:'
            $TestHandler.Requests[0].Headers | Should -Match 'X-Test: value'
            $TestHandler.Requests[0].ContentHeaders | Should -Match 'Content-Type: application/json; charset=utf-8'
        }

        It 'Preserves multipart bytes and rebuilds a request on retry' {
            $response = Add-TestResponse -Status 429 -Text '{"error":{"message":"rate limit"}}'
            $null = $response.Headers.TryAddWithoutValidation('retry-after-ms', '1')
            $null = Add-TestResponse
            $file = Join-Path $TestDrive '画像.bin'
            [IO.File]::WriteAllBytes($file, [byte[]](0, 255, 1))
            $null = Invoke-OpenAIHttpRequest @RequestParams -ContentType 'multipart/form-data' -Body @{ file = Get-Item $file } -MaxRetryCount 1
            $TestHandler.Requests.Count | Should -Be 2
            [Convert]::ToBase64String($TestHandler.Requests[0].Body) | Should -BeExactly ([Convert]::ToBase64String($TestHandler.Requests[1].Body))
            $text = [System.Text.Encoding]::UTF8.GetString($TestHandler.Requests[0].Body)
            $text | Should -Match 'filename="'
            $text | Should -Match "filename\*=utf-8''"
            $TestHandler.Requests[0].ContentHeaders | Should -Match 'multipart/form-data; boundary='
            $response.Content.Disposed | Should -BeTrue
        }

        It 'Preserves binary output and saved bytes' {
            $null = Add-TestResponse -MediaType 'audio/mpeg' -Bytes ([byte[]](0, 255, 128, 1))
            [byte[]]$result = Invoke-OpenAIHttpRequest @RequestParams
            [Convert]::ToBase64String($result) | Should -BeExactly 'AP+AAQ=='
            $null = Add-TestResponse -MediaType 'text/plain' -Bytes ([byte[]](0, 255, 128, 1))
            $file = Join-Path $TestDrive 'download.bin'
            Invoke-OpenAIHttpRequest -Uri https://download.example.test/file -Method Get -OutFile $file
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($file)) | Should -BeExactly 'AP+AAQ=='
        }

        It 'Handles an empty response and a non-JSON HTTP error' {
            $null = Add-TestResponse -Status 204 -Text '' -MediaType ''
            Invoke-OpenAIHttpRequest @RequestParams | Should -BeNullOrEmpty
            $response = Add-TestResponse -Status 502 -Text '<html>gateway error</html>' -MediaType 'text/html'
            try { Invoke-OpenAIHttpRequest @RequestParams -ErrorAction Stop; throw 'Expected HTTP failure' }
            catch {
                $_.Exception | Should -BeOfType APIRequestException
                $_.Exception.StatusCode | Should -Be 502
                $_.Exception.Response | Should -BeOfType System.Net.Http.HttpResponseMessage
                $_.FullyQualifiedErrorId | Should -Match '^PSOpenAI.APIRequest.APIRequestException'
            }
            $response.Content.Disposed | Should -BeTrue
        }

        It 'Does not retry quota errors' {
            $null = Add-TestResponse -Status 429 -Text '{"error":{"message":"quota exhausted","code":"insufficient_quota"}}'
            { Invoke-OpenAIHttpRequest @RequestParams -MaxRetryCount 3 -ErrorAction Stop } | Should -Throw '*quota*'
            $TestHandler.Requests.Count | Should -Be 1
        }

        It 'Preserves SSE data, First and raw lines' {
            $text = "event: test`ndata: {`"n`":1}`n`ndata: {`"n`":2}`n`ndata: [DONE]`n"
            $response = Add-TestResponse -MediaType 'text/event-stream' -Text $text
            @(Invoke-OpenAIHttpRequest -Stream @RequestParams -First 1) | Should -Be @('{"n":1}')
            $response.Content.Disposed | Should -BeTrue
            $null = Add-TestResponse -MediaType 'text/event-stream' -Text $text
            @(Invoke-OpenAIHttpRequest -Stream @RequestParams) | Should -Be @('{"n":1}', '{"n":2}')
            $null = Add-TestResponse -MediaType 'text/event-stream' -Text $text
            @(Invoke-OpenAIHttpRequest -Stream @RequestParams -ReturnRawResponse $true) | Should -Be @('event: test', 'data: {"n":1}', 'data: {"n":2}', 'data: [DONE]')
        }

        It 'Times out stalled <Mode> reads and disposes the stream' -TestCases @(
            @{ Mode = 'normal' }; @{ Mode = 'SSE' }; @{ Mode = 'error' }
        ) {
            param ($Mode)
            $stream = [PSOpenAI.Tests.StalledStream]::new()
            $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]200)
            if ($Mode -eq 'error') { $response.StatusCode = 500 }
            $response.Content = [System.Net.Http.StreamContent]::new($stream)
            $TestHandler.Responses.Enqueue($response)
            $timer = [Diagnostics.Stopwatch]::StartNew()
            try { Invoke-OpenAIHttpRequest @RequestParams -Stream:($Mode -eq 'SSE') -TimeoutSec 1 -ErrorAction Stop; throw 'Expected timeout' }
            catch { $_.Exception | Should -BeOfType TimeoutException }
            $timer.Elapsed.TotalSeconds | Should -BeLessThan 5
            $stream.Disposed | Should -BeTrue
        }

        It 'Does not carry a previous timeout into the next request' {
            $TestHandler.DelayMilliseconds = 1200
            $null = Add-TestResponse
            { Invoke-OpenAIHttpRequest @RequestParams -TimeoutSec 1 -ErrorAction Stop } | Should -Throw '*timeout*'
            Invoke-OpenAIHttpRequest @RequestParams -TimeoutSec 0 | Should -BeExactly '{"ok":true}'
            $script:OpenAIHttpTransport.Client.Timeout | Should -Be ([System.Threading.Timeout]::InfiniteTimeSpan)
        }

        It 'Strips credentials on a cross-origin redirect and preserves 307 body' {
            $response = Add-TestResponse -Status 307
            $response.Headers.Location = [uri]'https://other.example.test/result'
            $null = Add-TestResponse
            $null = Invoke-OpenAIHttpRequest @RequestParams -Body @{ n = 1 } -AdditionalHeaders @{ 'api-key' = 'test-secret' }
            $TestHandler.Requests[1].Headers | Should -Not -Match 'Authorization|api-key|test-secret'
            $TestHandler.Requests[1].Method | Should -BeExactly 'POST'
            [Convert]::ToBase64String($TestHandler.Requests[1].Body) | Should -BeExactly ([Convert]::ToBase64String($TestHandler.Requests[0].Body))
            $response.Content.Disposed | Should -BeTrue
        }

        It 'Releases SSE content when the downstream pipeline stops early' {
            $response = Add-TestResponse -MediaType 'text/event-stream' -Text "data: one`n`ndata: two`n"
            Invoke-OpenAIHttpRequest -Stream @RequestParams | Select-Object -First 1 | Should -BeExactly 'one'
            $response.Content.Disposed | Should -BeTrue
        }

        It 'Uses the shared retry policy for SSE before emitting data' {
            $response = Add-TestResponse -Status 503 -Text '{"error":{"message":"busy"}}'
            $null = $response.Headers.TryAddWithoutValidation('retry-after-ms', '1')
            $null = Add-TestResponse -MediaType 'text/event-stream' -Text "data: ready`n`ndata: [DONE]`n"
            Invoke-OpenAIHttpRequest -Stream @RequestParams -MaxRetryCount 1 | Should -BeExactly 'ready'
            $TestHandler.Requests.Count | Should -Be 2
        }

        It 'Reads compressed UTF-8 through a real loopback HTTP/1.1 connection' {
            $script:OpenAIHttpTransport.Client.Dispose()
            $script:OpenAIHttpTransport.Client = $null
            $buffer = [IO.MemoryStream]::new()
            $gzip = [IO.Compression.GZipStream]::new($buffer, [IO.Compression.CompressionMode]::Compress, $true)
            $bytes = [Text.Encoding]::UTF8.GetBytes('{"text":"日本語"}')
            $gzip.Write($bytes, 0, $bytes.Length)
            $gzip.Dispose()
            $compressed = $buffer.ToArray()
            $buffer.Dispose()
            $header = "HTTP/1.1 200 OK`r`nContent-Type: application/json`r`nContent-Encoding: gzip`r`nContent-Length: $($compressed.Length)`r`nConnection: close`r`n`r`n"
            $server = [PSOpenAI.Tests.LoopbackServer]::new([byte[]]([Text.Encoding]::ASCII.GetBytes($header) + $compressed))
            try {
                Invoke-OpenAIHttpRequest -Uri "http://127.0.0.1:$($server.Port)/test" -Method Get -TimeoutSec 5 | Should -BeExactly '{"text":"日本語"}'
                $server.Completion.GetAwaiter().GetResult()
            }
            finally { $server.Dispose() }
        }
    }
}

Describe 'HTTP client lifetime' -Tag Offline {
    It 'Disposes the client when removing the module' {
        $handler = [PSOpenAI.Tests.HttpHandler]::new()
        & (Get-Module PSOpenAI) {
            param ($Handler)
            $script:OpenAIHttpTransport.Client = [System.Net.Http.HttpClient]::new($Handler)
        } $handler
        Remove-Module PSOpenAI
        $handler.Disposed | Should -BeTrue
        Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'PSOpenAI.psd1') -Force
    }
}
