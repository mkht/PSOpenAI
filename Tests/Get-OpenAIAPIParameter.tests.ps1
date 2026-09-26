#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

$ModuleName = 'PSOpenAI'
$script:ModuleRoot = Split-Path $PSScriptRoot -Parent
$script:ModuleName = 'PSOpenAI'
Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force

    # backup current key
    $script:BackupGlobalApiKey = $global:OPENAI_API_KEY
    $script:BackupGlobalApiBase = $global:OPENAI_API_BASE
    $script:BackupEnvApiKey = $env:OPENAI_API_KEY
    $script:BackupEnvApiBase = $env:OPENAI_API_BASE
}

AfterAll {
    #Restore key
    $global:OPENAI_API_KEY = $script:BackupGlobalApiKey
    $global:OPENAI_API_BASE = $script:BackupGlobalApiBase
    $env:OPENAI_API_KEY = $script:BackupEnvApiKey
    $env:OPENAI_API_BASE = $script:BackupEnvApiBase
    $script:BackupGlobalApiKey = $script:BackupEnvApiKey = $script:BackupGlobalApiBase = $script:BackupEnvApiBase = $null
}

Describe 'Get-OpenAIAPIParameter' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        InModuleScope $ModuleName {
            BeforeAll {
                function Get-PlainTextFromSecureString ($securestring) {
                    $p = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
                    [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($p)
                    $securestring.Dispose()
                }

                Mock -Verifiable Get-OpenAIAPIEndpoint {
                    @{
                        Name        = 'chat.completion'
                        Method      = 'Post'
                        Uri         = 'https://api.openai.com/v1/chat/completions'
                        ContentType = 'application/json'
                    }
                }


            }

            BeforeEach {
                $global:OPENAI_API_KEY = $null
                $env:OPENAI_API_KEY = $null
                $global:OPENAI_API_BASE = $null
                $env:OPENAI_API_BASE = $null
                Clear-OpenAIContext
            }

            It 'No explicit param, No context, No environment -> Error' {
                $ExplicitParams = @{}
                { Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams -ea Stop } | Should -Throw
            }

            It 'No explicit param, No context, With environment' {
                $env:OPENAI_API_KEY = 'ENV_KEY'
                $ExplicitParams = @{}
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.Uri | Should -Be 'https://api.openai.com/v1/chat/completions'
                $ret.ApiBase | Should -BeNullOrEmpty        # default value
                $ret.MaxRetryCount | Should -Be 0           # default value
                Get-PlainTextFromSecureString $ret.ApiKey | Should -Be 'ENV_KEY'  # env value
                Should -Invoke Get-OpenAIAPIEndpoint -Times 1 -Exactly
            }

            It 'No explicit param, With Context, With environment' {
                $env:OPENAI_API_KEY = 'ENV_KEY'
                $env:OPENAI_API_BASE = 'ENV_BASE'
                $ExplicitParams = @{}
                $Context = @{
                    ApiKey        = 'CONTEXT_KEY'
                    MaxRetryCount = 15
                }
                Set-OpenAIContext @Context
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.Uri | Should -Be 'https://api.openai.com/v1/chat/completions'
                $ret.ApiBase | Should -Be 'ENV_BASE'        # env value
                $ret.MaxRetryCount | Should -Be 15          # context value
                Get-PlainTextFromSecureString $ret.ApiKey | Should -Be 'CONTEXT_KEY' # context value
                Should -Invoke Get-OpenAIAPIEndpoint -Times 1 -Exactly
            }

            It 'With explicit param, With Context, With environment' {
                $env:OPENAI_API_KEY = 'ENV_KEY'
                $env:OPENAI_API_BASE = 'ENV_BASE'
                $ExplicitParams = @{
                    ApiKey     = 'PARAM_KEY'
                    TimeoutSec = 50
                }
                $Context = @{
                    ApiKey        = 'CONTEXT_KEY'
                    MaxRetryCount = 15
                }
                Set-OpenAIContext @Context
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.Uri | Should -Be 'https://api.openai.com/v1/chat/completions'
                $ret.ApiBase | Should -Be 'ENV_BASE'    # env value
                $ret.MaxRetryCount | Should -Be 15      # context value
                $ret.TimeoutSec | Should -Be 50         # param value
                Get-PlainTextFromSecureString $ret.ApiKey | Should -Be 'PARAM_KEY' # param value
                Should -Invoke Get-OpenAIAPIEndpoint -Times 1 -Exactly
            }

            It 'Custom API base URL (OpenAI)' {
                $ExplicitParams = @{
                    ApiKey  = 'PARAM_KEY'
                    ApiBase = 'https://custombase.localhost.local/'
                }
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.ApiBase | Should -Be 'https://custombase.localhost.local/'
                Should -Invoke Get-OpenAIAPIEndpoint -Times 1 -Exactly
            }

            It 'Custom API base URL (nested path)' {
                $ExplicitParams = @{
                    ApiKey  = 'PARAM_KEY'
                    ApiBase = 'https://custombase.localhost.local/inference'
                }
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.ApiBase | Should -Be 'https://custombase.localhost.local/inference'
                Should -Invoke Get-OpenAIAPIEndpoint -Times 1 -Exactly
            }

            It 'Custom API base URL (IP address with port number)' {
                $ExplicitParams = @{
                    ApiKey  = 'PARAM_KEY'
                    ApiBase = 'http://127.0.0.1:8080/v1'
                }
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.ApiBase | Should -Be 'http://127.0.0.1:8080/v1'
                Should -Invoke Get-OpenAIAPIEndpoint -Times 1 -Exactly
            }
        }
    }
}
