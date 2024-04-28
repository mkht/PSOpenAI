#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Add-VectorStoreFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "file-abc123",
    "object": "vector_store.file",
    "created_at": 1699061776,
    "usage_bytes": 1234,
    "vector_store_id": "vs_abcd",
    "status": "completed",
    "last_error": null
}
'@ }
            Mock -Verifiable -ModuleName $script:ModuleName Get-VectorStore {
                [pscustomobject]@{
                    id     = 'vs_abc123'
                    object = 'vector_Store'
                    status = 'completed'
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Add file to vector store' {
            $vsid = 'vs_abcd'
            { $script:Result = Add-VectorStoreFile -VectorStore $vsid -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke -CommandName Get-VectorStore -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
        }

        It 'Add file to vector store (pipeline input)' {
            $vsid = 'vs_abcd'
            { $script:Result = $vsid | Add-VectorStoreFile -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke -CommandName Get-VectorStore -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
        }

        It 'Add file to vector store (PassThru)' {
            $vsid = 'vs_abcd'
            { $script:Result = Add-VectorStoreFile -VectorStore $vsid -FileId 'file-abc123' -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke -CommandName Get-VectorStore -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -Be 'vs_abc123'
        }

        It 'Invalid input' {
            $vsid = [datetime]::Today
            { $script:Result = Add-VectorStoreFile -VectorStore $vsid -FileId 'file-abc123' -ea Stop } | Should -Throw
            Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }
    }
}
