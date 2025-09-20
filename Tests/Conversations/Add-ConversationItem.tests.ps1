#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Add-ConversationItem' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                @'
{
  "object": "list",
  "data": [
    {
      "type": "message",
      "id": "msg_abc",
      "status": "completed",
      "role": "user",
      "content": [
        {"type": "input_text", "text": "Hello!"}
      ]
    },
    {
      "type": "message",
      "id": "msg_def",
      "status": "completed",
      "role": "user",
      "content": [
        {"type": "input_text", "text": "How are you?"}
      ]
    }
  ],
  "first_id": "msg_abc",
  "last_id": "msg_def",
  "has_more": false
}
'@
            }
            Mock -Verifiable -ModuleName $script:ModuleName Get-Conversation {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation'
                    id         = 'conv_abc123'
                    metadata   = @{}
                    created_at = [datetime]::Today
                    Items      = @(
                        [pscustomobject]@{
                            PSTypeName = 'PSOpenAI.Conversation.Item'
                            id         = 'msg_abc'
                            type       = 'message'
                            role       = 'user'
                            content    = @(
                                [pscustomobject]@{type = 'input_text'; text = 'Hello!' }
                            )
                        },
                        [pscustomobject]@{
                            PSTypeName = 'PSOpenAI.Conversation.Item'
                            id         = 'msg_def'
                            type       = 'message'
                            role       = 'user'
                            content    = @(
                                [pscustomobject]@{type = 'input_text'; text = 'How are you?' }
                            )
                        }
                    )
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Add conversation item' {
            { $splat = @{
                    ConversationId = 'conv_abc123'
                    Message        = 'Hello'
                    ErrorAction    = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Get-Conversation -ModuleName $script:ModuleName
            $script:Result | Should -BeNullOrEmpty
        }

        It 'Add conversation item with PassThru' {
            { $splat = @{
                    ConversationId = 'conv_abc123'
                    Message        = 'Hello'
                    PassThru       = $true
                    ErrorAction    = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-Conversation -ModuleName $script:ModuleName -Times 1 -Exactly
            $script:Result | Should -Not -BeNullOrEmpty
        }

        It 'Image input' {
            { $splat = @{
                    ConversationId = 'conv_abc123'
                    Images         = @('https://example.com/image.jpg', 'fileid_12345', (Join-Path $script:TestData 'sweets_donut.png'))
                    PassThru       = $true
                    ErrorAction    = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-Conversation -ModuleName $script:ModuleName -Times 1 -Exactly
            $script:Result | Should -Not -BeNullOrEmpty
        }

        It 'File input' {
            { $splat = @{
                    ConversationId = 'conv_abc123'
                    Files          = @('https://example.com/file.pdf', 'fileid_12345', (Join-Path $script:TestData 'sample.pdf'))
                    PassThru       = $true
                    ErrorAction    = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-Conversation -ModuleName $script:ModuleName -Times 1 -Exactly
            $script:Result | Should -Not -BeNullOrEmpty
        }

        # Skip because it seems not implemented in the backend.
        It 'Audio input' -Skip {
            { $splat = @{
                    ConversationId  = 'conv_abc123'
                    InputAudioFiles = ($script:TestData + '/voice_japanese.mp3')
                    PassThru        = $true
                    ErrorAction     = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-Conversation -ModuleName $script:ModuleName -Times 1 -Exactly
            $script:Result | Should -Not -BeNullOrEmpty
        }

        It 'All parameters' {
            { $splat = @{
                    ConversationId   = 'conv_abc123'
                    Message          = 'Hello'
                    Role             = 'user'
                    SystemMessage    = @('System message 1', 'System message 2')
                    DeveloperMessage = @('Developer message 1', 'Developer message 2')
                    Images           = @('https://example.com/image.jpg', 'fileid_img12345', (Join-Path $script:TestData 'sweets_donut.png'))
                    ImageDetail      = 'high'
                    Files            = @('https://example.com/file.pdf', 'fileid_file12345', (Join-Path $script:TestData '日本語テキスト.txtf'))
                    # InputAudioFiles  = @(($script:TestData + '/voice_japanese.mp3'))
                    # InputAudioFormat = 'mp3'
                    Include          = @('message.input_image.image_url', 'file_search_call.results')
                    PassThru         = $true
                    ErrorAction      = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-Conversation -ModuleName $script:ModuleName -Times 1 -Exactly
            $script:Result | Should -Not -BeNullOrEmpty
        }

        It 'Error: No message' {
            { Add-ConversationItem -ConversationId 'conv_abc123' -ErrorAction Stop } | Should -Throw 'No message is specified. You must specify one or more messages.*'
            Should -Not -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            Should -Not -Invoke Get-Conversation -ModuleName $script:ModuleName
        }

        Context 'Parameter Sets' {
            It 'ConversationId' {
                # Named
                { Add-ConversationItem -ConversationId 'conv_abc123' -Message 'Hi' -ea Stop } | Should -Not -Throw
                # Positional
                { Add-ConversationItem 'Hi' -ConversationId 'conv_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{conversation_id = 'conv_abc123'; message = 'Hi' } | Add-ConversationItem -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            $script:Result = $null
            $script:Conversation = New-Conversation -MetaData @{ purpose = 'test' } -ErrorAction Stop
        }

        AfterEach {
            if (Get-Command Remove-Conversation -ErrorAction SilentlyContinue) {
                $script:Conversation | Remove-Conversation -ea SilentlyContinue
            }
        }

        It 'Add conversation item' {
            { $splat = @{
                    ConversationId   = $Conversation
                    DeveloperMessage = 'you are a helpful assistant.'
                    Message          = 'Hello.'
                    PassThru         = $true
                    ErrorAction      = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            $Result.id | Should -Be $Conversation.id
            $Result.Items | Should -HaveCount 2
            $Result.Items[0].role | Should -Be 'developer'
            $Result.Items[0].content[0].text | Should -BeExactly 'you are a helpful assistant.'
            $Result.Items[1].role | Should -Be 'user'
            $Result.Items[1].content[0].text | Should -BeExactly 'Hello.'
        }

        It 'Add Image Item' {
            { $splat = @{
                    ConversationId = $Conversation
                    Message        = 'Please explain about this image.'
                    Images         = Join-Path $script:TestData 'sweets_donut.png'
                    PassThru       = $true
                    ErrorAction    = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            $Result.id | Should -Be $Conversation.id
            $Result.Items | Should -HaveCount 1
            $Result.Items[0].role | Should -Be 'user'
            $Result.Items[0].content[0].text | Should -BeExactly 'Please explain about this image.'
            $Result.Items[0].content[1].type | Should -Be 'input_image'
        }

        It 'Add File Item' {
            { $splat = @{
                    ConversationId = $Conversation
                    Message        = 'Please summarize the content of this file.'
                    Files          = 'https://upload.wikimedia.org/wikipedia/commons/5/57/ApiterapiaWiki.pdf'
                    PassThru       = $true
                    ErrorAction    = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            $Result.id | Should -Be $Conversation.id
            $Result.Items | Should -HaveCount 1
            $Result.Items[0].role | Should -Be 'user'
            $Result.Items[0].content[0].text | Should -BeExactly 'Please summarize the content of this file.'
            $Result.Items[0].content[1].type | Should -Be 'input_file'
            $Result.Items[0].content[1].file_url | Should -Be 'https://upload.wikimedia.org/wikipedia/commons/5/57/ApiterapiaWiki.pdf'
        }

        # Skip because it seems not implemented in the backend.
        It 'Add Audio Item' -Skip {
            { $splat = @{
                    ConversationId  = $Conversation
                    Message         = 'Transcribe this audio.'
                    InputAudioFiles = @(($script:TestData + '/voice_japanese.mp3'))
                    PassThru        = $true
                    ErrorAction     = 'Stop'
                }
                $script:Result = Add-ConversationItem @splat
            } | Should -Not -Throw
            $Result.id | Should -Be $Conversation.id
            $Result.Items | Should -HaveCount 1
            $Result.Items[0].role | Should -Be 'user'
        }
    }
}