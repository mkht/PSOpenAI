#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-Assistant' {
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
    "model": "gpt-4",
    "instructions": "You are a personal math tutor. When asked a question, write and run Python code to answer the question.",
    "tools": [{"type": "code_interpreter"}],
    "file_ids": [],
    "metadata": {}
    }
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Create assistant' {
            { $script:Result = New-Assistant -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result.id | Should -BeExactly 'asst_abc123'
            $Result.object | Should -BeExactly 'assistant'
            $Result.created_at | Should -BeOfType [datetime]
        }

        It 'Create assistant (full param)' {
            { $script:Result = New-Assistant `
                    -Name 'TEST' `
                    -Model gpt-4 `
                    -Description 'Test assistant' `
                    -Instructions 'Do it' `
                    -UseCodeInterpreter `
                    -UseRetrieval `
                    -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result.id | Should -BeExactly 'asst_abc123'
            $Result.object | Should -BeExactly 'assistant'
            $Result.created_at | Should -BeOfType [datetime]
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Result | Remove-Assistant -ea SilentlyContinue
        }

        It 'Create assistant (full param)' {
            $RandomName = ('TEST' + (Get-Random -Maximum 1000))
            { $script:Result = New-Assistant `
                    -Name $RandomName `
                    -Model gpt-3.5-turbo-0125 `
                    -Description 'Test assistant' `
                    -Instructions 'Do it' `
                    -UseCodeInterpreter `
                    -UseRetrieval `
                    -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'asst_*'
            $Result.object | Should -BeExactly 'assistant'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.name | Should -Be $RandomName
            $Result.description | Should -Be 'Test assistant'
            $Result.model | Should -Be 'gpt-3.5-turbo-0125'
            $Result.instructions | Should -Be 'Do it'
            $Result.tools | Should -HaveCount 2
        }
    }
}
