#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-ConversationItem' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "msg_abc123",
    "object": "conversation.item.deleted",
    "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove conversation item with ID' {
            { $script:Result = Remove-ConversationItem -ConversationId 'conv_abc123' -ItemId 'msg_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        Context 'Parameter Sets' {
            It 'Object' {
                $InObject1 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation'
                    id         = 'conv_abc123'
                }
                $InObject2 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation.Item'
                    id         = 'msg_abc123'
                }
                # Named
                { Remove-ConversationItem -Conversation $InObject1 -ItemId $InObject2 -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-ConversationItem -Conversation $InObject1 $InObject2 -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject1 | Remove-ConversationItem $InObject2 -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Remove-ConversationItem -ConversationId 'conv_abc123' -ItemId 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-ConversationItem -ConversationId 'conv_abc123' 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'conv_abc123' | Remove-ConversationItem 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{conversation_id = 'conv_abc123'; item_id = 'msg_abc123' } | Remove-ConversationItem -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
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

        It 'Remove conversation item' {
            $script:Conversation = New-Conversation | Add-ConversationItem -Message 'Hello' -PassThru
            $convitem = $script:Conversation.Items[-1]
            { $script:Conversation | Remove-ConversationItem -ItemId $convitem -ea Stop } | Should -Not -Throw
        }

        It 'Error on non existent conversation item' {
            $script:Conversation = New-Conversation | Add-ConversationItem -Message 'Hello' -PassThru
            { $script:Conversation | Remove-ConversationItem -ItemId 'invalid_convitem_id' -ea Stop } | Should -Throw
        }
    }
}
