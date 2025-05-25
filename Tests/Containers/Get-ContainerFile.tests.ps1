#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ContainerFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "file_abc123",
    "object": "container.file",
    "created_at": 1699061776,
    "container_id": "container_abc123"
}
'@ } -ParameterFilter { $Uri -eq 'https://api.openai.com/v1/containers/container_abc123/files/file_abc123' }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
"object": "list",
"data": [
    {
        "id": "file_abc123",
        "object": "container.file",
        "created_at": 1699061776,
        "container_id": "container_abc123"
    },
    {
        "id": "file_abc456",
        "object": "container.file",
        "created_at": 1699061777,
        "container_id": "container_abc123"
    }
],
"first_id": "file_abc123",
"last_id": "file_abc456",
"has_more": false
}
'@ } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/containers/container_abc123/files?limit=*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List container file objects' {
            { $script:Result = Get-ContainerFile -ContainerId 'container_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/containers/container_abc123/files?limit=*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeLike 'file_abc123'
            $Result[1].id | Should -BeLike 'file_abc456'
            $Result[1].psobject.TypeNames | Should -Contain 'PSOpenAI.Container.File'
        }

        It 'Get single container file object' {
            { $script:Result = Get-ContainerFile -ContainerId 'container_abc123' -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -eq 'https://api.openai.com/v1/containers/container_abc123/files/file_abc123' }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'file_abc123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Container.File'
        }

        Context 'Parameter Sets' {
            It 'Get_Id' {
                # Named
                { Get-ContainerFile -ContainerId 'container_abc123' -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ContainerFile 'container_abc123' 'file_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'container_abc123' | Get-ContainerFile -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{ContainerId = 'container_abc123' } | Get-ContainerFile -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { $Uri -eq 'https://api.openai.com/v1/containers/container_abc123/files/file_abc123' }
            }

            It 'List parameters' {
                { Get-ContainerFile -ContainerId 'container_abc123' -ea Stop } | Should -Not -Throw
                { Get-ContainerFile -ContainerId 'container_abc123' -Limit 30 -ea Stop } | Should -Not -Throw
                { Get-ContainerFile -ContainerId 'container_abc123' -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/containers/container_abc123/files?limit=*' }
            }
        }
    }
}
