#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-VectorStoreFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "file-abc123",
    "object": "vector_store.file",
    "created_at": 1699061776,
    "vector_store_id": "vs_abcd",
    "status": "completed",
    "last_error": null
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123/files/file-abc123' -eq $Uri }

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
'@
            } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores/vs_abc123/files`?*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List vector store file objects' {
            { $script:Result = Get-VectorStoreFile -VectorStoreId 'vs_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores/vs_abc123/files`?*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeLike 'file-abc*'
            $Result[1].id | Should -BeLike 'file-abc*'
            $Result[0].created_at | Should -BeOfType [datetime]
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore.File'
        }

        It 'Get single vector store object' {
            { $script:Result = Get-VectorStoreFile -VectorStoreId 'vs_abc123' -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123/files/file-abc123' -eq $Uri }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'file-abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore.File'
        }

        It 'Invalid input' {
            $vso = @{id = 'hoge_abc123'; object = 'invalid_object' }
            { $script:Result = $vso | Get-VectorStore -ea Stop } | Should -Throw
        }

        Context 'Parameter Sets' {
            It 'Get_Id' {
                # Named
                { Get-VectorStoreFile -VectorStoreId 'vs_abc123' -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-VectorStoreFile 'vs_abc123' 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Get-VectorStoreFile -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{VectorStoreId = 'vs_abc123'; FileId = 'file-abc123' } | Get-VectorStoreFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123/files/file-abc123' -eq $Uri }
            }

            It 'List_Id' {
                # Named
                { Get-VectorStoreFile -VectorStoreId 'vs_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-VectorStoreFile 'vs_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Get-VectorStoreFile -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{VectorStoreId = 'vs_abc123' } | Get-VectorStoreFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores/vs_abc123/files`?*' }
            }

            It 'Get_VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Get-VectorStoreFile -VectorStore $InObject -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-VectorStoreFile $InObject 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-VectorStoreFile -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123/files/file-abc123' -eq $Uri }
            }

            It 'List_VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Get-VectorStoreFile -VectorStore $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-VectorStoreFile $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-VectorStoreFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores/vs_abc123/files`?*' }
            }

            It 'Get_VectorStoreFile' {
                $InObject = [pscustomobject]@{
                    PSTypeName      = 'PSOpenAI.VectorStore.File'
                    id              = 'file-abc123'
                    vector_store_id = 'vs_abc123'
                }
                # Named
                { Get-VectorStoreFile -VectorStoreFile $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-VectorStoreFile $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-VectorStoreFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123/files/file-abc123' -eq $Uri }
            }
        }
    }
}
