#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
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
            { $script:Result = Remove-VectorStore -InputObject 'vs_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Remove vector store with object' {
            $InObject = [pscustomobject]@{
                id     = 'vs_abc123'
                object = 'vectore_store'
            }
            { $script:Result = Remove-VectorStore -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Pipeline input with ID' {
            $InObject = 'vs_abc123'
            { $InObject | Remove-VectorStore -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Pipeline input with Object' {
            $InObject = [pscustomobject]@{
                id     = 'vs_abc123'
                object = 'vectore_store'
            }
            { $InObject | Remove-VectorStore -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Remove-VectorStore -ea Stop } | Should -Throw
            Should -Not -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }
    }
}
