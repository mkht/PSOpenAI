#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Wait-Batch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Wait batch completes' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Batch'
                    'id'       = 'batch_abc123'
                    'status'   = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Batch'
                id         = 'batch_abc123'
                status     = 'in_progress'
            }
            { $script:Result = Wait-Batch -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Get-Batch -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'batch_abc123'
            $Result.status | Should -Be 'completed'
        }

        It 'Wait batch completes (already completed)' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Batch'
                    'id'       = 'batch_abc123'
                    'status'   = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Batch'
                id         = 'batch_abc123'
                status     = 'completed'
            }
            { $script:Result = Wait-Batch -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Get-Batch -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'batch_abc123'
            $Result.status | Should -Be 'completed'
        }

        It 'Custom wait status' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Batch'
                    'id'       = 'batch_abc123'
                    'status'   = 'cancelling'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Batch'
                id         = 'batch_abc123'
                status     = 'in_progress'
            }
            { $script:Result = Wait-Batch -InputObject $InObject -StatusForWait ('cancelling', 'failed') -TimeoutSec 2 -ea Stop } | Should -Throw -ExceptionType ([System.OperationCanceledException])
            Should -Invoke Get-Batch -ModuleName $script:ModuleName -Times 1
        }

        It 'Custom exit status' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Batch'
                    'id'       = 'batch_abc123'
                    'status'   = 'in_progress'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Batch'
                id         = 'batch_abc123'
                status     = 'validating'
            }
            { $script:Result = Wait-Batch -InputObject $InObject -StatusForExit ('completed', 'in_progress') -ea Stop } | Should -Not -Throw
            Should -Invoke Get-Batch -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Error on timeout' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                Start-Sleep -Seconds 0.1
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Batch'
                    'id'       = 'batch_abc123'
                    'status'   = 'in_progress'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Batch'
                id         = 'batch_abc123'
                status     = 'in_progress'
            }
            { $script:Result = Wait-Batch -InputObject $InObject -TimeoutSec 2 -ea Stop } | Should -Throw -ExceptionType ([OperationCanceledException])
            Should -Invoke Get-Batch -ModuleName $script:ModuleName -Times 3
            $Result | Should -BeNullOrEmpty
        }

        It 'Custom polling intervals' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                Start-Sleep -Seconds 0.1
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Batch'
                    'id'       = 'batch_abc123'
                    'status'   = 'in_progress'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Batch'
                id         = 'batch_abc123'
                status     = 'in_progress'
            }
            { $script:Result = Wait-Batch -InputObject $InObject -TimeoutSec 2 -PollIntervalSec 100 -ea Stop } | Should -Throw -ExceptionType ([OperationCanceledException])
            Should -Invoke Get-Batch -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            BeforeAll {
                Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                    [pscustomobject]@{
                        PSTypeName = 'PSOpenAI.Batch'
                        id         = 'batch_abc123'
                        status     = 'completed'
                    }
                }
            }

            It 'Batch' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Batch'
                    id         = 'batch_abc123'
                    status     = 'in_progress'
                }
                # Named
                { Wait-Batch -Batch $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Wait-Batch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Wait-Batch -ea Stop } | Should -Not -Throw
                Should -Invoke Get-Batch -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Wait-Batch -BatchId 'batch_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Wait-Batch 'batch_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'batch_abc123' | Wait-Batch -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{batch_id = 'batch_abc123' } | Wait-Batch -ea Stop } | Should -Not -Throw
                Should -Invoke Get-Batch -ModuleName $script:ModuleName -Times 4 -Exactly
            }
        }
    }
}
