#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-AudioTranscription' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -ModuleName $script:ModuleName Remove-Item {}
        }

        BeforeEach {
            $script:Text = ''
        }

        It 'Audio transcription' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { 'MOCKED' }
            { $script:Text = Request-AudioTranscription -File ($script:TestData + '/voice_japanese.mp3') -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Text | Should -Be 'MOCKED'
        }

        It 'Audio transcription (Stream text)' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                '{"type":"transcript.text.delta","delta":"ECHO","logprobs":[{"token":"ECHO","logprob":-0.0024760163,"bytes":[228,189,149]}]}'
            }
            $Result = Request-AudioTranscription -File ($script:TestData + '/voice_japanese.mp3') -Stream -ea Stop
            Should -InvokeVerifiable
            $Result | Should -Be 'ECHO'
        }

        It 'Audio transcription (Stream object)' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                '{"type":"transcript.text.delta","delta":"ECHO","logprobs":[{"token":"ECHO","logprob":-0.0024760163,"bytes":[228,189,149]}]}'
            }
            $Result = Request-AudioTranscription -File ($script:TestData + '/voice_japanese.mp3') -Stream -StreamOutputType object -ea Stop
            Should -InvokeVerifiable
            $Result.type | Should -Be 'transcript.text.delta'
            $Result.delta | Should -Be 'ECHO'
        }

        It 'Use collect endpoint' {
            $Result = Request-AudioTranscription -File ($script:TestData + '/voice_japanese.mp3')
            $Result.Uri | Should -Match 'transcriptions'
        }

        It 'Error if file not exist' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {}
            { Request-AudioTranscription -File ($script:TestData + '/notexist.mp3') -ea Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }

        It 'Convert language name to ISO-639-1 code' {
            $params = @{
                File     = $script:TestData + '/voice_japanese.mp3'
                Language = 'English'
            }
            $Result = Request-AudioTranscription @params
            $Result.Body.language | Should -BeExactly 'en'
        }

        It 'Not convert language name to ISO-639-1 code when it cannot be.' {
            $params = @{
                File     = $script:TestData + '/voice_japanese.mp3'
                Language = 'Unknown'
            }
            $Result = Request-AudioTranscription @params
            $Result.Body.language | Should -BeExactly 'Unknown'
        }

        It 'Not convert LiteralLanguage to anything else' {
            $params = @{
                File            = $script:TestData + '/voice_japanese.mp3'
                LiteralLanguage = 'English'
            }
            $Result = Request-AudioTranscription @params
            $Result.Body.language | Should -BeExactly 'English'
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Text = ''
        }

        It 'Audio transcription' {
            { $script:Text = Request-AudioTranscription -File ($script:TestData + '/voice_japanese.mp3') -TimeoutSec 30 -ErrorAction Stop } | Should -Not -Throw
            $Text | Should -BeOfType [string]
            $Text.Length | Should -BeGreaterThan 1
        }

        It 'Audio transcription (format: verbose_json)' {
            { $params = @{
                    File        = ($script:TestData + '/voice_japanese.mp3')
                    Model       = 'whisper-1'
                    Format      = 'verbose_json'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }

                $script:Text = Request-AudioTranscription @params
            } | Should -Not -Throw
            $ret = ($Text | ConvertFrom-Json)
            $ret.text.Length | Should -BeGreaterThan 1
            $ret.task | Should -Be 'transcribe'
        }

        It 'Audio transcription (Stream)' {
            $params = @{
                File        = ($script:TestData + '/voice_japanese.mp3')
                Model       = 'gpt-4o-mini-transcribe'
                Stream      = $true
                TimeoutSec  = 30
                ErrorAction = 'Stop'
            }
            $Result = Request-AudioTranscription @params | Select-Object -First 3
            $Result | Should -HaveCount 3
        }

        It 'Non-ASCII filename' {
            Copy-Item ($script:TestData + '/voice_japanese.mp3') 'TestDrive:/日本語音声ファイル.mp3'
            { $params = @{
                    File        = 'TestDrive:/日本語音声ファイル.mp3'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }

                $script:Text = Request-AudioTranscription @params
            } | Should -Not -Throw
            $Text | Should -BeOfType [string]
            $Text.Length | Should -BeGreaterThan 1
        }
    }
}
