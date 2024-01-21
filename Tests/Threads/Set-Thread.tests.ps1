#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-Thread' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName New-Thread {
                [pscustomobject]@{
                    id         = 'thread_abc123'
                    metadata   = @{}
                    created_at = [datetime]::Today
                    Messages   = @()
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Set thread with ID' {
            { $script:Result = Set-Thread -InputObject 'thread_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke New-Thread -ModuleName $script:ModuleName
            $script:Result.id | Should -Be 'thread_abc123'
        }

        It 'Remove thread with Thread object' {
            $InObject = [pscustomobject]@{
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $script:Result = Set-Thread -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke New-Thread -ModuleName $script:ModuleName
            $script:Result.id | Should -Be 'thread_abc123'
        }

        It 'Pipeline input with ID' {
            $InObject = 'thread_abc123'
            { $script:Result = $InObject | Set-Thread -ea Stop } | Should -Not -Throw
            Should -Invoke New-Thread -ModuleName $script:ModuleName
            $script:Result.id | Should -Be 'thread_abc123'
        }

        It 'Pipeline input with Object' {
            $InObject = [pscustomobject]@{
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $script:Result = $InObject | Set-Thread -ea Stop } | Should -Not -Throw
            Should -Invoke New-Thread -ModuleName $script:ModuleName
            $script:Result.id | Should -Be 'thread_abc123'
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Set-Thread -ea Stop } | Should -Throw
            Should -Invoke New-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
        }
    }
}
