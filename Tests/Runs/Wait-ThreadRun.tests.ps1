#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Wait-ThreadRun' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Wait run completes' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                id        = 'run_abc123'
                thread_id = 'thread_abc123'
                status    = 'in_progress'
            }
            { $script:Result = Wait-ThreadRun -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 2 -Exactly
            $Result.id | Should -Be 'run_abc123'
            $Result.thread_id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread.run'
            $Result.status | Should -Be 'completed'
        }

        It 'Wait run completes (already completed)' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                id        = 'run_abc123'
                thread_id = 'thread_abc123'
                status    = 'completed'
            }
            { $script:Result = Wait-ThreadRun -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Custom wait status' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                id        = 'run_abc123'
                thread_id = 'thread_abc123'
                status    = 'cancelling'
            }
            { $script:Result = Wait-ThreadRun -InputObject $InObject -StatusForWait ('cancelling', 'requires_action') -ea Stop } | Should -Not -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 2 -Exactly
        }

        It 'Custom exit status' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                id        = 'run_abc123'
                thread_id = 'thread_abc123'
                status    = 'in_progress'
            }
            { $script:Result = Wait-ThreadRun -InputObject $InObject -StatusForExit ('completed', 'in_progress') -ea Stop } | Should -Not -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Error on timeout' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                Start-Sleep -Seconds 0.1
                [pscustomobject]@{
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'in_progress'
                }
            }
            $InObject = [PSCustomObject]@{
                id        = 'run_abc123'
                thread_id = 'thread_abc123'
                status    = 'in_progress'
            }
            { $script:Result = Wait-ThreadRun -InputObject $InObject -TimeoutSec 2 -ea Stop } | Should -Throw '*canceled*'
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 3 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'Error on invalid input' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [datetime]::Today
            { $InObject | Wait-ThreadRun -ea Stop } | Should -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 0
        }
    }
}
