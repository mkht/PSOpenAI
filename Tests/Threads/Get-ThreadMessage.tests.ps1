#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ThreadMessage' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        Context 'Single Message' {

            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "msg_abc123",
    "object": "thread.message",
    "created_at": 1699017614,
    "thread_id": "thread_abc123",
    "role": "user",
    "content": [
        {
        "type": "text",
        "text": {
            "value": "How does AI work? Explain it in simple terms.",
            "annotations": []
        }
        }
    ],
    "file_ids": [],
    "assistant_id": null,
    "run_id": null,
    "metadata": {}
    }
'@ }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Get a single thread message with message ID' {
                { $script:Result = Get-ThreadMessage -InputObject 'thread_abc123' -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result.id | Should -BeExactly 'msg_abc123'
                $Result.thread_id | Should -BeExactly 'thread_abc123'
                $Result.created_at | Should -BeOfType [datetime]
                $Result.content.type | Should -Be 'text'
            }

            It 'Pipeline input' {
                $InObject = [pscustomobject]@{
                    thread_id  = 'thread_abc123'
                    message_id = 'msg_abc123'
                }
                { $InObject | Get-ThreadMessage -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            }
        }

        Context 'List Messages' {
            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                    $msgobj = @'
{
    "id": "msg_abc123",
    "object": "thread.message",
    "created_at": 1699017614,
    "thread_id": "thread_abc123",
    "role": "user",
    "content": [{"type": "text", "text": {"value": "How does AI work? Explain it in simple terms.", "annotations": []}}]
}
'@
                    $list = '{{"object": "list", "data": [{0}], "first_id": "msg_abc123", "last_id": "msg_abc456", "has_more": false }}'
                    $list -f ([string[]]$msgobj * 20 -join ',')
                }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'List thread messages.' {
                { $script:Result = Get-ThreadMessage -InputObject 'thread_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 20
            }

            It 'Get all thread messages.' {
                { $script:Result = Get-ThreadMessage -InputObject 'thread_abc123' -All -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 20
            }

            It 'Pipeline input with Object' {
                $InObject = [pscustomobject]@{
                    id         = 'thread_abc123'
                    object     = 'thread'
                    created_at = [datetime]::Today
                }
                { $InObject | Get-ThreadMessage -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            }

            It 'Error on invalid input' {
                $InObject = [datetime]::Today
                { $InObject | Get-ThreadMessage -ea Stop } | Should -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            #Prepare test thread object with 25 messages
            $msgs = [string[]]'Hi' * 25
            $script:thread = New-Thread -Messages $msgs
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterAll {
            $script:thread | Remove-Thread -ea SilentlyContinue
        }

        It 'Get thread messages' {
            { $script:Result = $script:thread | Get-ThreadMessage -ea Stop } | Should -Not -Throw
            $Result | Should -HaveCount 20
        }

        It 'Get thread messages with limit' {
            { $script:Result = $script:thread | Get-ThreadMessage -Limit 3 -ea Stop } | Should -Not -Throw
            $Result | Should -HaveCount 3
        }

        It 'Get ALL thread messages' {
            { $script:Result = $script:thread | Get-ThreadMessage -All -ea Stop } | Should -Not -Throw
            $Result | Should -HaveCount 25
        }
    }
}
