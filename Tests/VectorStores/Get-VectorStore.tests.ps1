#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-VectorStore' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "vs_abc123",
    "object": "vector_store",
    "created_at": 1699061776
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
"object": "list",
"data": [
    {
    "id": "vs_abc123",
    "object": "vector_store",
    "created_at": 1699061776,
    "name": "Support FAQ",
    "bytes": 139920,
    "file_counts": {}
    },
    {
    "id": "vs_abc456",
    "object": "vector_store",
    "created_at": 1699061776,
    "name": "Support FAQ v2",
    "bytes": 139920,
    "file_counts": {}
    }
],
"first_id": "vs_abc123",
"last_id": "vs_abc456",
"has_more": false
}
'@
            } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores`?limit=*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List vector store objects' {
            { $script:Result = Get-VectorStore -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores`?limit=*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeLike 'vs_abc*'
            $Result[1].id | Should -BeLike 'vs_abc*'
            $Result[0].created_at | Should -BeOfType [datetime]
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore'
        }

        It 'Get single vector store object' {
            { $script:Result = Get-VectorStore -VectorStoreId 'vs_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123' -eq $Uri }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'vs_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.VectorStore'
        }

        It 'Invalid input' {
            $vso = @{id = 'hoge_abc123'; object = 'invalid_object' }
            { $script:Result = $vso | Get-VectorStore -ea Stop } | Should -Throw
        }

        Context 'Parameter Sets' {
            It 'Get_Id' {
                # Named
                { Get-VectorStore -VectorStoreId 'vs_abc123'-ea Stop } | Should -Not -Throw
                # Positional
                { Get-VectorStore 'vs_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'vs_abc123' | Get-VectorStore -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{VectorStoreId = 'vs_abc123' } | Get-VectorStore -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123' -eq $Uri }
            }

            It 'Get_VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.VectorStore'
                    id         = 'vs_abc123'
                }
                # Named
                { Get-VectorStore -VectorStore $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-VectorStore $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-VectorStore -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123' -eq $Uri }
            }

            It 'List' {
                { Get-VectorStore -ea Stop } | Should -Not -Throw
                { Get-VectorStore -Limit 30 -ea Stop } | Should -Not -Throw
                { Get-VectorStore -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores`?limit=*' }
            }
        }
    }
}
