#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $ProgressPreference = 'SilentlyContinue'
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    $script:TestImageData = Join-Path $script:ModuleRoot 'Docs/images'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ImageGeneration' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -ModuleName $script:ModuleName Remove-Item {}
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Generate image. Save to file.' {
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
                    OutFile     = Join-Path $TestDrive 'file.png'
                    Model       = 'dall-e-2'
                    Size        = '256x256'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageGeneration @splat
            } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'file.png') | Should -FileContentMatchExactly 'HELLO'
        }

        It 'Generate multiple images. Save to files.' {
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
                    OutFile        = Join-Path $TestDrive 'fileA.png'
                    NumberOfImages = 3
                    Model          = 'dall-e-3'
                    Size           = '1792x1024'
                    Style          = 'vivid'
                    Quality        = 'hd'
                    TimeoutSec     = 30
                    ErrorAction    = 'Stop'
                }
                $script:Result = Request-ImageGeneration @splat
            } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'fileA.png') | Should -FileContentMatchExactly 'FIRST'
            (Join-Path $TestDrive 'fileA-1.png') | Should -FileContentMatchExactly 'SECOND'
            (Join-Path $TestDrive 'fileA-2.png') | Should -FileContentMatchExactly 'THIRD'
        }

        It 'Generate image. response_format = base64' {
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
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -ResponseFormat base64 -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -BeExactly 'SEVMTE8='
        }

        It 'Generate multiple images. response_format = base64' {
            $TestResponse = @'
{
  "created": 1713833628,
  "data": [
    {
      "b64_json": "RklSU1Q="
    },
    {
      "b64_json": "U0VDT05E"
    }
  ],
  "usage": {
    "input_tokens": 50,
    "output_tokens": 50
  }
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $TestResponse }
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -NumberOfImages 2 -ResponseFormat base64 -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -HaveCount 2
            $Result[0] | Should -BeExactly 'RklSU1Q='
            $Result[1] | Should -BeExactly 'U0VDT05E'
        }

        It 'Generate image. response_format = byte' {
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
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -ResponseFormat byte -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -HaveCount 5
            $Result[0] | Should -BeOfType [byte]
            $Result[0] | Should -Be 72
            $Result[1] | Should -Be 69
            $Result[2] | Should -Be 76
            $Result[3] | Should -Be 76
            $Result[4] | Should -Be 79
        }

        It 'Generate multiple images. response_format = byte' {
            $TestResponse = @'
{
  "created": 1713833628,
  "data": [
    {
      "b64_json": "RklSU1Q="
    },
    {
      "b64_json": "U0VDT05E"
    }
  ],
  "usage": {
    "input_tokens": 50,
    "output_tokens": 50
  }
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $TestResponse }
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -NumberOfImages 2 -ResponseFormat byte -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -HaveCount 2
            $Result[0] | Should -HaveCount 5
            $Result[1] | Should -HaveCount 6
            $Result[0][0] | Should -BeOfType [byte]
            $Result[0][0] | Should -Be 70
            $Result[0][1] | Should -Be 73
            $Result[1][0] | Should -BeOfType [byte]
            $Result[1][0] | Should -Be 83
            $Result[1][1] | Should -Be 69
        }

        It 'Generate image. response_format = url' {
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
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -ResponseFormat url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -Be 'https://dummyimage.example.com'
        }

        It 'Generate multiple image. response_format = url' {
            $TestResponse = @'
{
    "created": 1678359675,
    "data": [
        {
        "url": "https://dummyimage1.example.com"
        },
        {
        "url": "https://dummyimage2.example.com"
        }
    ]
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $TestResponse }
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -NumberOfImages 2 -ResponseFormat url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -HaveCount 2
            $Result[0] | Should -Be 'https://dummyimage1.example.com'
            $Result[1] | Should -Be 'https://dummyimage2.example.com'
        }

        It 'Generate image. returns raw response' {
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
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -ResponseFormat url -OutputRawResponse -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -BeExactly $TestResponse
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Generate image. OutFile' {
            { $splat = @{
                    Prompt      = 'Lion'
                    OutFile     = Join-Path $TestDrive 'file1.png'
                    Size        = '256x256'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageGeneration @splat
            } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'file1.png') | Should -Exist
        }

        It 'Generate image. Full parameters' {
            { $params = @{
                    Prompt            = 'A cute baby lion'
                    Model             = 'gpt-image-1'
                    ResponseFormat    = 'base64'
                    Moderation        = 'low'
                    NumberOfImages    = 2
                    Size              = '1024x1024'
                    Background        = 'transparent'
                    Quality           = 'low'
                    OutputFormat      = 'webp'
                    OutputCompression = 50
                    TimeoutSec        = 60
                    MaxRetryCount     = 5
                    ErrorAction       = 'Stop'
                }
                $script:Result = Request-ImageGeneration @params
            } | Should -Not -Throw
            $Result | Should -HaveCount 2
            $Result[0] | Should -BeOfType [string]
            $Result[1] | Should -BeOfType [string]
        }
    }

    Context 'Integration tests (Azure)' -Tag 'Azure' {

        BeforeAll {
            $AzureContext = @{
                ApiType    = 'Azure'
                AuthType   = 'Azure'
                ApiKey     = $env:AZURE_OPENAI_API_KEY
                ApiBase    = $env:AZURE_OPENAI_ENDPOINT
                TimeoutSec = 30
            }
            Set-OpenAIContext @AzureContext
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'Image generation. Format = url' {
            { $splat = @{
                    Model          = 'dall-e-3'
                    Prompt         = 'A polar bear on an ice block'
                    ResponseFormat = 'url'
                    Size           = '1024x1024'
                    ErrorAction    = 'Stop'
                }
                $script:Result = Request-ImageGeneration @splat
            } | Should -Not -Throw
            $Result | Should -BeOfType [string]
            $Result | Should -Match '^https://'
        }
    }
}
