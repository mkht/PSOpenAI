#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Conversations E2E Test' {
    Context 'End-to-End tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext
            $script:Model = 'gpt-5-nano'
        }

        Context 'General' {

            BeforeAll {
                $script:Conversation = $null
            }

            It 'STEP1: Create an Conversation' {
                { $script:Conversation = New-Conversation -MetaData @{ purpose = 'test' } -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
                $Conversation.id | Should -BeLike 'conv_*'
                $Conversation.Items | Should -HaveCount 0
            }

            It 'STEP2: Add a message item to the conversation' {
                { $script:Conversation = $script:Conversation | Add-ConversationItem -Message '9.11 and 9.9, which is larger.' -PassThru -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
                $Conversation.Items | Should -HaveCount 1
            }

            It 'STEP3: Get response from the model' {
                $ret = Request-Response -Conversation $script:Conversation -Model $script:Model -Store $true -Verbosity low -ReasoningEffort minimal -TimeoutSec 60 -MaxRetryCount 5 -ea Stop
                $ret | Should -Not -BeNullOrEmpty
            }

            It 'STEP4: Get conversation messages.' {
                { $script:Conversation = Get-Conversation -ConversationId $script:Conversation -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
                $Conversation.Items.Count | Should -BeGreaterOrEqual 2
                $Conversation.Items[0].Role | Should -Be 'user'
                $Conversation.Items[-1].Role | Should -Be 'assistant'
            }

            It 'STEP5: Remove conversation.' {
                { $script:Conversation | Remove-Conversation -ea Stop } | Should -Not -Throw
                { Get-Conversation -ConversationId $script:Conversation -ea Stop } | Should -Throw
            }
        }
    }
}