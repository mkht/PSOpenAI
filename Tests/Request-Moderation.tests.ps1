#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $ProgressPreference = 'SilentlyContinue'
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    $script:TestImageData = [string](Resolve-Path (Join-Path $PSScriptRoot '../Docs/images'))
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-Moderation' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIToken { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Text moderation' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { gc ($script:TestData + '/moderation_flagged_true.json') -raw }
            { $script:Result = Request-Moderation -Text 'I want to kill them.' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [PSCustomObject]
            $Result.id | Should -Not -BeNullOrEmpty
            $Result.results.GetType().Name | Should -Be 'Object[]'
            $Result.results[0].flagged | Should -BeTrue
            $Result.results[0].Text | Should -Be 'I want to kill them.'
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Text moderation' {
            { $script:Result = Request-Moderation `
                    -Text 'I want to kill them.' `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [PSCustomObject]
            $Result.id | Should -Not -BeNullOrEmpty
            $Result.results.GetType().Name | Should -Be 'Object[]'
            $Result.results[0].flagged | Should -BeTrue
            $Result.results[0].Text | Should -Be 'I want to kill them.'
        }

        It 'Text moderation (multiple texts)' {
            { $script:Result = Request-Moderation `
                    -Text ('I want to kill them.', 'I want to eat cake.') `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [PSCustomObject]
            $Result.id | Should -Not -BeNullOrEmpty
            $Result.results.GetType().Name | Should -Be 'Object[]'
            $Result.results | Should -HaveCount 2
            $Result.results[0].flagged | Should -BeTrue
            $Result.results[0].Text | Should -Be 'I want to kill them.'
            $Result.results[1].flagged | Should -BeFalse
            $Result.results[1].Text | Should -Be 'I want to eat cake.'
        }
    }
}
