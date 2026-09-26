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
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } { $PesterBoundParameters }
        }

        It 'List all available AI models.' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } { gc ($script:TestData + '/models.json') -Raw }

            $Models = Get-OpenAIModels
            Should -InvokeVerifiable
            $Models.GetType().Name | Should -Be 'Object[]'
            $Models.Count | Should -BeGreaterThan 1
            $Models[0] | Should -BeOfType [pscustomobject]
            $Models[0].id | Should -Not -BeNullOrEmpty
            $Models[0].created | Should -BeOfType [datetime]
        }

        It 'Get a specific AI model.' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } { @'
{
    "id": "gpt-5",
    "object": "model",
    "created": 1692901427,
    "owned_by": "system"
}
'@ }

            $Models = Get-OpenAIModels -Name 'gpt-5'
            Should -InvokeVerifiable
            $Models.GetType().Name | Should -Be 'PSCustomObject'
            @($Models).Count | Should -Be 1
            $Models.id | Should -Be 'gpt-5'
            $Models.created | Should -BeOfType [datetime]
        }
    }

    Context 'Explicit null API key (offline)' -Tag 'Offline' {
        BeforeAll {
            $script:BackupEnvApiKey = $env:OPENAI_API_KEY
            $script:BackupGlobalApiKey = $global:OPENAI_API_KEY
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest { '{"data":[]}' }
        }

        AfterAll {
            $env:OPENAI_API_KEY = $script:BackupEnvApiKey
            $global:OPENAI_API_KEY = $script:BackupGlobalApiKey
            Clear-OpenAIContext
        }

        It 'passes an empty key to the request when ApiKey is explicitly null' {
            $env:OPENAI_API_KEY = 'ENV_KEY'
            $global:OPENAI_API_KEY = 'GLOBAL_KEY'
            Set-OpenAIContext -ApiKey 'CONTEXT_KEY'

            Get-OpenAIModels -ApiKey $null

            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { $ApiKey -is [securestring] -and $ApiKey.Length -eq 0 }
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


}
