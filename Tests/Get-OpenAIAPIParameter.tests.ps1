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

                Mock -Verifiable Get-AzureOpenAIAPIEndpoint {
                    @{
                        Name        = 'chat.completion'
                        Method      = 'Post'
                        Uri         = 'https://test.openai.azure.com/openai/deployments/dummy/chat/completions'
                        ContentType = 'application/json'
                    }
                }
            }

            BeforeEach {
                $global:OPENAI_API_KEY = $null
                $env:OPENAI_API_KEY = $null
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
                $ret.ApiType | Should -Be 'OpenAI'          # default value
                $ret.AuthType | Should -Be 'openai'         # default value
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
                    ApiType       = 'Azure'
                    AuthType      = 'Azure'
                    MaxRetryCount = 15
                }
                Set-OpenAIContext @Context
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.Uri | Should -Be 'https://test.openai.azure.com/openai/deployments/dummy/chat/completions'
                $ret.ApiType | Should -Be 'Azure'           # context value
                $ret.AuthType | Should -Be 'azure'          # context value
                $ret.ApiBase | Should -Be 'ENV_BASE'        # env value
                $ret.MaxRetryCount | Should -Be 15          # context value
                Get-PlainTextFromSecureString $ret.ApiKey | Should -Be 'CONTEXT_KEY' # context value
                Should -Invoke Get-AzureOpenAIAPIEndpoint -Times 1 -Exactly
            }

            It 'With explicit param, With Context, With environment' {
                $env:OPENAI_API_KEY = 'ENV_KEY'
                $env:OPENAI_API_BASE = 'ENV_BASE'
                $ExplicitParams = @{
                    ApiKey     = 'PARAM_KEY'
                    ApiType    = 'Azure'
                    AuthType   = 'Azure'
                    TimeoutSec = 50
                }
                $Context = @{
                    ApiKey        = 'CONTEXT_KEY'
                    ApiType       = 'OpenAI'
                    AuthType      = 'openai'
                    MaxRetryCount = 15
                }
                Set-OpenAIContext @Context
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.Uri | Should -Be 'https://test.openai.azure.com/openai/deployments/dummy/chat/completions'
                $ret.ApiType | Should -Be 'Azure'       # param value
                $ret.AuthType | Should -Be 'azure'      # param value
                $ret.ApiBase | Should -Be 'ENV_BASE'    # env value
                $ret.MaxRetryCount | Should -Be 15      # context value
                $ret.TimeoutSec | Should -Be 50         # param value
                Get-PlainTextFromSecureString $ret.ApiKey | Should -Be 'PARAM_KEY' # param value
                Should -Invoke Get-AzureOpenAIAPIEndpoint -Times 1 -Exactly
            }

            It 'When the API base URL is Azure even though the API type is OpenAI. In this case, ignore the base URL.' {
                $ExplicitParams = @{}
                $Context = @{
                    ApiKey   = 'CONTEXT_KEY'
                    ApiType  = 'OpenAI'
                    AuthType = 'Azure'                          # Should ignore
                    ApiBase  = 'https://test.openai.azure.com/' # Should ignore
                }
                Set-OpenAIContext @Context
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.Uri | Should -Be 'https://api.openai.com/v1/chat/completions'
                $ret.ApiType | Should -Be 'OpenAI'
                $ret.AuthType | Should -Be 'openai'
                $ret.ApiBase | Should -BeNullOrEmpty
                Get-PlainTextFromSecureString $ret.ApiKey | Should -Be 'CONTEXT_KEY'
                Should -Invoke Get-OpenAIAPIEndpoint -Times 1 -Exactly
            }

            It 'When the API base URL is NOT Azure and the API type is OpenAI. In this case, obey specified base URL.' {
                $ExplicitParams = @{
                    ApiKey  = 'PARAM_KEY'
                    ApiType = 'OpenAI'
                    ApiBase = 'https://test.openai.notazure.com/'
                }
                $Context = @{
                    ApiKey   = 'CONTEXT_KEY'
                    ApiType  = 'Azure'
                    AuthType = 'Azure'
                    ApiBase  = 'https://test.openai.azure.com/'
                }
                Set-OpenAIContext @Context
                $ret = Get-OpenAIAPIParameter -EndpointName 'foo' -Parameters $ExplicitParams
                $ret.ApiType | Should -Be 'OpenAI'
                $ret.AuthType | Should -Be 'openai'
                $ret.ApiBase | Should -Be 'https://test.openai.notazure.com/'
                Get-PlainTextFromSecureString $ret.ApiKey | Should -Be 'PARAM_KEY'
                Should -Invoke Get-OpenAIAPIEndpoint -Times 1 -Exactly
            }
        }
    }
}
