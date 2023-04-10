#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-AudioTranscription' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -ModuleName $script:ModuleName Copy-TempFile {}
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
            $Result = Request-AudioTranscription `
                -File ($script:TestData + '/voice_japanese.mp3') `
                -Language 'English'
            $Result.Body.language | Should -BeExactly 'en'
        }

        It 'Not convert language name to ISO-639-1 code when it cannot be.' {
            $Result = Request-AudioTranscription `
                -File ($script:TestData + '/voice_japanese.mp3') `
                -Language 'Unknown'
            $Result.Body.language | Should -BeExactly 'Unknown'
        }

        It 'Not convert LiteralLanguage to anything else' {
            $Result = Request-AudioTranscription `
                -File ($script:TestData + '/voice_japanese.mp3') `
                -LiteralLanguage 'English'
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
            { $script:Text = Request-AudioTranscription `
                    -File ($script:TestData + '/voice_japanese.mp3') `
                    -Format 'verbose_json' `
                    -TimeoutSec 30 `
                    -ErrorAction Stop } | Should -Not -Throw
            $ret = ($Text | ConvertFrom-Json)
            $ret.text.Length | Should -BeGreaterThan 1
            $ret.task | Should -Be 'transcribe'
        }
    }
}
