#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ChatCompletionMessage' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }

        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List all messages' {
            InModuleScope $script:ModuleName {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "object": "list",
  "data": [
    {
      "id": "chatcmpl-abc123-0",
      "role": "user",
      "content": "write a haiku about ai",
      "name": null,
      "content_parts": null
    },
    {
      "id": "chatcmpl-abc123-1",
      "role": "assistant",
      "content": "Silicon whispers, Dreams spun in coded currents, Thoughts without a heart.",
      "name": null,
      "content_parts": null
    }
  ],
  "first_id": "chatcmpl-abc123-0",
  "last_id": "chatcmpl-abc123-2",
  "has_more": false
}
'@
                }

                { $script:Result = Get-ChatCompletionMessage -CompletionId 'chatcmpl-abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result | Should -HaveCount 2
                $Result[0].id | Should -BeExactly 'chatcmpl-abc123-0'
                $Result[0] | Should -BeOfType [Ordered]
                $Result[0].content | Should -BeExactly 'write a haiku about ai'
            }
        }
    }
}
