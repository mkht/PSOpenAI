#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-TextCompletion' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIToken { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Text completion' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "cmpl-uqkvlQyYK7bGYrRHQ0eXlWi7",
    "object": "text_completion",
    "created": 1589478378,
    "model": "text-davinci-003",
    "choices": [
        {
        "text": "\n\nThis is indeed a test",
        "index": 0,
        "logprobs": null,
        "finish_reason": "length"
        }
    ],
    "usage": {
        "prompt_tokens": 5,
        "completion_tokens": 7,
        "total_tokens": 12
    }
}
'@ }
            { $script:Result = Request-TextCompletion `
                    -Prompt 'Say this is a test' `
                    -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -Be "`n`nThis is indeed a test"
            $Result.Prompt | Should -Be 'Say this is a test'
            $Result.created | Should -BeOfType [datetime]
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Text completion' {
            { $script:Result = Request-TextCompletion `
                    -Prompt 'Say this is a test' `
                    -MaxTokens 16 `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -Not -BeNullOrEmpty
            $Result.Prompt | Should -Be 'Say this is a test'
            $Result.created | Should -BeOfType [datetime]
        }

        It 'Text completion (multiple prompts)' {
            { $script:Result = Request-TextCompletion `
                    -Prompt ('test1', 'test2') `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result.Answer | Should -HaveCount 2
            $Result.Answer[0] | Should -Not -BeNullOrEmpty
            $Result.Answer[1] | Should -Not -BeNullOrEmpty
            $Result.Prompt | Should -Be ('test1', 'test2')
            $Result.created | Should -BeOfType [datetime]
        }
    }
}
