#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
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
                    PSTypeName  = 'PSOpenAI.Thread.Run'
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                status     = 'in_progress'
            }
            { $script:Result = Wait-ThreadRun -Run $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 2 -Exactly
            $Result.id | Should -Be 'run_abc123'
            $Result.thread_id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread.run'
            $Result.status | Should -Be 'completed'
        }

        It 'Wait run completes (already completed)' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Thread.Run'
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                status     = 'completed'
            }
            { $script:Result = Wait-ThreadRun -Run $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 2 -Exactly
        }

        It 'Custom wait status' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Thread.Run'
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                status     = 'cancelling'
            }
            { $script:Result = Wait-ThreadRun -Run $InObject -StatusForWait ('cancelling', 'requires_action') -ea Stop } | Should -Not -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 2 -Exactly
        }

        It 'Custom exit status' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Thread.Run'
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                status     = 'in_progress'
            }
            { $script:Result = Wait-ThreadRun -Run $InObject -StatusForExit ('completed', 'in_progress') -ea Stop } | Should -Not -Throw
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 2 -Exactly
        }

        It 'Error on timeout' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                Start-Sleep -Seconds 0.1
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Thread.Run'
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'in_progress'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                status     = 'in_progress'
            }
            { $script:Result = Wait-ThreadRun -InputObject $InObject -TimeoutSec 2 -ea Stop } | Should -Throw -ExceptionType ([System.TimeoutException])
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 3
            $Result | Should -BeNullOrEmpty
        }

        It 'Custom polling intervals' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                Start-Sleep -Seconds 0.1
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Thread.Run'
                    'id'        = 'run_abc123'
                    'object'    = 'thread.run'
                    'thread_id' = 'thread_abc123'
                    'status'    = 'in_progress'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                status     = 'in_progress'
            }
            { $script:Result = Wait-ThreadRun -InputObject $InObject -TimeoutSec 2 -PollIntervalSec 100 -ea Stop } | Should -Throw -ExceptionType ([System.TimeoutException])
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 1
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            BeforeAll {
                Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                    [pscustomobject]@{
                        PSTypeName  = 'PSOpenAI.Thread.Run'
                        'id'        = 'run_abc123'
                        'object'    = 'thread.run'
                        'thread_id' = 'thread_abc123'
                        'status'    = 'completed'
                    }
                }
            }

            It 'Run' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                    status     = 'in_progress'
                }
                # Named
                { Wait-ThreadRun -Run $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Wait-ThreadRun $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Wait-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 6 -Exactly
            }

            It 'Id' {
                # Named
                { Wait-ThreadRun -RunId 'run_abc123' -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Wait-ThreadRun 'run_abc123' 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'run_abc123' | Wait-ThreadRun -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123'; run_id = 'run_abc123' } | Wait-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 8 -Exactly
            }
        }
    }
}
