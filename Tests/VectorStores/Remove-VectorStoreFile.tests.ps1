#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-VectorStoreFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    id: "file-abc123",
    object: "vector_store.file.deleted",
    deleted: true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Delete a vector store file' {
            { $script:Result = Remove-VectorStoreFile -VectorStoreId 'vs_abc123' -file 'file-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'Invalid input' {
            $vso = @{id = 'hoge_abc123'; object = 'invalid_object' }
            { $script:Result = $vso | Remove-VectorStoreFile -ea Stop } | Should -Throw
        }

        Context 'Parameter Sets' {
            It 'Id' {
                # Named
                { Remove-VectorStoreFile -VectorStoreId 'vs_abc123' -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-VectorStoreFile 'vs_abc123' 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Remove-VectorStoreFile -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{VectorStoreId = 'vs_abc123'; FileId = 'file-abc123' } | Remove-VectorStoreFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Remove-VectorStoreFile -VectorStore $InObject -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-VectorStoreFile $InObject 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-VectorStoreFile -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'VectorStoreFile' {
                $InObject = [pscustomobject]@{
                    PSTypeName      = 'PSOpenAI.VectorStore.File'
                    id              = 'file-abc123'
                    vector_store_id = 'vs_abc123'
                }
                # Named
                { Remove-VectorStoreFile -VectorStoreFile $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-VectorStoreFile $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-VectorStoreFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
