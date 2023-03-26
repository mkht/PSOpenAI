#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ChatCompletion' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIToken { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Chat completion' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "chatcmpl-123",
    "object": "chat.completion",
    "created": 1677652288,
    "choices": [{
        "index": 0,
        "message": {
        "role": "assistant",
        "content": "Hello there, how may I assist you today?"
        },
        "finish_reason": "stop"
    }],
    "usage": {
        "prompt_tokens": 9,
        "completion_tokens": 12,
        "total_tokens": 21
    }
}
'@ }
            { $script:Result = Request-ChatCompletion -Message 'test' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer | Should -Be 'Hello there, how may I assist you today?'
            $Result.created | Should -BeOfType [datetime]
            $Result.Message | Should -Be 'test'
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be 'test'
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[1].Content | Should -Be 'Hello there, how may I assist you today?'
        }

        It 'Stream output' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                '{"id":"chatcmpl-sf547Pa","object":"chat.completion.chunk","created":1679839328,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"ECHO"},"index":0,"finish_reason":null}]}'
            }
            $Result = Request-ChatCompletion -Message 'test' -Stream -InformationVariable StreamOut -ea Stop
            Should -InvokeVerifiable
            $Result | Should -Be 'ECHO'
            $StreamOut | Should -Be 'ECHO'
        }

        It 'Use collect endpoint' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @"
{"choices": [{"message": {"content": "$($PesterBoundParameters.Uri)"}}]}
"@ }
            $Result = Request-ChatCompletion -Message 'test'
            $Result.Answer | Should -Match 'chat/completions'
        }

        It 'Request-ChatGPT as alias' {
            $Alias = Get-Alias 'Request-ChatGPT' -ea Ignore
            $Alias.ResolvedCommandName | Should -Be 'Request-ChatCompletion'
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''

            # To avoid api rate limit
            # Free trial tier has 20 requests per minutes
            Start-Sleep -Seconds 3.1
        }

        It 'Chat completion' {
            { $script:Result = Request-ChatCompletion -Message '君の名は？' -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -BeOfType [string]
            $Result.created | Should -BeOfType [datetime]
            $Result.Message | Should -Be '君の名は？'
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be '君の名は？'
            $Result.History[1].Role | Should -Be 'assistant'
        }

        It 'Chat completion, multiple answers' {
            { $script:Result = Request-ChatCompletion -Message 'What your name' -NumberOfAnswers 2 -MaxTokens 10 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 2
        }

        It 'Pipeline input (Conversations)' {
            { $script:First = Request-ChatCompletion -Message 'What' -MaxTokens 10 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            { $script:Result = $script:First | Request-ChatCompletion -Message 'When' -MaxTokens 10 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be 'What'
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[2].Role | Should -Be 'user'
            $Result.History[2].Content | Should -Be 'When'
            $Result.History[3].Role | Should -Be 'assistant'
        }

        It 'Stream output' {
            $Result = Request-ChatCompletion `
                -Message 'Please describe about ChatGPT' `
                -MaxTokens 32 `
                -Stream `
                -InformationVariable Info `
                -TimeoutSec 30 -ea Stop `
            | select -First 10
            $Result | Should -HaveCount 10
            ([string[]]$Info) | Should -Be ([string[]]$Result)
        }
    }
}
