#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Wait-VectorStoreFileBatch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Wait batch completes' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-VectorStoreFileBatch {
                [pscustomobject]@{
                    PSTypeName        = 'PSOpenAI.VectorStore.FileBatch'
                    'id'              = 'vsfb_abc123'
                    'vector_store_id' = 'vs_abc123'
                    'status'          = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'in_progress'
            }
            { $script:Result = Wait-VectorStoreFileBatch -Batch $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'vsfb_abc123'
            $Result.vector_store_id | Should -Be 'vs_abc123'
            $Result.status | Should -Be 'completed'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore.FileBatch'
        }

        It 'Wait batch completes (already completed)' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-VectorStoreFileBatch {
                [pscustomobject]@{
                    PSTypeName        = 'PSOpenAI.VectorStore.FileBatch'
                    'id'              = 'vsfb_abc123'
                    'vector_store_id' = 'vs_abc123'
                    'status'          = 'completed'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'completed'
            }
            { $script:Result = Wait-VectorStoreFileBatch -Batch $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Custom wait status' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-VectorStoreFileBatch {
                [pscustomobject]@{
                    PSTypeName        = 'PSOpenAI.VectorStore.FileBatch'
                    'id'              = 'vsfb_abc123'
                    'vector_store_id' = 'vs_abc123'
                    'status'          = 'cancelled'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'cancelling'
            }
            { $script:Result = Wait-VectorStoreFileBatch -Batch $InObject -StatusForWait ('cancelling', 'in_progress') -ea Stop } | Should -Not -Throw
            Should -Invoke Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Custom exit status' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-VectorStoreFileBatch {
                [pscustomobject]@{
                    PSTypeName        = 'PSOpenAI.VectorStore.FileBatch'
                    'id'              = 'vsfb_abc123'
                    'vector_store_id' = 'vs_abc123'
                    'status'          = 'cancelled'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'cancelling'
            }
            { $script:Result = Wait-VectorStoreFileBatch -Batch $InObject -StatusForExit ('completed', 'cancelled', 'failed') -ea Stop } | Should -Not -Throw
            Should -Invoke Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Error on timeout' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-VectorStoreFileBatch {
                Start-Sleep -Seconds 0.2
                [pscustomobject]@{
                    PSTypeName        = 'PSOpenAI.VectorStore.FileBatch'
                    'id'              = 'vsfb_abc123'
                    'vector_store_id' = 'vs_abc123'
                    'status'          = 'in_progress'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'in_progress'
            }
            { $script:Result = Wait-VectorStoreFileBatch -Batch $InObject -TimeoutSec 2 -ea Stop } | Should -Throw -ExceptionType ([OperationCanceledException])
            Should -Invoke Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 3
            $Result | Should -BeNullOrEmpty
        }

        It 'Custom polling intervals' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-VectorStoreFileBatch {
                Start-Sleep -Seconds 0.2
                [pscustomobject]@{
                    PSTypeName        = 'PSOpenAI.VectorStore.FileBatch'
                    'id'              = 'vsfb_abc123'
                    'vector_store_id' = 'vs_abc123'
                    'status'          = 'in_progress'
                }
            }
            $InObject = [PSCustomObject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'in_progress'
            }
            { $script:Result = Wait-VectorStoreFileBatch -Batch $InObject -TimeoutSec 2 -PollIntervalSec 100 -ea Stop } | Should -Throw -ExceptionType ([OperationCanceledException])
            Should -Invoke Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        Context 'Parameter Sets' {
            BeforeAll {
                Mock -Verifiable -ModuleName $script:ModuleName Get-VectorStoreFileBatch {
                    [pscustomobject]@{
                        PSTypeName        = 'PSOpenAI.VectorStore.FileBatch'
                        'id'              = 'vsfb_abc123'
                        'vector_store_id' = 'vs_abc123'
                        'status'          = 'completed'
                    }
                }
            }

            It 'VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Wait-VectorStoreFileBatch -VectorStore $InObject -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Wait-VectorStoreFileBatch $InObject 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Wait-VectorStoreFileBatch -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'VectorStoreId' {
                # Named
                { Wait-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Wait-VectorStoreFileBatch 'vs_abc123' 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Wait-VectorStoreFileBatch -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{vector_store_id = 'vs_abc123'; batch_id = 'vsfb_abc123' } | `
                            Wait-VectorStoreFileBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'VectorStoreFileBatch' {
                $InObject = [pscustomobject]@{
                    PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                    id              = 'vsfb_abc123'
                    vector_store_id = 'vs_abc123'
                }
                # Named
                { Wait-VectorStoreFileBatch -Batch $InObject -ea Stop } | Should -Not -Throw
                # Position
                { Wait-VectorStoreFileBatch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Wait-VectorStoreFileBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Get-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
