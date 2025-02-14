#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-ChatCompletion' {
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
  "tool_choice": null,
  "usage": {
    "total_tokens": 31,
    "completion_tokens": 18,
    "prompt_tokens": 13
  },
  "input_user": null,
  "service_tier": "default",
  "tools": null,
  "metadata": {
    "foo": "qux"
  },
  "choices": [
    {
      "index": 0,
      "message": {
        "content": "I am a helpful assistant.",
        "role": "assistant",
        "tool_calls": null,
        "function_call": null
      },
      "finish_reason": "stop",
      "logprobs": null
    }
  ],
  "response_format": null
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Update metadata with completion ID' {
            { $script:Result = Set-ChatCompletion -CompletionId 'chatcmpl-abc123' -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.metadata.foo | Should -Be 'qux'
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Chat.Completion'
        }

        Context 'Parameter Sets' {
            It 'Chat' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Chat.Completion'
                    id         = 'chatcmpl-abc123'
                }
                # Named
                { Set-ChatCompletion -Completion $InObject -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                # Alias
                { Set-ChatCompletion -InputObject $InObject -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                # Positional
                { Set-ChatCompletion $InObject -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Set-ChatCompletion -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'Id' {
                # Named
                { Set-ChatCompletion -CompletionId 'chatcmpl-abc123' -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                # Alias
                { Set-ChatCompletion -Id 'chatcmpl-abc123' -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                # Positional
                { Set-ChatCompletion 'file-abc123' -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'file-abc123' | Set-ChatCompletion -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{completion_id = 'file-abc123' } | Set-ChatCompletion -MetaData @{'foo' = 'qux' } -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 5 -Exactly
            }
        }
    }
}
