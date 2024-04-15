#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $ProgressPreference = 'SilentlyContinue'
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    $script:TestImageData = [string](Resolve-Path (Join-Path $PSScriptRoot '../Docs/images'))
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ImageVariation' {
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

        It 'Generate valiation image. format = url' {
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
            { $script:Result = Request-ImageVariation -Image ($script:TestImageData + '/cupcake.png') -Format url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -Be 'https://dummyimage.example.com'
        }

        It 'Error if image file not exist' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {}
            { $script:Result = Request-ImageVariation -Image ($script:TestImageData + '/notexist.png') -ea Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Image edit. OutFile' {
            { $splat = @{
                    Image       = $script:TestImageData + '/cupcake.png'
                    OutFile     = Join-Path $TestDrive 'file1.png'
                    Size        = 256
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageVariation @splat
            } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'file1.png') | Should -Exist
        }

        It 'Image edit. Format = url' {
            { $splat = @{
                    Image       = $script:TestImageData + '/cupcake.png'
                    Format      = 'url'
                    Size        = 256
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageVariation @splat
            } | Should -Not -Throw
            $Result | Should -BeOfType [string]
            $Result | Should -Match '^https://'
        }

        It 'Image edit. Format = base64' {
            { $splat = @{
                    Image       = $script:TestImageData + '/cupcake.png'
                    Format      = 'base64'
                    Size        = 256
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageVariation @splat
            } | Should -Not -Throw
            $Result | Should -BeOfType [string]
            { [Convert]::FromBase64String($script:Result) } | Should -Not -Throw
        }

        It 'Image edit. Format = byte' {
            { $splat = @{
                    Image       = $script:TestImageData + '/cupcake.png'
                    Format      = 'byte'
                    Size        = 256
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageVariation @splat
            } | Should -Not -Throw
            $Result.GetType().Name | Should -Be 'Byte[]'
            $Result.Count | Should -BeGreaterThan 1
        }
    }
}
