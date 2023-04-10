#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
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
    "id": "text-davinci-003",
    "object": "model",
    "created": 1669599635,
    "owned_by": "openai-internal",
    "permission": [
        {
        "id": "modelperm-6CAfTW5IbFpnlziQKoDilahq",
        "object": "model_permission",
        "created": 1677793558,
        "allow_create_engine": false,
        "allow_sampling": true,
        "allow_logprobs": true,
        "allow_search_indices": false,
        "allow_view": true,
        "allow_fine_tuning": false,
        "organization": "*",
        "group": null,
        "is_blocking": false
        }
    ],
    "root": "text-davinci-003",
    "parent": null
    }
'@ }

            $Models = Get-OpenAIModels -Name 'text-davinci-003'
            Should -InvokeVerifiable
            $Models.GetType().Name | Should -Be 'PSCustomObject'
            @($Models).Count | Should -Be 1
            $Models.id | Should -Be 'text-davinci-003'
            $Models.created | Should -BeOfType [datetime]
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

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
            { $script:Models = Get-OpenAIModels -Name 'text-davinci-003' -ErrorAction Stop } | Should -Not -Throw
            $Models.GetType().Name | Should -Be 'PSCustomObject'
            @($Models).Count | Should -Be 1
            $Models.id | Should -Be 'text-davinci-003'
            $Models.created | Should -BeOfType [datetime]
        }

        It '404 error not found' {
            { $script.Models = Get-OpenAIModels -Name 'non-exist-model' -ErrorAction Stop } | Should -Throw '*404*'
        }
    }
}
