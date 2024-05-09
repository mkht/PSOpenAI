#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-ThreadMessage' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "msg_abc123",
    "object": "thread.message.deleted",
    "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove thread message with ID' {
            { $script:Result = Remove-ThreadMessage -ThreadId 'thread_abc123' -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        Context 'Parameter Sets' {
            It 'Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Remove-ThreadMessage -Thread $InObject -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-ThreadMessage -Thread $InObject 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-ThreadMessage 'Hi' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Remove-ThreadMessage -ThreadId 'thread_abc123' -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-ThreadMessage -ThreadId 'thread_abc123' 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Remove-ThreadMessage 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123'; message_id = 'msg_abc123' } | Remove-ThreadMessage -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Thread | Remove-Thread -TimeoutSec 30 -MaxRetryCount 5
            $script:Thread = $null
        }

        It 'Remove thread message' {
            $script:Thread = New-Thread | Add-ThreadMessage -Message 'Hello' -PassThru
            $threadmessage = $script:Thread | Get-ThreadMessage
            $threadmessage | Should -HaveCount 1
            { $script:Thread | Remove-ThreadMessage -MessageId $threadmessage.id -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $script:Thread | Get-ThreadMessage | Should -HaveCount 0
        }

        It 'Error on non existent thread message' {
            $script:Thread = New-Thread | Add-ThreadMessage -Message 'Hello' -PassThru
            { $script:Thread | Remove-ThreadMessage -MessageId 'invalid_msg_id' -TimeoutSec 30 -ea Stop } | Should -Throw
        }
    }
}
