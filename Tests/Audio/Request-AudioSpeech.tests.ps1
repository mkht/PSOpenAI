#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-AudioSpeech' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { [byte[]](77, 79, 67, 75) }
        }

        It 'Text to Speech' {
            { Request-AudioSpeech -Text 'test' -OutFile (Join-Path $TestDrive 'mock.mp3') -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            (Join-Path $TestDrive 'mock.mp3') | Should -FileContentMatchExactly 'MOCK'
        }

        It 'Pipeline input (string)' {
            { 'test' | Request-AudioSpeech -OutFile (Join-Path $TestDrive 'mock.mp3') -ea Stop } | Should -Not -Throw
        }

        It 'Pipeline input from chat completion object' {
            $obj = [PSCustomObject]@{
                Message = 'Message'
                Answer  = [string[]]('Answer')
            }
            { $obj | Request-AudioSpeech -OutFile (Join-Path $TestDrive 'mock.mp3') -ea Stop } | Should -Not -Throw
        }

        It 'Error if pipeline input is invalid type of object' {
            $obj = [byte[]](1..10)
            { $obj | Request-AudioSpeech -OutFile (Join-Path $TestDrive 'mock.mp3') -ea Stop } | Should -Throw
        }

        It 'Fully parameterized' {
            { $params = @{
                    Text        = 'test'
                    Model       = 'tts-1-hd'
                    Voice       = 'onyx'
                    Format      = 'opus'
                    Speed       = 1.5
                    OutFile     = (Join-Path $TestDrive 'テスト.mp3')
                    ErrorAction = 'Stop'
                }
                Request-AudioSpeech @params
            } | Should -Not -Throw
            Should -InvokeVerifiable
            (Join-Path $TestDrive 'テスト.mp3') | Should -FileContentMatchExactly 'MOCK'
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            Remove-Item (Join-Path $TestDrive 'test.aac') -Force -ErrorAction Ignore
        }

        It 'Text to Speech' {
            { $params = @{
                    Text          = 'Hey, I want to play the game with you.'
                    Model         = 'tts-1'
                    Voice         = 'nova'
                    Format        = 'aac'
                    Speed         = 1.1
                    OutFile       = (Join-Path $TestDrive 'test.aac')
                    TimeoutSec    = 30
                    MaxRetryCount = 3
                    ErrorAction   = 'Stop'
                }

                Request-AudioSpeech @params
            } | Should -Not -Throw
            (Join-Path $TestDrive 'test.aac') | Should -Exist
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

            $script:Model = 'tts-1'
        }

        BeforeEach {
            Remove-Item (Join-Path $TestDrive 'test.aac') -Force -ErrorAction Ignore
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'Text to Speech' {
            { $params = @{
                    Text          = 'Hey, I want to play the game with you.'
                    Model         = $script:Model
                    Voice         = 'nova'
                    Format        = 'aac'
                    Speed         = 1.1
                    OutFile       = (Join-Path $TestDrive 'test.aac')
                    TimeoutSec    = 30
                    MaxRetryCount = 3
                    ErrorAction   = 'Stop'
                }

                Request-AudioSpeech @params
            } | Should -Not -Throw
            (Join-Path $TestDrive 'test.aac') | Should -Exist
        }
    }
}
