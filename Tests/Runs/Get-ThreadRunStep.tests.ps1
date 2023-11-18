#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ThreadRunStep' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadMessage {
                [PSCustomObject]@{
                    id           = 'msg_abc123'
                    object       = 'thread.message'
                    thread_id    = 'thread_abc123'
                    assistant_id = 'asst_abc123'
                    run_id       = 'run_abc123'
                    role         = 'assistant'
                    content      = @(
                        [PSCustomObject]@{
                            type = 'text'
                            text = [PSCustomObject]@{
                                value       = 'Hi! How can I help you today?'
                                annotations = [PSCustomObject]@{}
                            }
                        }
                    )
                }
            }
        }

        Context 'Get Single Step' {
            BeforeAll {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "step_abc123",
    "object": "thread.run.step",
    "created_at": 1699063291,
    "run_id": "run_abc123",
    "assistant_id": "asst_abc123",
    "thread_id": "thread_abc123",
    "type": "message_creation",
    "status": "completed",
    "cancelled_at": null,
    "completed_at": 1699063291,
    "expired_at": null,
    "failed_at": null,
    "last_error": null,
    "step_details": {
        "type": "message_creation",
        "message_creation": {
        "message_id": "msg_abc123"
        }
    }
}
'@ }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Get a single object with run ID' {
                $InObject = [PSCustomObject]@{
                    id        = 'run_abc123'
                    thread_id = 'thread_abc123'
                }
                { $script:Result = Get-ThreadRunStep -InputObject $InObject -StepId 'step_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                Should -Invoke Get-ThreadMessage -ModuleName $script:ModuleName
                $Result.id | Should -BeExactly 'step_abc123'
                $Result.object | Should -BeExactly 'thread.run.step'
                $Result.created_at | Should -BeOfType [datetime]
                $Result.completed_at | Should -BeOfType [datetime]
                $Result.SimpleContent.role | Should -Be 'assistant'
                $Result.SimpleContent.type | Should -Be 'text'
                $Result.SimpleContent.content | Should -Be 'Hi! How can I help you today?'
            }

            It 'Pipeline input' {
                $InObject = [PSCustomObject]@{
                    id        = 'run_abc123'
                    thread_id = 'thread_abc123'
                }
                { $InObject | Get-ThreadRunStep -StepId 'step_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                Should -Invoke Get-ThreadMessage -ModuleName $script:ModuleName
            }
        }

        Context 'List Steps' {
            BeforeAll {
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                    $msgobj = @'
{
    "id": "step_abc123",
    "object": "thread.run.step",
    "created_at": 1699063291,
    "run_id": "run_abc123",
    "assistant_id": "asst_abc123",
    "thread_id": "thread_abc123",
    "type": "message_creation",
    "status": "completed",
    "cancelled_at": null,
    "completed_at": 1699063291,
    "expired_at": null,
    "failed_at": null,
    "last_error": null,
    "step_details": {
        "type": "message_creation",
        "message_creation": {
        "message_id": "msg_abc123"
        }
    }
}
'@
                    $list = '{{"object": "list", "data": [{0}], "first_id": "msg_abc123", "last_id": "msg_abc456", "has_more": false }}'
                    $list -f ([string[]]$msgobj * 20 -join ',')
                }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'List steps.' {
                $InObject = [PSCustomObject]@{
                    id        = 'run_abc123'
                    thread_id = 'thread_abc123'
                }
                { $script:Result = $InObject | Get-ThreadRunStep -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                Should -Invoke Get-ThreadMessage -ModuleName $script:ModuleName
                $Result | Should -HaveCount 20
            }

            It 'Get all steps.' {
                $InObject = [PSCustomObject]@{
                    id        = 'run_abc123'
                    thread_id = 'thread_abc123'
                }
                { $script:Result = $InObject | Get-ThreadRunStep -All -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                Should -Invoke Get-ThreadMessage -ModuleName $script:ModuleName
                $Result | Should -HaveCount 20
            }

            It 'Error on invalid input' {
                $InObject = [datetime]::Today
                { $InObject | Get-ThreadRunStep -ea Stop } | Should -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0
            }
        }
    }
}
