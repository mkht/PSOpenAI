#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-TextEdit' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIToken { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Edit text' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "object": "edit",
    "created": 1589478378,
    "choices": [
        {
        "text": "What day of the week is it?",
        "index": 0
        }
    ],
    "usage": {
        "prompt_tokens": 25,
        "completion_tokens": 32,
        "total_tokens": 57
    }
}
'@ }
            { $script:Result = Request-TextEdit `
                    -Instruction 'Fix the spelling mistakes' `
                    -Text 'What day of the wek is it?' `
                    -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -Be 'What day of the week is it?'
            $Result.Text | Should -Be 'What day of the wek is it?'
            $Result.Instruction | Should -Be 'Fix the spelling mistakes'
            $Result.created | Should -BeOfType [datetime]
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Edit text' {
            { $script:Result = Request-TextEdit `
                    -Instruction 'Fix the spelling mistakes' `
                    -Text 'What day of the wek is it?' `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -Not -BeNullOrEmpty
            $Result.Text | Should -Be 'What day of the wek is it?'
            $Result.Instruction | Should -Be 'Fix the spelling mistakes'
            $Result.created | Should -BeOfType [datetime]
        }
    }
}
