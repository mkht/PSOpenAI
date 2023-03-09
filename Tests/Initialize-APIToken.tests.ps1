#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

$ModuleName = 'PSOpenAI'
$script:ModuleRoot = Split-Path $PSScriptRoot -Parent
$script:ModuleName = 'PSOpenAI'
Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force

    # backup current token
    $script:BackupGlobalToken = $global:OPENAI_TOKEN
    $script:BackupEnvToken = $env:OPENAI_TOKEN

    function Get-PlainTextFromSecureString ($securestring) {
        $p = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securestring)
        [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($p)
        $securestring.Dispose()
    }
}

AfterAll {
    #Restore token
    $global:OPENAI_TOKEN = $script:BackupGlobalToken
    $env:OPENAI_TOKEN = $script:BackupEnvToken
    $script:BackupGlobalToken = $script:BackupEnvToken = $null
}

Describe 'Initialize-APIToken' {
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
                $global:OPENAI_TOKEN = $null
                $env:OPENAI_TOKEN = $null
            }

            It 'Token from parameter' {
                $ret = Initialize-APIToken -Token 'TOKEN'
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be 'TOKEN'
            }

            It 'Token from parameter as securestring' {
                $ret = Initialize-APIToken -Token (ConvertTo-SecureString 'TOKEN' -AsPlainText -Force)
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be 'TOKEN'
            }

            It 'Token from global variable' {
                $global:OPENAI_TOKEN = 'GLOBALTOKEN'
                $ret = Initialize-APIToken -Token $null
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be 'GLOBALTOKEN'
            }

            It 'Token from environment variable' {
                $env:OPENAI_TOKEN = 'ENVTOKEN'
                $ret = Initialize-APIToken -Token $null
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be 'ENVTOKEN'
            }

            It '1: Token > Global > Env' {
                $TOKEN = 'TOKEN'
                $global:OPENAI_TOKEN = 'GLOBALTOKEN'
                $env:OPENAI_TOKEN = 'ENVTOKEN'
                $ret = Initialize-APIToken -Token $TOKEN
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be $TOKEN
            }

            It '2: Token > Global > Env' {
                $TOKEN = $null
                $global:OPENAI_TOKEN = 'GLOBALTOKEN'
                $env:OPENAI_TOKEN = 'ENVTOKEN'
                $ret = Initialize-APIToken -Token $TOKEN
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be $global:OPENAI_TOKEN
            }

            It '3: Token > Global > Env' {
                $TOKEN = $null
                $global:OPENAI_TOKEN = $null
                $env:OPENAI_TOKEN = 'ENVTOKEN'
                $ret = Initialize-APIToken -Token $TOKEN
                $ret | Should -BeOfType [securestring]
                Get-PlainTextFromSecureString $ret | Should -Be $env:OPENAI_TOKEN
            }

            It 'Error when the token is not string or securestring' {
                $TOKEN = @{a = 'b' }
                { Initialize-APIToken -Token $TOKEN -ea Stop } | Should -Throw
            }
        }
    }
}
