#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-VectorStore' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "vs_abc123",
    "object": "vector_store.deleted",
    "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove vector store with ID' {
            { $script:Result = Remove-VectorStore -VectorStoreId 'vs_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'Id' {
                # Named
                { Remove-VectorStore -VectorStoreId 'vs_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-VectorStore 'vs_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Remove-VectorStore -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{vector_store_id = 'vs_abc123' } | Remove-VectorStore -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Remove-VectorStore -VectorStore $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-VectorStore $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-VectorStore -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
