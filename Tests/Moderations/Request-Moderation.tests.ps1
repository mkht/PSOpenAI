#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $ProgressPreference = 'SilentlyContinue'
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    $script:TestImageData = Join-Path $script:ModuleRoot 'Docs/images'
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
            $Result.results[0].Input | Should -Be 'I want to kill them.'
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

        It 'Text moderation (single text)' {
            { $splat = @{
                    Text        = 'I want to kill them.'
                    Model       = 'omni-moderation-latest'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-Moderation @splat
            } | Should -Not -Throw
            $Result | Should -BeOfType [PSCustomObject]
            $Result.id | Should -Not -BeNullOrEmpty
            $Result.results.GetType().Name | Should -Be 'Object[]'
            $Result.results[0].flagged | Should -BeTrue
            $Result.results[0].Input | Should -Be 'I want to kill them.'
        }

        It 'Text moderation (multiple texts)' {
            { $splat = @{
                    Text        = ('I want to kill them.', 'I want to eat cake.')
                    Model       = 'omni-moderation-latest'
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
            $Result.results[0].Input | Should -Be 'I want to kill them.'
            $Result.results[1].flagged | Should -BeFalse
            $Result.results[1].Input | Should -Be 'I want to eat cake.'
        }

        It 'Image moderation (Image file)' {
            { $splat = @{
                    Images      = ($script:TestData + '/sweets_donut.png')
                    Model       = 'omni-moderation-latest'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-Moderation @splat
            } | Should -Not -Throw
            $Result | Should -BeOfType [PSCustomObject]
            $Result.id | Should -Not -BeNullOrEmpty
            $Result.results.GetType().Name | Should -Be 'Object[]'
            $Result.results[0].flagged | Should -BeFalse
            $Result.results[0].Input | Should -Not -BeNullOrEmpty
        }

        It 'Multi-modal moderation (Text & Image_url)' {
            { $splat = @{
                    Text        = 'I want to kill them.'
                    Images      = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Morakniv_Basic_511_Carbon_Steel_5.jpg/640px-Morakniv_Basic_511_Carbon_Steel_5.jpg'
                    Model       = 'omni-moderation-latest'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-Moderation @splat
            } | Should -Not -Throw
            $Result | Should -BeOfType [PSCustomObject]
            $Result.id | Should -Not -BeNullOrEmpty
            $Result.results.GetType().Name | Should -Be 'Object[]'
            $Result.results[0].flagged | Should -BeTrue
            $Result.results[0].Input | Should -Not -BeNullOrEmpty
        }
    }
}
