#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Response' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Get-ResponseInputItem {
                @(
                    [pscustomobject]@{
                        id      = 'msg_abc123-0'
                        role    = 'user'
                        content = @{
                            type = 'input_text'
                            text = 'Hello.'
                        }
                    },
                    [pscustomobject]@{
                        id      = 'msg_abc123-1'
                        role    = 'assistant'
                        content = @{
                            type = 'output_text'
                            text = 'Hello! How can I assist you today?'
                        }
                    },
                    [pscustomobject]@{
                        id      = 'msg_abc123-2'
                        role    = 'user'
                        content = @{
                            type = 'input_text'
                            text = "What's the weather today?"
                        }
                    }
                )
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get a single object by ID' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abc123",
  "object": "response",
  "created_at": 1743924446,
  "status": "completed",
  "error": null,
  "incomplete_details": null,
  "instructions": null,
  "max_output_tokens": null,
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_abc123-3",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "It is a sunny day.",
          "annotations": []
        }
      ]
    }
  ],
  "previous_response_id": null,
  "store": true,
  "text": {
    "format": {
      "type": "text"
    }
  },
  "user": null,
  "metadata": {}
}
'@
            }

            { $script:Result = Get-Response -Id 'resp_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -Scope It
            Should -Invoke Get-ResponseInputItem -ModuleName $script:ModuleName -Times 1
            $Result.id | Should -BeExactly 'resp_abc123'
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Response'
            $Result.LastUserMessage | Should -BeExactly "What's the weather today?"
            $Result.output_text | Should -Not -BeNullOrEmpty
            $Result.History | Should -HaveCount 4
            $Result.History[0].id | Should -Be 'msg_abc123-0'
            $Result.History[-1].id | Should -Be 'msg_abc123-3'
        }

        Context 'Parameter Sets' {
            BeforeAll {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abc123",
  "object": "response",
  "created_at": 1743924446,
  "status": "completed",
  "error": null,
  "incomplete_details": null,
  "instructions": null,
  "max_output_tokens": null,
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_abc123-3",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "It is a sunny day.",
          "annotations": []
        }
      ]
    }
  ],
  "previous_response_id": null,
  "store": true,
  "text": {
    "format": {
      "type": "text"
    }
  },
  "user": null,
  "metadata": {}
}
'@
                }
            }

            It 'Get_Response' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Response'
                    id         = 'resp_abc123'
                }
                # Named
                { Get-Response -Response $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Response $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-Response -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Get_Id' {
                # Named
                { Get-Response -ResponseId 'resp_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Response 'resp_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'resp_abc123' | Get-Response -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{ID = 'resp_abc123' } | Get-Response -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext

            $script:TestResponse = Request-Response -Model 'gpt-4.1-nano' -Message 'Hello' -Store $true -TimeoutSec 30 -ErrorAction Stop
            Start-Sleep -Seconds 5
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get response by object' {
            { $splat = @{
                    Response    = $script:TestResponse
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Get-Response @splat
            } | Should -Not -Throw
            $Result.id | Should -Be $script:TestResponse.id
            $Result.LastUserMessage | Should -BeExactly $script:TestResponse.LastUserMessage
            $Result.output_text | Should -BeExactly $script:TestResponse.output_text
            $Result.History | Should -HaveCount 2
        }

        It 'Get response by id' {
            { $splat = @{
                    ResponseId  = $script:TestResponse.id
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Get-Response @splat
            } | Should -Not -Throw
            $Result.id | Should -Be $script:TestResponse.id
            $Result.LastUserMessage | Should -BeExactly $script:TestResponse.LastUserMessage
            $Result.output_text | Should -BeExactly $script:TestResponse.output_text
            $Result.History | Should -HaveCount 2
        }
    }

    Context 'Integration tests (Azure)' -Tag 'Azure' {

        BeforeAll {
            # Set Context for Azure OpenAI
            $AzureContext = @{
                ApiType    = 'Azure'
                AuthType   = 'Azure'
                ApiKey     = $env:AZURE_OPENAI_API_KEY
                ApiBase    = $env:AZURE_OPENAI_ENDPOINT
                TimeoutSec = 30
            }
            Set-OpenAIContext @AzureContext

            $script:TestResponse = Request-Response -Model 'gpt-4o-mini' -Message 'Hello' -Store $true -TimeoutSec 30 -ErrorAction Stop
            Start-Sleep -Seconds 5
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get response by object' {
            { $splat = @{
                    Response    = $script:TestResponse
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Get-Response @splat
            } | Should -Not -Throw
            $Result.id | Should -Be $script:TestResponse.id
            $Result.LastUserMessage | Should -BeExactly $script:TestResponse.LastUserMessage
            $Result.output_text | Should -BeExactly $script:TestResponse.output_text
            $Result.History | Should -HaveCount 2
        }

        It 'Get response by id' {
            { $splat = @{
                    ResponseId  = $script:TestResponse.id
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Get-Response @splat
            } | Should -Not -Throw
            $Result.id | Should -Be $script:TestResponse.id
            $Result.LastUserMessage | Should -BeExactly $script:TestResponse.LastUserMessage
            $Result.output_text | Should -BeExactly $script:TestResponse.output_text
            $Result.History | Should -HaveCount 2
        }
    }
}