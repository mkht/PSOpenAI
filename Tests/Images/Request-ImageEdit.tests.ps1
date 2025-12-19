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
                    Image       = $script:TestImageData + '/fether_mask.png'
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
                    Image          = @(($script:TestImageData + '/fether_mask.png'), ($script:TestImageData + '/cupcake.png'))
                    NumberOfImages = 3
                    OutFile        = Join-Path $TestDrive 'fileA.png'
                    Model          = 'gpt-image-1.5'
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
                    Image          = ($script:TestImageData + '/fether_mask.png')
                    Mask           = ($script:TestImageData + '/fether_mask.png')
                    NumberOfImages = 1
                    OutFile        = Join-Path $TestDrive 'fileB.png'
                    Model          = 'gpt-image-1.5'
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
            { $script:Result = Request-ImageEdit -Image ($script:TestImageData + '/fether_mask.png') -Prompt 'sunflower' -ResponseFormat url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -Be 'https://dummyimage.example.com'
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
            { $script:Result = Request-ImageEdit -Image ($script:TestImageData + '/fether_mask.png') -Model gpt-image-1 -Prompt 'sunflower' -ResponseFormat url -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Image'
            $Result.created | Should -BeOfType [datetime]
        }

        It 'Error if image file not exist' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {}
            { $script:Result = Request-ImageEdit -Image ($script:TestImageData + '/notexist.png') -Prompt 'sunflower' -ea Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }

        Context 'Streaming' {
            It 'Image Edit. OutFile.' {
                $TestResponse = @'
{
  "type": "image_edit.completed",
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
                        Image       = ($script:TestImageData + '/fether_mask.png')
                        Model       = 'gpt-image-1.5'
                        Size        = '1024x1024'
                        OutFile     = Join-Path $TestDrive 'file.png'
                        ErrorAction = 'Stop'
                    }
                    $script:Result = Request-ImageEdit @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -BeNullOrEmpty
                (Join-Path $TestDrive 'file.png') | Should -Exist
                (Join-Path $TestDrive 'file.png') | Should -FileContentMatchExactly 'TEST_IMAGE_1'
            }

            It 'Image Edit. OutFile. Partial images.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_edit.partial_image","b64_json":"VEVTVF9JTUFHRV8yX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_edit.partial_image","b64_json":"VEVTVF9JTUFHRV8yX1BBUlRJQUxfMQ==","created_at":1620000000,"partial_image_index": 1}'
                    '{"type":"image_edit.partial_image","b64_json":"VEVTVF9JTUFHRV8yX1BBUlRJQUxfMg==","created_at":1620000000,"partial_image_index": 2}'
                    '{"type":"image_edit.completed","b64_json":"VEVTVF9JTUFHRV8y","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt        = 'Hello'
                        Image         = ($script:TestImageData + '/fether_mask.png')
                        Model         = 'gpt-image-1.5'
                        Size          = '1024x1024'
                        OutFile       = Join-Path $TestDrive 'file.png'
                        PartialImages = 3
                        ErrorAction   = 'Stop'
                    }
                    $script:Result = Request-ImageEdit @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -BeNullOrEmpty
                (Join-Path $TestDrive 'file-0.png') | Should -FileContentMatchExactly 'TEST_IMAGE_2_PARTIAL_0'
                (Join-Path $TestDrive 'file-1.png') | Should -FileContentMatchExactly 'TEST_IMAGE_2_PARTIAL_1'
                (Join-Path $TestDrive 'file-2.png') | Should -FileContentMatchExactly 'TEST_IMAGE_2_PARTIAL_2'
                (Join-Path $TestDrive 'file.png') | Should -FileContentMatchExactly 'TEST_IMAGE_2'
            }

            It 'Image Edit. ResponseFormat = object' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_edit.partial_image","b64_json":"VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_edit.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Image          = ($script:TestImageData + '/fether_mask.png')
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'object'
                        PartialImages  = 1
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageEdit @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 2
                $Result[0].PSTypeNames | Should -Contain 'PSOpenAI.Image'
                $Result[0].type | Should -Be 'image_edit.partial_image'
                $Result[0].created_at | Should -BeOfType [datetime]
                $Result[0].b64_json | Should -Be 'VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA=='
                $Result[1].PSTypeNames | Should -Contain 'PSOpenAI.Image'
                $Result[1].type | Should -Be 'image_edit.completed'
                $Result[1].created_at | Should -BeOfType [datetime]
                $Result[1].b64_json | Should -Be 'VEVTVF9JTUFHRV8z'
            }

            It 'Image Edit. ResponseFormat = base64' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_edit.partial_image","b64_json":"VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_edit.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Image          = ($script:TestImageData + '/fether_mask.png')
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'base64'
                        PartialImages  = 1
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageEdit @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 2
                $Result[0] | Should -BeExactly 'VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA=='
                $Result[1] | Should -BeExactly 'VEVTVF9JTUFHRV8z'
            }

            It 'Image Edit. ResponseFormat = byte. Single image.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_edit.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Image          = ($script:TestImageData + '/fether_mask.png')
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'byte'
                        PartialImages  = 0
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageEdit @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 12
                $Result[0] | Should -Be 84
                $Result[-1] | Should -Be 51
            }

            It 'Image Edit. ResponseFormat = byte. Partial image.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_edit.partial_image","b64_json":"VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_edit.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Image          = ($script:TestImageData + '/fether_mask.png')
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'byte'
                        PartialImages  = 1
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageEdit @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 2
                $Result[0] | Should -HaveCount 22
                $Result[1] | Should -HaveCount 12
                $Result[0][0] | Should -BeOfType [byte]
                $Result[1][0] | Should -BeOfType [byte]
            }

            It 'Image Edit. ResponseFormat = byte. Partial image.' {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                    '{"type":"image_edit.partial_image","b64_json":"VEVTVF9JTUFHRV8zX1BBUlRJQUxfMA==","created_at":1620000000,"partial_image_index": 0}'
                    '{"type":"image_edit.completed","b64_json":"VEVTVF9JTUFHRV8z","created_at":1620000000}'
                }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { }
                { $splat = @{
                        Prompt         = 'Hello'
                        Image          = ($script:TestImageData + '/fether_mask.png')
                        Model          = 'gpt-image-1.5'
                        Size           = '1024x1024'
                        ResponseFormat = 'byte'
                        PartialImages  = 1
                        ErrorAction    = 'Stop'
                    }
                    $script:Result = Request-ImageEdit @splat -Stream
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
                        Image       = ($script:TestImageData + '/fether_mask.png')
                        Model       = 'gpt-image-1.5'
                        Size        = '1024x1024'
                        ErrorAction = 'Stop'
                    }
                    $script:Result = Request-ImageEdit @splat -Stream
                } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                Should -Not -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Image edit. OutFile' {
            { $params = @{
                    Image       = $script:TestImageData + '/fether_mask.png'
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
                    Image          = @(($script:TestImageData + '/fether_mask.png'), ($script:TestImageData + '/sand_with_feather.png'))
                    Prompt         = 'sunflower'
                    ResponseFormat = 'base64'
                    Model          = 'gpt-image-1.5'
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

        It 'Stream image edit' {
            { $splat = @{
                    Image         = $script:TestImageData + '/sand_with_feather.png'
                    Prompt        = 'A bird on the desert'
                    Model         = 'gpt-image-1.5'
                    OutFile       = Join-Path $TestDrive 'file4.png'
                    Size          = '1024x1024'
                    Stream        = $true
                    PartialImages = 2
                    TimeoutSec    = 60
                    ErrorAction   = 'Stop'
                }
                $script:Result = Request-ImageEdit @splat -Stream
            } | Should -Not -Throw
            $Result | Should -BeNullOrEmpty
            (Join-Path $TestDrive 'file4-0.png') | Should -Exist
            (Join-Path $TestDrive 'file4-1.png') | Should -Exist
            (Join-Path $TestDrive 'file4.png') | Should -Exist
        }
    }
}
