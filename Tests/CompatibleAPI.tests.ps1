#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'PSOpenAI.psd1') -Force
    if (-not ('PSOpenAI.Tests.HttpHandler' -as [type])) {
        $references = @{}
        if ($PSVersionTable.PSVersion.Major -le 5) { $references.ReferencedAssemblies = @('System.Net.Http', 'System.dll') }
        Add-Type -Path (Join-Path $PSScriptRoot 'TestData/HttpTransport.cs') @references
    }
}

Describe 'OpenAI-compatible connection contract' -Tag Offline {
    BeforeEach {
        Clear-OpenAIContext
    }

    AfterAll {
        Clear-OpenAIContext
    }

    It 'Removes legacy parameters from every exported command' {
        foreach ($command in Get-Command -Module PSOpenAI -CommandType Function) {
            foreach ($name in 'ApiType', 'ApiVersion', 'AuthType') {
                $command.Parameters.ContainsKey($name) | Should -BeFalse -Because "$($command.Name) no longer has $name"
            }
        }
    }

    It 'Rejects an explicitly supplied legacy <Name> parameter' -TestCases @(
        @{ Name = 'ApiType'; Value = 'OpenAI' }
        @{ Name = 'ApiVersion'; Value = '2025-04-01-preview' }
        @{ Name = 'AuthType'; Value = 'azure_ad' }
    ) {
        param ($Name, $Value)
        $legacy = @{ $Name = $Value }
        { Set-OpenAIContext @legacy -ErrorAction Stop } | Should -Throw
        { Request-ChatCompletion -Message 'test' @legacy -ErrorAction Stop } | Should -Throw
        { Connect-RealtimeSession @legacy -ErrorAction Stop } | Should -Throw
    }

    It 'Returns only supported context properties and accepts SecureString tokens' {
        $token = ConvertTo-SecureString 'test-token' -AsPlainText -Force
        Set-OpenAIContext -ApiBase 'https://example.test/openai/v1/' -ApiKey $token -TimeoutSec 12
        $context = Get-OpenAIContext
        @($context.PSObject.Properties.Name | Sort-Object) -join ',' | Should -BeExactly 'ApiBase,ApiKey,MaxRetryCount,Organization,TimeoutSec'
        $context.ApiKey | Should -BeOfType [securestring]
        $context.TimeoutSec | Should -Be 12
        Clear-OpenAIContext
        (Get-OpenAIContext).ApiBase | Should -BeNullOrEmpty
    }

    It 'Builds paths relative to <Base> without a legacy API version' -TestCases @(
        @{ Base = 'https://example.openai.azure.com/openai/v1'; Prefix = 'https://example.openai.azure.com/openai/v1/' }
        @{ Base = 'https://example.openai.azure.com/openai/v1/'; Prefix = 'https://example.openai.azure.com/openai/v1/' }
        @{ Base = 'https://example.services.ai.azure.com/openai/v1/'; Prefix = 'https://example.services.ai.azure.com/openai/v1/' }
        @{ Base = 'http://localhost:1234/proxy/v1'; Prefix = 'http://localhost:1234/proxy/v1/' }
    ) {
        param ($Base, $Prefix)
        InModuleScope PSOpenAI -Parameters @{ Base = $Base; Prefix = $Prefix } {
            $paths = @{
                'Chat.Completion' = 'chat/completions'
                'Responses' = 'responses'
                'Embeddings' = 'embeddings'
                'Image.Edit' = 'images/edits'
                'Audio.Transcription' = 'audio/transcriptions'
                'Batch' = 'batches'
            }
            foreach ($entry in $paths.GetEnumerator()) {
                $resolved = Get-OpenAIAPIParameter -EndpointName $entry.Key -Parameters @{ ApiBase = $Base; ApiKey = 'test-key' }
                $resolved.Uri.AbsoluteUri | Should -BeExactly ($Prefix + $entry.Value)
                $resolved.Uri.Query | Should -BeNullOrEmpty
            }
            $realtime = Get-OpenAIAPIEndpoint -EndpointName Realtime -ApiBase $Base
            $realtime.Uri.AbsoluteUri | Should -BeExactly (($Prefix -replace '^http', 'ws') + 'realtime')
        }
    }

    It 'Preserves preview query options without a dedicated ApiVersion parameter' {
        InModuleScope PSOpenAI {
            $request = Initialize-OpenAIAPIRequestParam -Uri 'https://example.test/openai/v1/images/edits' -AdditionalQuery @{ 'api-version' = 'preview' } -AdditionalHeaders @{ 'feature' = 'preview' }
            $request.Uri.AbsoluteUri | Should -BeExactly 'https://example.test/openai/v1/images/edits?api-version=preview'
            $request.Headers.feature | Should -BeExactly 'preview'
        }
    }

    It 'Sends the <Session> WebSocket handshake with Bearer authentication' -TestCases @(
        @{ Session = 'realtime'; Query = 'model=my-deployment' }
        @{ Session = 'transcription'; Query = 'intent=transcription' }
    ) {
        param ($Session, $Query)
        # Deliberately reject the handshake after recording it; no receive loop or external service is needed.
        $response = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 400 Bad Request`r`nContent-Length: 0`r`nConnection: close`r`n`r`n")
        $server = [PSOpenAI.Tests.LoopbackServer]::new($response)
        try {
            Set-OpenAIContext -ApiBase "http://127.0.0.1:$($server.Port)/openai/v1/" -ApiKey (ConvertTo-SecureString 'handshake-token' -AsPlainText -Force)
            if ($Session -eq 'realtime') {
                { Connect-RealtimeSession -Model 'my-deployment' -ErrorAction Stop } | Should -Throw
            }
            else {
                { Connect-RealtimeTranscriptionSession -ErrorAction Stop } | Should -Throw
            }
            $server.Completion.GetAwaiter().GetResult()
            $server.RequestHeaders | Should -Match ([regex]::Escape("GET /openai/v1/realtime?$Query HTTP/1.1"))
            $server.RequestHeaders | Should -Match 'Authorization: Bearer handshake-token'
            $server.RequestHeaders | Should -Not -Match 'api-key:|api-version='
        }
        finally {
            $server.Dispose()
            InModuleScope PSOpenAI { $script:WebSocketClient = $null }
        }
    }

    It 'Keeps deployment names and batch URLs independent of the API base' {
        Set-OpenAIContext -ApiBase 'https://example.test/openai/v1/' -ApiKey 'test-key'
        $batch = Request-ChatCompletion -Model 'my-production-deployment' -Message 'test' -AsBatch
        $batch.url | Should -BeExactly '/v1/chat/completions'
        $batch.body.model | Should -BeExactly 'my-production-deployment'
        $responseBatch = Request-Response -Model 'my-production-deployment' -Message 'test' -AsBatch
        $responseBatch.url | Should -BeExactly '/v1/responses'
        $responseBatch.body.model | Should -BeExactly 'my-production-deployment'
    }

    It 'Forwards the custom connection through Batch upload and job creation' {
        Mock -ModuleName PSOpenAI Add-OpenAIFile { [pscustomobject]@{ id = 'file-test' } }
        Mock -ModuleName PSOpenAI Invoke-OpenAIHttpRequest { '{"id":"batch-test","object":"batch","status":"validating"}' }
        Set-OpenAIContext -ApiBase 'https://example.test/openai/v1/' -ApiKey 'test-key'
        $batch = Request-ChatCompletion -Model 'deployment' -Message 'test' -AsBatch
        $null = $batch | Start-Batch
        Should -Invoke -ModuleName PSOpenAI Add-OpenAIFile -Times 1 -Exactly -ParameterFilter {
            $ApiBase -eq 'https://example.test/openai/v1/' -and $null -ne $ApiKey -and
            ([Text.Encoding]::UTF8.GetString($Content) | ConvertFrom-Json).url -eq '/v1/chat/completions'
        }
        Should -Invoke -ModuleName PSOpenAI Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsoluteUri -eq 'https://example.test/openai/v1/batches' -and $Body.endpoint -eq '/v1/chat/completions'
        }
    }

    It 'Uploads image edits as multipart files with the deployment name' {
        Mock -ModuleName PSOpenAI Invoke-OpenAIHttpRequest { '{"created":1713833628,"data":[]}' }
        $imagePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Docs/images/fether_mask.png'
        $null = Request-ImageEdit -Image $imagePath -Mask $imagePath -Prompt 'test' -Model 'image-deployment' -ApiBase 'https://example.test/openai/v1/' -ApiKey 'test-key'
        Should -Invoke -ModuleName PSOpenAI Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsoluteUri -eq 'https://example.test/openai/v1/images/edits' -and
            $ContentType -eq 'multipart/form-data' -and $Body.image -is [IO.FileInfo] -and
            $Body.mask -is [IO.FileInfo] -and $Body.model -eq 'image-deployment'
        }
    }

}

