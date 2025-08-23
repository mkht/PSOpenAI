#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-Conversation' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "conv_abc123",
    "object": "conversation.deleted",
    "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove conversation with ID' {
            { $script:Result = Remove-Conversation -ConversationId 'conv_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Remove conversation with Conversation object' {
            $InObject = [pscustomobject]@{
                PSTypeName = 'PSOpenAI.Conversation'
                id         = 'conv_abc123'
                object     = 'conversation'
                created_at = [datetime]::Today
                Items      = @()
            }
            { $script:Result = Remove-Conversation -Conversation $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        Context 'Parameter Sets' {
            It 'Conversation' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation'
                    id         = 'conv_abc123'
                    object     = 'conversation'
                    created_at = [datetime]::Today
                    Items      = @()
                }
                # Named
                { Remove-Conversation -Conversation $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Conversation $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-Conversation -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Remove-Conversation -ConversationId 'conv_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Conversation 'conv_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'conv_abc123' | Remove-Conversation -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{conversation_id = 'conv_abc123' } | Remove-Conversation -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
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

        It 'Remove conversation' {
            $conv = New-Conversation
            { $conv | Remove-Conversation -ea Stop } | Should -Not -Throw
            $conv = try { $conv | Get-Conversation -ea Ignore }catch {}
            $conv | Should -BeNullOrEmpty
        }

        It 'Error on non existent conversation' {
            $conv_id = 'conv_notexist'
            { $conv_id | Remove-Conversation -ea Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }
    }
}
