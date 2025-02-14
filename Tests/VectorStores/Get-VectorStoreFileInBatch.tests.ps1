#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-VectorStoreFileInBatch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "object": "list",
    "data": [
        {
        "id": "file-abc123",
        "object": "vector_store.file",
        "created_at": 1699061776,
        "vector_store_id": "vs_abc123"
        },
        {
        "id": "file-abc456",
        "object": "vector_store.file",
        "created_at": 1699061776,
        "vector_store_id": "vs_abc123"
        }
    ],
    "first_id": "file-abc123",
    "last_id": "file-abc456",
    "has_more": false
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get vector store files in batch' {
            { $script:Result = Get-VectorStoreFileInBatch -VectorStoreId 'vs_abc123' -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -HaveCount 2
            $Result[0] | Should -BeOfType [pscustomobject]
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore.File'
            $Result[0].id | Should -BeLike 'file-*'
        }

        Context 'Parameter Sets' {
            It 'List_VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Get-VectorStoreFileInBatch -VectorStore $InObject -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Get-VectorStoreFileInBatch $InObject 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-VectorStoreFileInBatch -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'List_Id' {
                # Named
                { Get-VectorStoreFileInBatch -VectorStoreId 'vs_abc123' -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Get-VectorStoreFileInBatch 'vs_abc123' 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Get-VectorStoreFileInBatch -BatchId 'vsfb_abc123' -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{vector_store_id = 'vs_abc123'; batch_id = 'vsfb_abc123' } | `
                            Get-VectorStoreFileInBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'List_VectorStoreFileBatch' {
                $InObject = [pscustomobject]@{
                    PSTypeName      = 'PSOpenAI.VectorStore.FileBatch'
                    id              = 'vsfb_abc123'
                    vector_store_id = 'vs_abc123'
                }
                # Named
                { Get-VectorStoreFileInBatch -Batch $InObject -ea Stop } | Should -Not -Throw
                # Position
                { Get-VectorStoreFileInBatch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-VectorStoreFileInBatch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
