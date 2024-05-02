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
            { $script:Result = Remove-ThreadMessage -InputObject 'thread_abc123' -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Remove message with Thread object and message id' {
            $InObject = [pscustomobject]@{
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $script:Result = Remove-ThreadMessage -InputObject $InObject -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Pipeline input with ID' {
            $InObject = 'thread_abc123'
            { $InObject | Remove-ThreadMessage -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Pipeline input with Object' {
            $InObject = [pscustomobject]@{
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $InObject | Remove-ThreadMessage -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Remove-ThreadMessage -ea Stop } | Should -Throw
            Should -Not -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
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
