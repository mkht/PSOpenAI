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

        It 'The GPT image models are not support response_format = url. Defaulting to object.' {
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
            { $script:Result = Request-ImageGeneration -Model gpt-image-1.5 -Prompt 'sunflower' -ResponseFormat url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Image'
            $Result.created | Should -BeOfType [datetime]
        }

        It 'Generate image. response_format = object' {
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
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -ResponseFormat object -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Image'
            $Result.created | Should -BeOfType [datetime]
            $Result.data | Should -HaveCount 1
            $Result.data[0].b64_json | Should -Be 'SEVMTE8='
        }

        It 'Generate multiple image. response_format = object' {
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
            { $script:Result = Request-ImageGeneration -Prompt 'sunflower' -NumberOfImages 2 -ResponseFormat object -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -HaveCount 1
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Image'
            $Result.created | Should -BeOfType [datetime]
            $Result.data | Should -HaveCount 2
            $Result.data[0].b64_json | Should -Be 'RklSU1Q='
            $Result.data[1].b64_json | Should -Be 'U0VDT05E'
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

        Context 'Streaming' {
            It 'Generate image. OutFile.' {
                $TestResponse = @'
{
  "type": "image_generation.completed",
  "b64_json": "VEVTVF9JTUFHRV8x",
  "created_at": 1620000000,
  "size": "1024x1024",
  "quality": "high",
  "background": "transparent",
  "output_format": "png",
  "usage": {
    "total_tokens": 100,
    "input_tokens": 50
  }
}
'@
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE { $TestResponse }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt      = 'Hello'
                        Model       = 'gpt-image-1.5'
                        Size        = '1024x1024'
                        OutFile     = Join-Path $TestDrive 'file.png'
                        ErrorAction = 'Stop'
                    }
                    $script:Result = Request-ImageGeneration @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -BeNullOrEmpty
                (Join-Path $TestDrive 'file.png') | Should -Exist
                (Join-Path $TestDrive 'file.png') | Should -FileContentMatchExactly 'TEST_IMAGE_1'
            }

            It 'Generate image. OutFile. Partial images.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_generation.partial_image","b64_json":"VEVTVF9JTUFHRV8yX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_generation.partial_image","b64_json":"VEVTVF9JTUFHRV8yX1BBUlRJQUxfMQ==","created_at":1620000000,"partial_image_index": 1}'
                    '{"type":"image_generation.partial_image","b64_json":"VEVTVF9JTUFHRV8yX1BBUlRJQUxfMg==","created_at":1620000000,"partial_image_index": 2}'
                    '{"type":"image_generation.completed","b64_json":"VEVTVF9JTUFHRV8y","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt        = 'Hello'
                        Model         = 'gpt-image-1.5'
                        Size          = '1024x1024'
                        OutFile       = Join-Path $TestDrive 'file.png'
                        PartialImages = 3
                        ErrorAction   = 'Stop'
                    }
                    $script:Result = Request-ImageGeneration @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -BeNullOrEmpty
                (Join-Path $TestDrive 'file-0.png') | Should -FileContentMatchExactly 'TEST_IMAGE_2_PARTIAL_0'
                (Join-Path $TestDrive 'file-1.png') | Should -FileContentMatchExactly 'TEST_IMAGE_2_PARTIAL_1'
                (Join-Path $TestDrive 'file-2.png') | Should -FileContentMatchExactly 'TEST_IMAGE_2_PARTIAL_2'
                (Join-Path $TestDrive 'file.png') | Should -FileContentMatchExactly 'TEST_IMAGE_2'
            }

            It 'Generate image. ResponseFormat = object' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_generation.partial_image","b64_json":"VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_generation.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'object'
                        PartialImages  = 1
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageGeneration @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 2
                $Result[0].PSTypeNames | Should -Contain 'PSOpenAI.Image'
                $Result[0].type | Should -Be 'image_generation.partial_image'
                $Result[0].created_at | Should -BeOfType [datetime]
                $Result[0].b64_json | Should -Be 'VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA=='
                $Result[1].PSTypeNames | Should -Contain 'PSOpenAI.Image'
                $Result[1].type | Should -Be 'image_generation.completed'
                $Result[1].created_at | Should -BeOfType [datetime]
                $Result[1].b64_json | Should -Be 'VEVTVF9JTUFHRV8z'
            }

            It 'Generate image. ResponseFormat = base64' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_generation.partial_image","b64_json":"VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_generation.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'base64'
                        PartialImages  = 1
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageGeneration @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 2
                $Result[0] | Should -BeExactly 'VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA=='
                $Result[1] | Should -BeExactly 'VEVTVF9JTUFHRV8z'
            }

            It 'Generate image. ResponseFormat = byte. Single image.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_generation.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'byte'
                        PartialImages  = 0
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageGeneration @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 12
                $Result[0] | Should -Be 84
                $Result[-1] | Should -Be 51
            }

            It 'Generate image. ResponseFormat = byte. Partial image.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_generation.partial_image","b64_json":"VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_generation.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'byte'
                        PartialImages  = 1
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageGeneration @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 2
                $Result[0] | Should -HaveCount 22
                $Result[1] | Should -HaveCount 12
                $Result[0][0] | Should -BeOfType [byte]
                $Result[1][0] | Should -BeOfType [byte]
            }

            It 'Generate image. ResponseFormat = byte. Partial image.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_generation.partial_image","b64_json":"VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_generation.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'byte'
                        PartialImages  = 1
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageGeneration @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 2
                $Result[0] | Should -HaveCount 22
                $Result[1] | Should -HaveCount 12
                $Result[0][0] | Should -BeOfType [byte]
                $Result[1][0] | Should -BeOfType [byte]
            }

            It 'Unknwon event type, Just ignore.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"unknown.event","b64_json":"VU5LTldPTg==","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt      = 'Hello'
                        Model       = 'gpt-image-1.5'
                        Size        = '1024x1024'
                        ErrorAction = 'Stop'
                    }
                    $script:Result = Request-ImageGeneration @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -BeNullOrEmpty
            }
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
                    Model             = 'gpt-image-1.5'
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

        It 'Stream image generation. OutFile' {
            { $splat = @{
                    Prompt        = 'A cute baby lion'
                    Model         = 'gpt-image-1.5'
                    OutFile       = Join-Path $TestDrive 'file3.png'
                    Size          = '1024x1024'
                    Stream        = $true
                    PartialImages = 2
                    TimeoutSec    = 60
                    ErrorAction   = 'Stop'
                }
                $script:Result = Request-ImageGeneration @splat -Stream
            } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'file3-0.png') | Should -Exist
            (Join-Path $TestDrive 'file3-1.png') | Should -Exist
            (Join-Path $TestDrive 'file3.png') | Should -Exist
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

        It 'Image generation. Save to file.' {
            { $splat = @{
                    Model       = 'dall-e-3'
                    Prompt      = 'A polar bear on an ice block'
                    OutFile     = Join-Path $TestDrive 'file1.png'
                    Size        = '1024x1024'
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ImageGeneration @splat
            } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'file1.png') | Should -Exist
        }

        It 'Image generation. response_format = url' {
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
