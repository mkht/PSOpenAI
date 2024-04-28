#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-VectorStore' {
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

        It 'Modify vector store (id)' {
            $vsid = 'vs_abc123'
            { $script:Result = Set-VectorStore -vector_store_id $vsid -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'vs_123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'completed'
        }

        It 'Modify vector store (object)' {
            $vso = @{id = 'vs_abc123'; object = 'vector_store' }
            { $script:Result = Set-VectorStore -InputObject $vso -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Modify vector store (object, pipeline)' {
            $vso = @{id = 'vs_abc123'; object = 'vector_store' }
            { $script:Result = $vso | Set-VectorStore -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Modify vector store (full param)' {
            $Params = @{
                InputObject      = 'vs_abc123'
                Name             = 'My New Store'
                ExpiresAfterDays = 10
                MetaData         = @{ meta_id = 'id-0001' }
            }
            { $script:Result = Set-VectorStore @Params -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Invalid input' {
            $vso = @{id = 'hoge_abc123'; object = 'invalid_object' }
            { $script:Result = Set-VectorStore -InputObject $vso -ea Stop } | Should -Throw
            Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }
    }
}
