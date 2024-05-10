#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Assistant' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
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
'@ } -ParameterFilter { 'https://api.openai.com/v1/assistants/asst_abc123' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "object": "list",
    "data": [
      {
        "id": "asst_abc123",
        "object": "assistant",
        "created_at": 1698982736,
        "name": "Coding Tutor",
        "description": null,
        "model": "gpt-4-turbo",
        "instructions": "You are a helpful assistant designed to make me better at coding!",
        "tools": [],
        "tool_resources": {},
        "metadata": {},
        "top_p": 1.0,
        "temperature": 1.0,
        "response_format": "auto"
      },
      {
        "id": "asst_abc456",
        "object": "assistant",
        "created_at": 1698982718,
        "name": "My Assistant",
        "description": null,
        "model": "gpt-4-turbo",
        "instructions": "You are a helpful assistant designed to make me better at coding!",
        "tools": [],
        "tool_resources": {},
        "metadata": {},
        "top_p": 1.0,
        "temperature": 1.0,
        "response_format": "auto"
      },
      {
        "id": "asst_abc789",
        "object": "assistant",
        "created_at": 1698982643,
        "name": null,
        "description": null,
        "model": "gpt-4-turbo",
        "instructions": null,
        "tools": [],
        "tool_resources": {},
        "metadata": {},
        "top_p": 1.0,
        "temperature": 1.0,
        "response_format": "auto"
      }
    ],
    "first_id": "asst_abc123",
    "last_id": "asst_abc789",
    "has_more": false
  }
'@ } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/assistants`?*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get a single object with assistant ID' {
            { $script:Result = Get-Assistant -AssistantId 'asst_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly `
                -ParameterFilter { 'https://api.openai.com/v1/assistants/asst_abc123' -eq $Uri }
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Assistant'
            $Result.id | Should -BeExactly 'asst_abc123'
            $Result.object | Should -BeExactly 'assistant'
            $Result.created_at | Should -BeOfType [datetime]
        }

        It 'List assistants' {
            { $script:Result = Get-Assistant -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly `
                -ParameterFilter { $Uri -like 'https://api.openai.com/v1/assistants`?*' }
            $Result | Should -HaveCount 3
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.Assistant'
            $Result[0].id | Should -BeExactly 'asst_abc123'
            $Result[0].created_at | Should -BeOfType [datetime]
        }

        Context 'Parameter Sets' {
            It 'Get_Id' {
                # Named
                { Get-Assistant -AssistantId 'asst_abc123'-ea Stop } | Should -Not -Throw
                # Positional
                { Get-Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'asst_abc123' | Get-Assistant -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{assistant_id = 'asst_abc123' } | Get-Assistant -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/assistants/asst_abc123' -eq $Uri }
            }

            It 'Get_Assistant' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Assistant'
                    id         = 'asst_abc123'
                }
                # Named
                { Get-Assistant -Assistant $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Assistant $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-Assistant -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/assistants/asst_abc123' -eq $Uri }
            }

            It 'List' {
                { Get-Assistant -ea Stop } | Should -Not -Throw
                { Get-Assistant -Limit 30 -ea Stop } | Should -Not -Throw
                { Get-Assistant -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/assistants`?*' }
            }
        }
    }
}
