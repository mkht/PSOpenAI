#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-VectorStore' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "vs_abc123",
    "object": "vector_store",
    "created_at": 1698107661,
    "usage_bytes": 123456,
    "last_active_at": 1698107661,
    "name": "my_vector_store",
    "description": "This is my vector store.",
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
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore'
            $Result.id | Should -BeExactly 'vs_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'completed'
        }

        It 'Create vector store (full param)' {
            $Params = @{
                FileId           = 'file-abc123', 'file-abc456'
                Name             = 'My Store'
                Description      = 'This is my vector store.'
                ExpiresAfterDays = 7
                MetaData         = @{ meta_id = 'id-0000' }
            }
            { $script:Result = New-VectorStore @Params -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        Context 'Parameter Sets' {
            It 'None' {
                { New-VectorStore -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            }

            It 'FileId' {
                # Single
                { New-VectorStore -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Array
                { New-VectorStore -FileId 'file-abc123', 'file-abc456' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 2 -Exactly
            }

            It 'File' {
                $InObject1 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                $InObject2 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc456'
                }
                # Single
                { New-VectorStore -FileId $InObject1 -ea Stop } | Should -Not -Throw
                # Array
                { New-VectorStore -FileId $InObject1, $InObject2 -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 2 -Exactly
            }

            It 'Mix' {
                $InObject1 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                $InObject2 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc456'
                }
                { New-VectorStore -FileId 'file-abc123', $InObject1, 'file-abc456', $InObject2 -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            }
        }
    }
}
