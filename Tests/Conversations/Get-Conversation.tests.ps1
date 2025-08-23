#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Conversation' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -Verifiable -ModuleName $script:ModuleName Get-ConversationItem {
                [PSCustomObject]@{
                    PSTypeName = 'PSOpenAI.Conversation.Item'
                    'id'       = 'msg_xyz789'
                    'type'     = 'message'
                    status     = 'completed'
                    'role'     = 'user'
                    'content'  = @(
                        [PSCustomObject]@{
                            'type' = 'input_text'
                            'text' = 'Hello'
                        }
                    )
                }
            }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "conv_xyz789",
    "object": "conversation",
    "created_at": 1741900000,
    "metadata": {"key1" : "value1"}
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get conversation with ID' {
            { $script:Result = Get-Conversation -ConversationId 'conv_xyz789' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-ConversationItem -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -BeExactly 'conv_xyz789'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Conversation'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Items.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Items | Should -HaveCount 1
            $Result.Items[0].id | Should -BeExactly 'msg_xyz789'
        }

        Context 'Parameter Sets' {
            It 'Get_Conversation' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation'
                    id         = 'conv_xyz789'
                }
                # Named
                { Get-Conversation -Conversation $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Conversation $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-Conversation -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Get_Id' {
                # Named
                { Get-Conversation -ConversationId 'conv_xyz789' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Conversation 'conv_xyz789' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'conv_xyz789' | Get-Conversation -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{conversation_id = 'conv_xyz789' } | Get-Conversation -ea Stop } | Should -Not -Throw
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
        }

        AfterEach {
            if (Get-Command Remove-Conversation -ErrorAction SilentlyContinue) {
                $script:Result | Remove-Conversation -ea SilentlyContinue
            }
        }

        It 'Get conversation' {
            $script:conv = New-Conversation
            { $script:Result = $conv | Get-Conversation -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'conv_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Items.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Items | Should -HaveCount 0
        }

        It 'Error on non existent conversation' {
            $conversation_id = 'conv_notexist'
            { $conversation_id | Get-Conversation -ea Stop } | Should -Throw
        }
    }
}
