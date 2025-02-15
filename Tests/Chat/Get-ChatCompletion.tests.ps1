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
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
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
            }

            { $script:Result = Get-ChatCompletion -ID 'chatcmpl-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -Scope It
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
            }

            { $script:Result = Get-ChatCompletion -All -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -Scope It
            $Result | Should -HaveCount 2
        }

        It 'Timeout' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                Start-Sleep -Seconds 1
                @'
{
  "object": "list",
  "data": [
    {
      "object": "chat.completion",
      "id": "chatcmpl-abc123",
      "model": "gpt-4o-2024-08-06",
      "created": 1738960610,
      "request_id": "req_ded123",
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
  ],
  "first_id": "chatcmpl-abc123",
  "last_id": "chatcmpl-abc123",
  "has_more": true
}
'@
            }
            { Get-ChatCompletion -TimeoutSec 2 -All -ea Stop } | Should -Throw -ExceptionType ([System.TimeoutException])
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 2 -Exactly -Scope It
        }

        Context 'Parameter Sets' {
            BeforeAll {
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
                }
            }

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
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
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
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'List' {
                { Get-ChatCompletion -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            }
        }
    }
}