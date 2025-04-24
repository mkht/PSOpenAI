#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $ProgressPreference = 'SilentlyContinue'
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    $script:TestImageData = Join-Path $script:ModuleRoot 'Docs/images'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ImageEdit' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -ModuleName $script:ModuleName Remove-Item {}
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Image edit. one input, one output, save to file' {
            $TestResponse = @'
{
  "created": 1713833628,
  "data": [
    {
      "b64_json": "SEVMTE8="
    }
  ],
  "usage": {
    "input_tokens": 50,
    "output_tokens": 50
  }
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $TestResponse }
            { $splat = @{
                    Prompt      = 'Hello'
                    Image       = $script:TestImageData + '/sunflower_masked.png'
                    OutFile     = Join-Path $TestDrive 'out.png'
                    Model       = 'dall-e-2'
                    Size        = '256x256'
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageEdit @splat
            } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'out.png') | Should -FileContentMatchExactly 'HELLO'
        }

        It 'Image edit. multiple input, multiple output, save to files' {
            $TestResponse = @'
{
  "created": 1713833628,
  "data": [
    {
      "b64_json": "RklSU1Q="
    },
    {
      "b64_json": "U0VDT05E"
    },
    {
      "b64_json": "VEhJUkQ="
    }
  ],
  "usage": {
    "input_tokens": 50,
    "output_tokens": 50
  }
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $TestResponse }
            { $splat = @{
                    Prompt         = 'Hello'
                    Image          = @(($script:TestImageData + '/sunflower_masked.png'), ($script:TestImageData + '/cupcake.png'))
                    NumberOfImages = 3
                    OutFile        = Join-Path $TestDrive 'fileA.png'
                    Model          = 'gpt-image-1'
                    Size           = 'auto'
                    ErrorAction    = 'Stop'
                }
                $script:Result = Request-ImageEdit @splat
            } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'fileA.png') | Should -FileContentMatchExactly 'FIRST'
            (Join-Path $TestDrive 'fileA-1.png') | Should -FileContentMatchExactly 'SECOND'
            (Join-Path $TestDrive 'fileA-2.png') | Should -FileContentMatchExactly 'THIRD'
        }

        It 'Image edit. one input with mask, save to files' {
            $TestResponse = @'
{
  "created": 1713833628,
  "data": [
    {
      "b64_json": "SEVMTE8="
    }
  ],
  "usage": {
    "input_tokens": 50,
    "output_tokens": 50
  }
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $TestResponse }
            { $splat = @{
                    Prompt         = 'Hello'
                    Image          = ($script:TestImageData + '/sunflower_masked.png')
                    Mask           = ($script:TestImageData + '/fether_mask.png')
                    NumberOfImages = 1
                    OutFile        = Join-Path $TestDrive 'fileB.png'
                    Model          = 'gpt-image-1'
                    Size           = 'auto'
                    ErrorAction    = 'Stop'
                }
                $script:Result = Request-ImageEdit @splat
            } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'fileB.png') | Should -FileContentMatchExactly 'HELLO'
        }

        It 'Image edit. response_format = url' {
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
            { $script:Result = Request-ImageEdit -Image ($script:TestImageData + '/sunflower_masked.png') -Prompt 'sunflower' -ResponseFormat url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -Be 'https://dummyimage.example.com'
        }

        It 'Error if image file not exist' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {}
            { $script:Result = Request-ImageEdit -Image ($script:TestImageData + '/notexist.png') -Prompt 'sunflower' -ea Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Image edit. OutFile' {
            { $params = @{
                    Image       = $script:TestImageData + '/sunflower_masked.png'
                    Prompt      = 'sunflower'
                    OutFile     = Join-Path $TestDrive 'file1.png'
                    Size        = '256x256'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageEdit @params
            } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'file1.png') | Should -Exist
        }

        It 'Image edit. Full parameters' {
            { $params = @{
                    Image          = @(($script:TestImageData + '/sunflower_masked.png'), ($script:TestImageData + '/sand_with_feather.png'))
                    Prompt         = 'sunflower'
                    ResponseFormat = 'base64'
                    Model          = 'gpt-image-1'
                    NumberOfImages = 2
                    Size           = '1024x1024'
                    Quality        = 'low'
                    TimeoutSec     = 60
                    ErrorAction    = 'Stop'
                }

                $script:Result = Request-ImageEdit @params
            } | Should -Not -Throw
            $Result | Should -HaveCount 2
            $Result[0] | Should -BeOfType [string]
            $Result[1] | Should -BeOfType [string]
        }

        It 'Image, Mask, Prompt' {
            { $params = @{
                    Image       = $script:TestImageData + '/sand_with_feather.png'
                    Mask        = $script:TestImageData + '/fether_mask.png'
                    Prompt      = 'A bird on the desert'
                    Model       = 'dall-e-2'
                    Size        = '256x256'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                Request-ImageEdit @params
            } | Should -Not -Throw
        }
    }
}
