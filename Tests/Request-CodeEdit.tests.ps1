#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-CodeEdit' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
        }

        It 'Just call the Request-TextEdit with "code-davinci-edit-001" model' {
            Mock -Verifiable -ModuleName $script:ModuleName Request-TextEdit { $PesterBoundParameters }
            $Result = Request-CodeEdit -Instruction 'test'
            Should -InvokeVerifiable
            $Result.Model | Should -Be 'code-davinci-edit-001'
            $Result.Instruction | Should -Be 'test'
        }
    }

    #### DEPRECATED ################
    # Context 'Integration tests (online)' -Tag 'Online' {

    #     BeforeEach {
    #         $script:Result = ''
    #     }

    #     It 'Code Edit' {
    #         { $script:Result = Request-CodeEdit `
    #                 -Instruction 'Write a function in python that calculates fibonacci' `
    #                 -Temperature 0.1 `
    #                 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
    #         $Result | Should -BeOfType [pscustomobject]
    #         $Result.object | Should -Be 'edit'
    #         $Result.Answer | Should -HaveCount 1
    #         $Result.Instruction | Should -Be 'Write a function in python that calculates fibonacci'
    #         $Result.created | Should -BeOfType [datetime]
    #     }
    # }
}
