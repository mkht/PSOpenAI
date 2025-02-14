#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Start-VectorStoreFileBatch' {
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

        It 'Start vector store file batch' {
            { $script:Result = Start-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
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
                { Start-VectorStoreFileBatch -VectorStore $InObject -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Start-VectorStoreFileBatch $InObject 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Start-VectorStoreFileBatch -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'VectorStoreId' {
                # Named
                { Start-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Start-VectorStoreFileBatch 'vs_abc123' 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Start-VectorStoreFileBatch -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{vector_store_id = 'vs_abc123'; file_ids = ('file-abc123', 'file-abc456') } | `
                            Start-VectorStoreFileBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'FileId' {
                $InObject1 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                $InObject2 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc456'
                }
                { New-VectorStore -VectorStoreId 'vs_abc123' -FileId 'file-abc123', $InObject1, 'file-abc456', $InObject2 -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            }
        }
    }
}
