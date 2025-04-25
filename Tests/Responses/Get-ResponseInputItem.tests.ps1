#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ResponseInputItem' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List all items' {
            InModuleScope $script:ModuleName {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "object": "list",
  "data": [
    {
      "id": "msg_abc123",
      "type": "message",
      "role": "user",
      "content": [
        {
          "type": "input_text",
          "text": "Tell me a three sentence bedtime story about a unicorn."
        }
      ]
    }
  ],
  "first_id": "msg_abc123",
  "last_id": "msg_abc123",
  "has_more": false
}
'@
                }

                { $script:Result = Get-ResponseInputItem -ResponseId 'resp_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result | Should -HaveCount 1
                $Result[0].id | Should -BeExactly 'msg_abc123'
            }
        }

        It 'List all messages (pagenate)' {
            InModuleScope $script:ModuleName {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "object": "list",
  "data": [
    {
      "id": "msg_abc123",
      "type": "message",
      "role": "user",
      "content": [
        {
          "type": "input_text",
          "text": "Tell me a three sentence bedtime story about a unicorn."
        }
      ]
    }
  ],
  "first_id": "msg_abc123",
  "last_id": "msg_abc123",
  "has_more": true
}
'@
                } -ParameterFilter { -not $Uri.Query.Contains('after=') }

                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "object": "list",
  "data": [
    {
      "id": "msg_abc456",
      "type": "message",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "How can I help you?"
        }
      ]
    }
  ],
  "first_id": "msg_abc456",
  "last_id": "msg_abc456",
  "has_more": false
}
'@
                } -ParameterFilter { $Uri.Query.Contains('after=') }

                { $script:Result = Get-ResponseInputItem -ResponseId 'resp_abc123' -All -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { -not $Uri.Query.Contains('after=') }
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri.Query.Contains('after=') }
                $Result | Should -HaveCount 2
                $Result[0].id | Should -BeExactly 'msg_abc123'
                $Result[1].id | Should -BeExactly 'msg_abc456'
            }
        }
    }
}
