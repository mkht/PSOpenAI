#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-CodeCompletion' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
        }

        It 'Just call the Request-TextCompletion with "code-davinci-002" model' {
            Mock -Verifiable -ModuleName $script:ModuleName Request-TextCompletion { $PesterBoundParameters }
            $Result = Request-CodeCompletion -Prompt 'test'
            Should -InvokeVerifiable
            $Result.Model | Should -Be 'code-davinci-002'
            $Result.Prompt | Should -Be 'test'
        }

        It 'Codex models are discontinued.' {
            { Request-CodeCompletion `
                    -Prompt '# PowerShell' `
                    -MaxTokens 16 `
                    -WarningAction Stop `
                    -TimeoutSec 30 -ea Stop } | Should -Throw '*discontinued*'
        }
    }

    #### DEPRECATED ################
    # Context 'Integration tests (online)' -Tag 'Online' {

    #     BeforeEach {
    #         $script:Result = ''
    #     }

    #     It 'Code completion' {
    #         { $script:Result = Request-CodeCompletion `
    #                 -Prompt '# PowerShell' `
    #                 -Model 'code-cushman-001' `
    #                 -MaxTokens 16 `
    #                 -Echo $true `
    #                 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
    #         $Result | Should -BeOfType [pscustomobject]
    #         $Result.object | Should -Be 'text_completion'
    #         $Result.Answer | Should -HaveCount 1
    #         $Result.Answer[0] | Should -Match '^# PowerShell'
    #         $Result.Prompt | Should -Not -BeNullOrEmpty
    #         $Result.created | Should -BeOfType [datetime]
    #     }
    # }
}
