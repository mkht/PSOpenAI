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
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
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

        It 'Output warning when the message violates the policy' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { gc ($script:TestData + '/moderation_flagged_true.json') -raw }
            { $script:Result = Request-Moderation -Text 'I want to kill them.' -WarningAction Stop } | Should -Throw
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Text moderation' {
            { $splat = @{
                    Text        = 'I want to kill them.'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-Moderation @splat
            } | Should -Not -Throw
            $Result | Should -BeOfType [PSCustomObject]
            $Result.id | Should -Not -BeNullOrEmpty
            $Result.results.GetType().Name | Should -Be 'Object[]'
            $Result.results[0].flagged | Should -BeTrue
            $Result.results[0].Text | Should -Be 'I want to kill them.'
        }

        It 'Text moderation (multiple texts)' {
            { $splat = @{
                    Text        = ('I want to kill them.', 'I want to eat cake.')
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-Moderation @splat
            } | Should -Not -Throw
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
