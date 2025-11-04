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
        }

        Context 'Files parameter variations' {
            BeforeAll {
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { ConvertTo-Json -InputObject $PesterBoundParameters -Depth 10 }
            }

            It 'Files parameter - file IDs as strings' {
                $Files = @('file-abc123', 'file-abc456')
                { $script:Result = Start-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -Files $Files -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result.Body.file_ids | Should -Be $Files
                $Result.Body.files | Should -BeNullOrEmpty
            }

            It 'Files parameter - PSOpenAI.File objects' {
                $Files = @(
                    [pscustomobject]@{
                        PSTypeName = 'PSOpenAI.File'
                        id         = 'file-abc123'
                    },
                    [pscustomobject]@{
                        PSTypeName = 'PSOpenAI.File'
                        id         = 'file-abc456'
                    }
                )
                { $script:Result = Start-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -Files $Files -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result.Body.file_ids | Should -Be @('file-abc123', 'file-abc456')
                $Result.Body.files | Should -BeNullOrEmpty
            }

            It 'Files parameter - hash objects with file_id' {
                $Files = @(
                    @{file_id = 'file-abc456' },
                    @{file_id = 'file-abc123'; attributes = @{ key1 = 'value1' } },
                    @{file_id = 'file-abc789'; attributes = @{ key2 = 'value2' }; chunking_strategy = @{ type = 'static'; max_chunk_size_tokens = 1200; chunk_overlap_tokens = 200 } }
                )
                { $script:Result = Start-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -Files $Files -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result.Body.file_ids | Should -BeNullOrEmpty
                $Result.Body.files | Should -HaveCount 3
            }

            It 'Files parameter - mixed types' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                $Files = @(
                    'file-abc456',
                    $InObject,
                    @{file_id = 'file-abc789'; attributes = @{ key1 = 'value1' } }
                )
                { $script:Result = Start-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -Files $Files -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result.Body.file_ids | Should -BeNullOrEmpty
                $Result.Body.files | Should -HaveCount 3
            }
        }
    }
}
