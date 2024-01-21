#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Receive-ThreadRun' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-ThreadRun {
                [pscustomobject]@{
                    'id'           = 'run_abc123'
                    'object'       = 'thread.run'
                    'created_at'   = [datetime]::Today
                    'assistant_id' = 'asst_abc123'
                    'thread_id'    = 'thread_abc123'
                    'status'       = 'completed'
                    'started_at'   = [datetime]::Today
                    'completed_at' = [datetime]::Today
                }
            }
            Mock -Verifiable -ModuleName $script:ModuleName Get-Thread {
                [pscustomobject]@{
                    'id'         = 'thread_abc123'
                    'object'     = 'thread'
                    'created_at' = [datetime]::Today
                }
            }
            Mock -Verifiable -ModuleName $script:ModuleName Remove-Thread {}
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Receive run result' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'completed'
                started_at = [datetime]::Today
            }
            { $script:Result = Receive-ThreadRun -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Remove-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result.id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread'
        }

        It 'Wait run completes then Receive run result' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Receive-ThreadRun -InputObject $InObject -Wait -ea Stop } | Should -Not -Throw
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Remove-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result.id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread'
        }

        It 'Wait run completes then Receive run result. Finally, Remove thread' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Receive-ThreadRun -InputObject $InObject -Wait -AutoRemoveThread -ea Stop } | Should -Not -Throw
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Remove-Thread -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread'
        }

        It '-AutoRemoveThread should use with -Wait' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Receive-ThreadRun -InputObject $InObject -AutoRemoveThread -ea Stop } | Should -Throw
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Remove-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Receive-ThreadRun -ea Stop } | Should -Throw
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Remove-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result | Should -BeNullOrEmpty
        }
    }
}
