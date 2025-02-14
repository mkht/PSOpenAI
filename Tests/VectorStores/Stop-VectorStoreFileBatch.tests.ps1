#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Stop-VectorStoreFileBatch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-VectorStoreFileBatch {
                [pscustomobject]@{
                    PSTypeName        = 'PSOpenAI.VectorStore.FileBatch'
                    'id'              = 'vsfb_abc123'
                    'object'          = 'vector_store.file_batch'
                    'created_at'      = [datetime]::Today
                    'vector_store_id' = 'vs_abc123'
                    'status'          = 'cancelling'
                }
            }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "vsfb_abc123",
    "object": "vector_store.file_batch",
    "created_at": 1699061776,
    "vector_store_id": "vs_abc123",
    "status": "cancelling",
    "file_counts": {
        "in_progress": 12,
        "completed": 3,
        "failed": 0,
        "cancelled": 0,
        "total": 15
    }
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Cancel batch' {
            $InObject = [pscustomobject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'in_progress'
            }
            { $script:Result = Stop-VectorStoreFileBatch -Batch $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Wait-VectorStoreFileBatch -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
        }

        It 'Cancel batch (PassThru)' {
            $InObject = [pscustomobject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'in_progress'
            }
            { $script:Result = Stop-VectorStoreFileBatch -Batch $InObject -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Wait-VectorStoreFileBatch -ModuleName $script:ModuleName
            $Result.id | Should -Be 'vsfb_abc123'
            $Result.vector_store_id | Should -Be 'vs_abc123'
            $Result.status | Should -Be 'cancelling'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore.FileBatch'
        }

        It 'Cancel batch and wait cancelled' {
            $InObject = [pscustomobject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'in_progress'
            }
            { $script:Result = Stop-VectorStoreFileBatch -Batch $InObject -Wait -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'Cancel batch and wait cancelled (PassThru)' {
            $InObject = [pscustomobject]@{
                PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                id              = 'vsfb_abc123'
                vector_store_id = 'vs_abc123'
                status          = 'in_progress'
            }
            { $script:Result = Stop-VectorStoreFileBatch --Batch $InObject -Wait -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'vsfb_abc123'
            $Result.vector_store_id | Should -Be 'vs_abc123'
            $Result.status | Should -Be 'cancelling'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore.FileBatch'
        }

        It 'Error when the run status is not valid' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'completed'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-VectorStoreFileBatch -InputObject $InObject -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Wait-VectorStoreFileBatch -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Stop-VectorStoreFileBatch -VectorStore $InObject -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Stop-VectorStoreFileBatch $InObject 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Stop-VectorStoreFileBatch -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'VectorStoreId' {
                # Named
                { Stop-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Stop-VectorStoreFileBatch 'vs_abc123' 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Stop-VectorStoreFileBatch -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{vector_store_id = 'vs_abc123'; batch_id = 'vsfb_abc123' } | `
                            Stop-VectorStoreFileBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'VectorStoreFileBatch' {
                $InObject = [pscustomobject]@{
                    PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                    id              = 'vsfb_abc123'
                    vector_store_id = 'vs_abc123'
                }
                # Named
                { Stop-VectorStoreFileBatch -Batch $InObject -ea Stop } | Should -Not -Throw
                # Position
                { Stop-VectorStoreFileBatch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Stop-VectorStoreFileBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }

}
