#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ConversationItem' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "type": "message",
  "id": "msg_abc",
  "status": "completed",
  "role": "user",
  "content": [
    {"type": "input_text", "text": "Hello!"}
  ]
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/conversations/conv_abc123/items/msg_abc' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
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
        "role": "assistant",
        "content": [
            {"type": "output_text", "text": "Hello! How can I assist you today?"}
        ]
    }
    ],
    "first_id": "msg_abc",
    "last_id": "msg_def",
    "has_more": false
}
'@ } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/conversations/conv_abc123/items`?*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get single conversation item with item ID' {
            { $script:Result = Get-ConversationItem -ConversationId 'conv_abc123' -ItemId 'msg_abc' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/conversations/conv_abc123/items/msg_abc' -eq $Uri }
            $Result.id | Should -BeExactly 'msg_abc'
            $Result.role | Should -BeExactly 'user'
            $Result.content[0].type | Should -Be 'input_text'
            $Result.content[0].text | Should -Be 'Hello!'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Conversation.Item'
        }

        It 'List conversation items.' {
            { $script:Result = Get-ConversationItem -ConversationId 'conv_abc123' -All -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/conversations/conv_abc123/items`?*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeExactly 'msg_abc'
            $Result[1].id | Should -BeExactly 'msg_def'
            $Result[0].role | Should -BeExactly 'user'
            $Result[1].role | Should -BeExactly 'assistant'
            $Result[0].content[0].text | Should -Be 'Hello!'
            $Result[1].content[0].text | Should -Be 'Hello! How can I assist you today?'
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.Conversation.Item'
            $Result[1].psobject.TypeNames | Should -Contain 'PSOpenAI.Conversation.Item'
        }

        Context 'Parameter Sets' {
            It 'Get_Conversation' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation'
                    id         = 'conv_abc123'
                }
                # Named
                { Get-ConversationItem -Conversation $InObject -ItemId 'msg_abc' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ConversationItem $InObject 'msg_abc' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ConversationItem -ItemId 'msg_abc' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/conversations/conv_abc123/items/msg_abc' -eq $Uri }
            }

            It 'Get_ConversationId' {
                # Named
                { Get-ConversationItem -ConversationId 'conv_abc123' -ItemId 'msg_abc' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ConversationItem 'conv_abc123' 'msg_abc' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'conv_abc123' | Get-ConversationItem -ItemId 'msg_abc' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/conversations/conv_abc123/items/msg_abc' -eq $Uri }
            }

            It 'List_Conversation' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation'
                    id         = 'conv_abc123'
                }
                # Named
                { Get-ConversationItem -Conversation $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ConversationItem $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ConversationItem -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/conversations/conv_abc123/items`?*' }
            }

            It 'List_ConversationId' {
                # Named
                { Get-ConversationItem -ConversationId 'conv_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ConversationItem 'conv_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'conv_abc123' | Get-ConversationItem -All -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{conversation_id = 'conv_abc123' } | Get-ConversationItem -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/conversations/conv_abc123/items`?*' }
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext

            #Prepare test conversation object with 10 items
            $script:conversation = New-Conversation
            $msgs = (1..10) | % { 'Hello_{0}' -f $_ }
            $msgs | % { Add-ConversationItem -ConversationId $script:conversation -Message $_ -ea Stop }
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterAll {
            $script:conversation | Remove-Conversation -ea SilentlyContinue
        }

        It 'Get conversation items' {
            { $script:Result = $script:conversation | Get-ConversationItem -ea Stop } | Should -Not -Throw
            $Result | Should -HaveCount 10

            # Get single item and verify
            $itemId = $Result[0].id
            { $script:Result = $script:conversation | Get-ConversationItem -ItemId $itemId -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeExactly $itemId
        }

        It 'Get conversation items with limit' {
            { $script:Result = $script:conversation | Get-ConversationItem -Limit 3 -ea Stop } | Should -Not -Throw
            $Result | Should -HaveCount 3
        }

        It 'Get ALL conversation items' {
            { $script:Result = $script:conversation | Get-ConversationItem -All -ea Stop } | Should -Not -Throw
            $Result | Should -HaveCount 10
        }
    }
}
