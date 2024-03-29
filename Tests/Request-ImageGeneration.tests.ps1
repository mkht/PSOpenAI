#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $ProgressPreference = 'SilentlyContinue'
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    $script:TestImageData = [string](Resolve-Path (Join-Path $PSScriptRoot '../Docs/images'))
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ImageGeneration' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -ModuleName $script:ModuleName Copy-TempFile {}
            Mock -ModuleName $script:ModuleName Remove-Item {}
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Generate image. format = url' {
            $TestResponse = @'
{
    "created": 1678359675,
    "data": [
        {
        "url": "https://dummyimage.example.com"
        }
    ]
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $TestResponse }
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -Format url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -Be 'https://dummyimage.example.com'
        }

        It 'Generate image. format = raw_response' {
            $TestResponse = @'
{
    "created": 1678359675,
    "data": [
        {
        "url": "https://dummyimage.example.com"
        }
    ]
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $TestResponse }
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -Format raw_response -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -BeExactly $TestResponse
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Generate image. OutFile' {
            { $script:Result = Request-ImageGeneration `
                    -Prompt 'Lion' `
                    -OutFile (Join-Path $TestDrive 'file1.png') `
                    -Size 256 `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'file1.png') | Should -Exist
        }

        It 'Image generation. Format = url' {
            { $script:Result = Request-ImageGeneration `
                    -Prompt 'Pigs' `
                    -Format url `
                    -Size 256 `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [string]
            $Result | Should -Match '^https://'
        }

        It 'Image generation. Format = base64' {
            { $script:Result = Request-ImageGeneration `
                    -Prompt 'Dog' `
                    -Format base64 `
                    -Size 256 `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [string]
            { [Convert]::FromBase64String($script:Result) } | Should -Not -Throw
        }

        It 'Image generation. Format = byte' {
            { $script:Result = Request-ImageGeneration `
                    -Prompt 'Fox' `
                    -Format byte `
                    -Size 256 `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result.GetType().Name | Should -Be 'Byte[]'
            $Result.Count | Should -BeGreaterThan 1
        }

        It 'Image generation. Specifies model name (dall-e-3) and styles.' {
            { $script:Result = Request-ImageGeneration `
                    -Prompt 'A cute baby lion' `
                    -Model 'dall-e-3' `
                    -Format url `
                    -Quality HD `
                    -Style natural `
                    -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [string]
            $Result | Should -Match '^https://'
        }
    }
}
