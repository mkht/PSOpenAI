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
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "created": 1678359675,
    "data": [
        {
        "url": "https://dummyimage.example.com"
        }
    ]
}
'@ }
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -Format url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -Be 'https://dummyimage.example.com'
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

        It 'Image edit. Format = url' {
            { $script:Result = Request-ImageGeneration `
                    -Prompt 'Pigs' `
                    -Format url `
                    -Size 256 `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [string]
            $Result | Should -Match '^https://'
        }

        It 'Image edit. Format = base64' {
            { $script:Result = Request-ImageGeneration `
                    -Prompt 'Dog' `
                    -Format base64 `
                    -Size 256 `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [string]
            { [Convert]::FromBase64String($script:Result) } | Should -Not -Throw
        }

        It 'Image edit. Format = byte' {
            { $script:Result = Request-ImageGeneration `
                    -Prompt 'Fox' `
                    -Format byte `
                    -Size 256 `
                    -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result.GetType().Name | Should -Be 'Byte[]'
            $Result.Count | Should -BeGreaterThan 1
        }
    }
}
