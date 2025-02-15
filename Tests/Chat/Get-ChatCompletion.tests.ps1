#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ChatCompletion' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "object": "chat.completion",
  "id": "chatcmpl-abc123",
  "model": "gpt-4o-2024-08-06",
  "created": 1738960610,
  "request_id": "req_ded123",
  "usage": {
    "total_tokens": 31
  },
  "metadata": {},
  "choices": [
    {
      "index": 0,
      "message": {
        "content": "I am a helpful assistant.",
        "role": "assistant"
      },
      "finish_reason": "stop"
    }
  ],
  "response_format": null
}
'@
            } -ParameterFilter { 'https://api.openai.com/v1/chat/completions/chatcmpl-abc123' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "object": "list",
  "data": [
    {
      "object": "chat.completion",
      "id": "chatcmpl-abc123",
      "model": "gpt-4o-2024-08-06",
      "created": 1738960610,
      "request_id": "req_ded123",
      "usage": {
        "total_tokens": 31
      },
      "metadata": {},
      "choices": [
        {
          "index": 0,
          "message": {
            "content": "I am a helpful assistant.",
            "role": "assistant"
          },
          "finish_reason": "stop"
        }
      ],
      "response_format": null
    },
    {
      "object": "chat.completion",
      "id": "chatcmpl-abc456",
      "model": "gpt-4o-2024-08-06",
      "created": 1738960611,
      "request_id": "req_ded456",
      "usage": {
        "total_tokens": 25
      },
      "metadata": {},
      "choices": [
        {
          "index": 0,
          "message": {
            "content": "How do I help you?",
            "role": "assistant"
          },
          "finish_reason": "stop"
        }
      ],
      "response_format": null
    }
  ],
  "first_id": "chatcmpl-abc123",
  "last_id": "chatcmpl-abc456",
  "has_more": false
}
'@
            } -ParameterFilter { 'https://api.openai.com/v1/chat/completions' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Get-ChatCompletionMessage {
                [ordered]@{
                    id      = 'chatcmpl-abc123-0'
                    role    = 'user'
                    content = 'Hello.'
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get a single object with ID' {
            { $script:Result = Get-ChatCompletion -ID 'chatcmpl-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/chat/completions/chatcmpl-abc123' -eq $Uri }
            Should -Invoke Get-ChatCompletionMessage -ModuleName $script:ModuleName -Times 1
            $Result.id | Should -BeExactly 'chatcmpl-abc123'
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Chat.Completion'
            $Result.Message | Should -BeExactly 'Hello.'
            $Result.Answer[0] | Should -BeExactly 'I am a helpful assistant.'
            $Result.History[0].id | Should -Be 'chatcmpl-abc123-0'
            $Result.History[0].PSTypeNames | Should -Contain 'PSOpenAI.Chat.Completion.Message'
            $Result.History[1].content | Should -Be 'I am a helpful assistant.'
        }

        It 'List all completions.' {
            { $script:Result = Get-ChatCompletion -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/chat/completions' -eq $Uri }
            $Result | Should -HaveCount 2
        }

        Context 'Parameter Sets' {
            It 'Get_Chat' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Chat.Completion'
                    id         = 'chatcmpl-abc123'
                }
                # Named
                { Get-ChatCompletion -Completion $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ChatCompletion $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ChatCompletion -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/chat/completions/chatcmpl-abc123' -eq $Uri }
            }

            It 'Get_Id' {
                # Named
                { Get-ChatCompletion -CompletionId 'chatcmpl-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ChatCompletion 'chatcmpl-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'chatcmpl-abc123' | Get-ChatCompletion -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{ID = 'chatcmpl-abc123' } | Get-ChatCompletion -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/chat/completions/chatcmpl-abc123' -eq $Uri }
            }

            It 'List' {
                { Get-ChatCompletion -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/chat/completions' -eq $Uri }
            }
        }
    }
}
