#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-VectorStore' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "vs_123",
    "object": "vector_store",
    "created_at": 1698107661,
    "usage_bytes": 123456,
    "last_active_at": 1698107661,
    "name": "my_vector_store",
    "status": "completed",
    "file_counts": {
        "in_progress": 0,
        "completed": 100,
        "cancelled": 0,
        "failed": 0,
        "total": 100
    },
    "metadata": {},
    "last_used_at": 1698107661
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Create vector store' {
            { $script:Result = New-VectorStore -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'vs_123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'completed'
        }

        It 'Create vector store (full param)' {
            $Params = @{
                FileId           = 'file-abc123', 'file-abc456'
                Name             = 'My Store'
                ExpiresAfterDays = 7
                MetaData         = @{ meta_id = 'id-0000' }
            }
            { $script:Result = New-VectorStore @Params -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }
    }
}
