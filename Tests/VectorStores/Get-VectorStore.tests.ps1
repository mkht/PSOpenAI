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
            } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores?limit=*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List vector store objects' {
            { $script:Result = Get-VectorStore -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/vector_stores?limit=*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeLike 'vs_abc*'
            $Result[1].id | Should -BeLike 'vs_abc*'
            $Result[0].created_at | Should -BeOfType [datetime]
        }

        It 'Get single vector store object' {
            { $script:Result = Get-VectorStore 'vs_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123' -eq $Uri }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'vs_abc123'
            $Result.created_at | Should -BeOfType [datetime]
        }

        It 'Get single vector store object (pipeline input)' {
            $vso = @{id = 'vs_abc123'; object = 'vector_store' }
            { $script:Result = $vso | Get-VectorStore -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/vector_stores/vs_abc123' -eq $Uri }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'vs_abc123'
            $Result.created_at | Should -BeOfType [datetime]
        }

        It 'Invalid input' {
            $vso = @{id = 'hoge_abc123'; object = 'invalid_object' }
            { $script:Result = $vso | Get-VectorStore -ea Stop } | Should -Throw
        }
    }
}