Describe 'Optional compatible server smoke test' -Tag Online {
    It 'Creates a chat completion using an explicitly configured server' -Skip:(-not ($env:PSOPENAI_COMPAT_API_BASE -and $env:PSOPENAI_COMPAT_API_KEY -and $env:PSOPENAI_COMPAT_MODEL)) {
        $result = Request-ChatCompletion -ApiBase $env:PSOPENAI_COMPAT_API_BASE -ApiKey $env:PSOPENAI_COMPAT_API_KEY -Model $env:PSOPENAI_COMPAT_MODEL -Message 'Reply with OK.' -TimeoutSec 30 -ErrorAction Stop
        $result.object | Should -BeExactly 'chat.completion'
        $result.choices | Should -Not -BeNullOrEmpty
    }
}

Describe 'Azure AI v1 integration tests' -Tag @('Online', 'Azure') {
    BeforeAll {
        if ($env:AZURE_ENDPOINT -and $env:AZURE_API_KEY) {
            $script:AzureApiBase = $env:AZURE_ENDPOINT.TrimEnd('/')
            if ($script:AzureApiBase -notmatch '/openai/v1$') {
                $script:AzureApiBase += '/openai/v1'
            }
            $script:AzureApiBase += '/'
            Set-OpenAIContext -ApiBase $script:AzureApiBase -ApiKey $env:AZURE_API_KEY -TimeoutSec 120 -MaxRetryCount 0
        }

        $script:AzureChatModel = 'gpt-5.6-luna'
        if ($env:AZURE_CHAT_MODEL) { $script:AzureChatModel = $env:AZURE_CHAT_MODEL }
        $script:AzureAudioModel = 'gpt-audio-mini'
        if ($env:AZURE_AUDIO_MODEL) { $script:AzureAudioModel = $env:AZURE_AUDIO_MODEL }
        $script:AzureImageModel = 'gpt-image-2.5-flare'
        if ($env:AZURE_IMAGE_MODEL) { $script:AzureImageModel = $env:AZURE_IMAGE_MODEL }
    }

    AfterAll {
        Clear-OpenAIContext
    }

    It 'Creates a chat completion with the configured chat deployment' -Skip:(-not ($env:AZURE_ENDPOINT -and $env:AZURE_API_KEY)) {
        $result = Request-ChatCompletion -Model $script:AzureChatModel -Message 'Reply with OK.' -MaxCompletionTokens 20 -TimeoutSec 90 -ErrorAction Stop
        $result.object | Should -BeExactly 'chat.completion'
        $result.choices | Should -Not -BeNullOrEmpty
    }

    It 'Creates a response with the configured chat deployment' -Skip:(-not ($env:AZURE_ENDPOINT -and $env:AZURE_API_KEY)) {
        $result = Request-Response -Model $script:AzureChatModel -Message 'Reply with OK.' -MaxOutputTokens 20 -Store $false -TimeoutSec 90 -ErrorAction Stop
        $result.object | Should -BeExactly 'response'
        $result.output_text | Should -Not -BeNullOrEmpty
    }

    It 'Handles audio input and output with the configured audio deployment' -Skip:(-not ($env:AZURE_ENDPOINT -and $env:AZURE_API_KEY)) {
        $audioPath = Join-Path $TestDrive 'audio-output.mp3'
        $result = Request-ChatCompletion -Model $script:AzureAudioModel -Message 'この音声の内容を短く説明してください。' -InputAudio (Join-Path $PSScriptRoot 'TestData/voice_japanese.mp3') -Modalities @('text', 'audio') -Voice 'shimmer' -AudioOutFile $audioPath -TimeoutSec 120 -ErrorAction Stop
        $result.object | Should -BeExactly 'chat.completion'
        $result.choices | Should -Not -BeNullOrEmpty
        $audioPath | Should -Exist
    }

    It 'Generates an image with the configured image deployment' -Skip:(-not ($env:AZURE_ENDPOINT -and $env:AZURE_API_KEY)) {
        $imagePath = Join-Path $TestDrive 'generated.png'
        $null = Request-ImageGeneration -Model $script:AzureImageModel -Prompt 'A small red paper crane on a plain light background.' -Size '1024x1024' -OutFile $imagePath -TimeoutSec 120 -MaxRetryCount 0 -ErrorAction Stop
        $imagePath | Should -Exist
        (Get-Item $imagePath).Length | Should -BeGreaterThan 0
    }
}
