#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-Assistant' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName New-Assistant {
                [pscustomobject]@{
                    id         = 'asst_abc123'
                    object     = 'assistant'
                    created_at = [datetime]::Today
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Set assistant with ID' {
            { $script:Result = Set-Assistant -InputObject 'asst_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke New-Assistant -ModuleName $script:ModuleName
            $script:Result.id | Should -Be 'asst_abc123'
        }

        It 'Remove thread with Thread object' {
            $InObject = [pscustomobject]@{
                id         = 'asst_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $script:Result = Set-Assistant -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke New-Assistant -ModuleName $script:ModuleName
            $script:Result.id | Should -Be 'asst_abc123'
        }

        It 'Pipeline input with ID' {
            $InObject = 'asst_abc123'
            { $script:Result = $InObject | Set-Assistant -ea Stop } | Should -Not -Throw
            Should -Invoke New-Assistant -ModuleName $script:ModuleName
            $script:Result.id | Should -Be 'asst_abc123'
        }

        It 'Pipeline input with Object' {
            $InObject = [pscustomobject]@{
                id         = 'asst_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $script:Result = $InObject | Set-Assistant -ea Stop } | Should -Not -Throw
            Should -Invoke New-Assistant -ModuleName $script:ModuleName
            $script:Result.id | Should -Be 'asst_abc123'
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Set-Assistant -ea Stop } | Should -Throw
            Should -Invoke New-Assistant -ModuleName $script:ModuleName -Times 0 -Exactly
        }
    }
}
