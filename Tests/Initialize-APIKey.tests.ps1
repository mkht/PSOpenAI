#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

$ModuleName = 'PSOpenAI'

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force

    # backup current key
    $script:BackupGlobalApiKey = $global:OPENAI_API_KEY
    $script:BackupEnvApiKey = $env:OPENAI_API_KEY

    function Get-PlainTextFromSecureString ($securestring) {
        $p = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
        [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($p)
        $securestring.Dispose()
    }
}

AfterAll {
    #Restore key
    $global:OPENAI_API_KEY = $script:BackupGlobalApiKey
    $env:OPENAI_API_KEY = $script:BackupEnvApiKey
    $script:BackupGlobalApiKey = $script:BackupEnvApiKey = $script:BackupGlobalToken = $script:BackupEnvToken = $null
}

Describe 'Initialize-APIKey' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        InModuleScope $ModuleName {

            BeforeAll {
                function Get-PlainTextFromSecureString ($securestring) {
                    $p = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
                    [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($p)
                    $securestring.Dispose()
                }
            }

            BeforeEach {
                $global:OPENAI_API_KEY = $null
                $env:OPENAI_API_KEY = $null
            }

            It 'ApiKey from parameter' {
                $ret = Initialize-APIKey -ApiKey 'APIKEY'
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be 'APIKEY'
            }

            It 'ApiKey from parameter as securestring' {
                $ret = Initialize-APIKey -ApiKey (ConvertTo-SecureString 'APIKEY' -AsPlainText -Force)
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be 'APIKEY'
            }

            It 'ApiKey from global variable (OPENAI_API_KEY)' {
                $global:OPENAI_API_KEY = 'GLOBALAPIKEY'
                $ret = Initialize-APIKey -ApiKey $null
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be 'GLOBALAPIKEY'
            }

            It 'ApiKey from environment variable (OPENAI_API_KEY)' {
                $env:OPENAI_API_KEY = 'ENVAPIKEY'
                $ret = Initialize-APIKey -ApiKey $null
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be 'ENVAPIKEY'
            }

            It '1: ApiKey > Global > Env' {
                $ApiKey = 'APIKEY'
                $global:OPENAI_API_KEY = 'GLOBALAPIKEY'
                $env:OPENAI_API_KEY = 'ENVAPIKEY'
                $ret = Initialize-APIKey -ApiKey $ApiKey
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be $ApiKey
            }

            It '2: ApiKey > Global > Env' {
                $ApiKey = $null
                $global:OPENAI_API_KEY = 'GLOBALAPIKEY'
                $env:OPENAI_API_KEY = 'ENVAPIKEY'
                $ret = Initialize-APIKey -ApiKey $ApiKey
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be $global:OPENAI_API_KEY
            }

            It '3: ApiKey > Global > Env' {
                $ApiKey = $null
                $global:OPENAI_API_KEY = $null
                $env:OPENAI_API_KEY = 'ENVAPIKEY'
                $ret = Initialize-APIKey -ApiKey $ApiKey
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be $env:OPENAI_API_KEY
            }

            It 'Error when the ApiKey is not string or securestring' {
                $ApiKey = @{a = 'b' }
                { Initialize-APIKey -ApiKey $ApiKey -ea Stop } | Should -Throw
            }
        }
    }
}
