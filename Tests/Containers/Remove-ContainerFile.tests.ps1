#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Container' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "container_abc123",
    "object": "container",
    "created_at": 1699061776
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/containers/container_abc123' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
"object": "list",
"data": [
    {
    "id": "container_abc123",
    "object": "container",
    "created_at": 1699061776,
    "name": "Container 1"
    },
    {
    "id": "container_abc456",
    "object": "container",
    "created_at": 1699061776,
    "name": "Container 2"
    }
],
"first_id": "container_abc123",
"last_id": "container_abc456",
"has_more": false
}
'@ } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/containers?limit=*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List container objects' {
            { $script:Result = Get-Container -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/containers?limit=*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeLike 'container_abc*'
            $Result[1].id | Should -BeLike 'container_abc*'
            $Result[0].created_at | Should -BeOfType [datetime]
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.Container'
        }

        It 'Get single container object' {
            { $script:Result = Get-Container -ContainerId 'container_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/containers/container_abc123' -eq $Uri }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'container_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Container'
        }

        It 'Invalid input' {
            $co = @{id = 'hoge_abc123'; object = 'invalid_object' }
            { $script:Result = $co | Get-Container -ea Stop } | Should -Throw
        }

        Context 'Parameter Sets' {
            It 'Get_Id' {
                # Named
                { Get-Container -ContainerId 'container_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Container 'container_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'container_abc123' | Get-Container -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{ContainerId = 'container_abc123' } | Get-Container -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/containers/container_abc123' -eq $Uri }
            }

            It 'Get_Container' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Container'
                    id         = 'container_abc123'
                }
                # Named
                { Get-Container -Container $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Container $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-Container -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/containers/container_abc123' -eq $Uri }
            }

            It 'List' {
                { Get-Container -ea Stop } | Should -Not -Throw
                { Get-Container -Limit 30 -ea Stop } | Should -Not -Throw
                { Get-Container -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/containers?limit=*' }
            }
        }
    }
}
