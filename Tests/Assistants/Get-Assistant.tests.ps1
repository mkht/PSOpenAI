#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Assistant' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        Context 'Get Single Assistant' {
            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "asst_abc123",
    "object": "assistant",
    "created_at": 1698984975,
    "name": "Math Tutor",
    "description": null,
    "model": "gpt-4-turbo",
    "instructions": "You are a personal math tutor. When asked a question, write and run Python code to answer the question.",
    "tools": [
        {
        "type": "code_interpreter"
        }
    ],
    "metadata": {},
    "top_p": 1.0,
    "temperature": 1.0,
    "response_format": "auto"
}
'@ }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Get a single object with assistant ID' {
                { $script:Result = Get-Assistant -InputObject 'asst_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result.id | Should -BeExactly 'asst_abc123'
                $Result.object | Should -BeExactly 'assistant'
                $Result.created_at | Should -BeOfType [datetime]
            }

            It 'Pipeline input' {
                $InObject = [pscustomobject]@{
                    id     = 'asst_abc123'
                    object = 'assistant'
                }
                { $InObject | Get-Assistant -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            }
        }

        Context 'List Assistants' {
            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                    $msgobj = @'
{
    "id": "asst_abc123",
    "object": "assistant",
    "created_at": 1698984975,
    "name": "Math Tutor",
    "description": null,
    "model": "gpt-4-turbo",
    "instructions": "You are a personal math tutor. When asked a question, write and run Python code to answer the question.",
    "tools": [
        {
        "type": "code_interpreter"
        }
    ],
    "metadata": {},
    "top_p": 1.0,
    "temperature": 1.0,
    "response_format": "auto"
}
'@
                    $list = '{{"object": "list", "data": [{0}], "first_id": "asst_abc123", "last_id": "asst_abc456", "has_more": false }}'
                    $list -f ([string[]]$msgobj * 20 -join ',')
                }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'List assistants.' {
                { $script:Result = Get-Assistant -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 20
            }

            It 'Get all assistants.' {
                { $script:Result = Get-Assistant -All -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 20
            }

            It 'Error on invalid input' {
                $InObject = [datetime]::Today
                { $InObject | Get-Assistant -ea Stop } | Should -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
            }
        }
    }
}
