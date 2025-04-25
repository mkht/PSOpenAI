#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-Response' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abc123",
  "object": "response",
  "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove response with ID' {
            { $script:Result = Remove-Response -ResponseId 'resp_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'Response' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Response'
                    id         = 'resp_abc123'
                }
                # Named
                { Remove-Response -Response $InObject -ea Stop } | Should -Not -Throw
                # Alias
                { Remove-Response -InputObject $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Response $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-Response -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'Id' {
                # Named
                { Remove-Response -ResponseId 'resp_abc123' -ea Stop } | Should -Not -Throw
                # Alias
                { Remove-Response -Id 'resp_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Response 'resp_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'resp_abc123' | Remove-Response -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{id = 'resp_abc123' } | Remove-Response -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 5 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            $script:Result = ''
            $script:TestResponse = Request-Response -Model 'gpt-4.1-nano' -Message 'Hello' -Store $true -TimeoutSec 30 -ErrorAction Stop
            Start-Sleep -Seconds 5
        }

        It 'Remove response' {
            { $splat = @{
                    Response    = $script:TestResponse
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Remove-Response @splat
            } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
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
            $script:Result = ''
            $script:TestResponse = Request-Response -Model 'gpt-4o-mini' -Message 'Hello' -Store $true -TimeoutSec 30 -ErrorAction Stop
            Start-Sleep -Seconds 5
        }

        It 'Remove response' {
            { $splat = @{
                    Response    = $script:TestResponse
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Remove-Response @splat
            } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
        }
    }
}
