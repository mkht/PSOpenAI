#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-OpenAIModels' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        It 'List all available AI models.' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { gc ($script:TestData + '/models.json') -Raw }

            $Models = Get-OpenAIModels
            Should -InvokeVerifiable
            $Models.GetType().Name | Should -Be 'Object[]'
            $Models.Count | Should -BeGreaterThan 1
            $Models[0] | Should -BeOfType [pscustomobject]
            $Models[0].id | Should -Not -BeNullOrEmpty
            $Models[0].created | Should -BeOfType [datetime]
        }

        It 'Get a specific AI model.' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "gpt-3.5-turbo-instruct",
    "object": "model",
    "created": 1692901427,
    "owned_by": "system"
}
'@ }

            $Models = Get-OpenAIModels -Name 'gpt-3.5-turbo-instruct'
            Should -InvokeVerifiable
            $Models.GetType().Name | Should -Be 'PSCustomObject'
            @($Models).Count | Should -Be 1
            $Models.id | Should -Be 'gpt-3.5-turbo-instruct'
            $Models.created | Should -BeOfType [datetime]
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            $script:Models = ''
        }

        It 'List all available AI models.' {
            { $script:Models = Get-OpenAIModels -ErrorAction Stop } | Should -Not -Throw
            $Models.GetType().Name | Should -Be 'Object[]'
            $Models.Count | Should -BeGreaterThan 1
            $Models[0] | Should -BeOfType [pscustomobject]
            $Models[0].id | Should -Not -BeNullOrEmpty
            $Models[0].created | Should -BeOfType [datetime]
        }

        It 'Get a specific AI model.' {
            { $script:Models = Get-OpenAIModels -Name 'gpt-4o-mini-2024-07-18' -ErrorAction Stop } | Should -Not -Throw
            $Models.GetType().Name | Should -Be 'PSCustomObject'
            @($Models).Count | Should -Be 1
            $Models.id | Should -Be 'gpt-4o-mini-2024-07-18'
            $Models.created | Should -BeOfType [datetime]
        }

        It '404 error not found' {
            { $script.Models = Get-OpenAIModels -Name 'non-exist-model' -ErrorAction Stop } | Should -Throw '*404*'
        }
    }

    Context 'Integration tests (Azure)' -Tag 'Azure' {
        BeforeAll {
            # Set Context for Azure OpenAI
            $AzureContext = @{
                ApiType    = 'Azure'
                AuthType   = 'Azure'
                ApiKey     = $env:AZURE_OPENAI_API_KEY
                ApiBase    = $env:AZURE_OPENAI_ENDPOINT
                TimeoutSec = 30
            }
            Set-OpenAIContext @AzureContext
        }

        BeforeEach {
            $script:Models = ''
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'List all available AI models.' {
            { $script:Models = Get-OpenAIModels -ErrorAction Stop } | Should -Not -Throw
            $Models.GetType().Name | Should -Be 'Object[]'
            $Models.Count | Should -BeGreaterThan 1
            $Models[0] | Should -BeOfType [pscustomobject]
            $Models[0].id | Should -Not -BeNullOrEmpty
        }

        It 'Get a specific AI model.' {
            { $script:Models = Get-OpenAIModels -Name 'gpt-4o-mini-2024-07-18' -ErrorAction Stop } | Should -Not -Throw
            $Models.GetType().Name | Should -Be 'PSCustomObject'
            @($Models).Count | Should -Be 1
            $Models.id | Should -Be 'gpt-4o-mini-2024-07-18'
        }

        It '404 error not found' {
            { $script.Models = Get-OpenAIModels -Name 'non-exist-model' -ErrorAction Stop } | Should -Throw '*404*'
        }
    }
}
