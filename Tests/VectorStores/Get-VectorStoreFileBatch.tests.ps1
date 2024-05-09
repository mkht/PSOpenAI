#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-VectorStoreFileBatch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "vsfb_abc123",
    "object": "vector_store.file_batch",
    "created_at": 1699061776,
    "vector_store_id": "vs_abc123",
    "status": "in_progress",
    "file_counts": {
        "in_progress": 1,
        "completed": 1,
        "failed": 0,
        "cancelled": 0,
        "total": 0
    }
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get vector store file batch' {
            { $script:Result = Get-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore.FileBatch'
            $Result.id | Should -BeExactly 'vsfb_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'in_progress'
        }

        Context 'Parameter Sets' {
            It 'VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Get-VectorStoreFileBatch -VectorStore $InObject -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Get-VectorStoreFileBatch $InObject 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-VectorStoreFileBatch -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'VectorStoreId' {
                # Named
                { Get-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Get-VectorStoreFileBatch 'vs_abc123' 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Get-VectorStoreFileBatch -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{vector_store_id = 'vs_abc123'; batch_id = 'vsfb_abc123' } | `
                            Get-VectorStoreFileBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'VectorStoreFileBatch' {
                $InObject = [pscustomobject]@{
                    PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                    id              = 'vsfb_abc123'
                    vector_store_id = 'vs_abc123'
                }
                # Named
                { Get-VectorStoreFileBatch -Batch $InObject -ea Stop } | Should -Not -Throw
                # Position
                { Get-VectorStoreFileBatch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-VectorStoreFileBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
