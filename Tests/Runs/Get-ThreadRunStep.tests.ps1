#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ThreadRunStep' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadMessage {
                [PSCustomObject]@{
                    PSTypeName   = 'PSOpenAI.Thread.Message'
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
'@ } -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps/step_abc123' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "object": "list",
    "data": [
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
        },
        {
            "id": "step_abc456",
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
    ],
    "first_id": "step_abc123",
    "last_id": "step_abc456",
    "has_more": false
}
'@ } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps`?*' }
        }

        BeforeEach {
            $script:Result = ''
        }



        It 'Get a single run step object with ID' {
            { $script:Result = Get-ThreadRunStep -RunId 'run_abc123' -ThreadId 'thread_abc123' -StepId 'step_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps/step_abc123' -eq $Uri }
            Should -Invoke Get-ThreadMessage -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -BeExactly 'step_abc123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run.Step'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.completed_at | Should -BeOfType [datetime]
            $Result.SimpleContent.role | Should -Be 'assistant'
            $Result.SimpleContent.type | Should -Be 'text'
            $Result.SimpleContent.content | Should -Be 'Hi! How can I help you today?'
        }

        It 'List run steps' {
            { $script:Result = Get-ThreadRunStep -RunId 'run_abc123' -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps`?*' }
            Should -Invoke Get-ThreadMessage -ModuleName $script:ModuleName -Times 2 -Exactly
            $Result.GetType().Fullname | Should -Be 'System.Object[]'
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeExactly 'step_abc123'
            $Result[1].id | Should -BeExactly 'step_abc456'
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run.Step'
            $Result[0].created_at | Should -BeOfType [datetime]
            $Result[0].completed_at | Should -BeOfType [datetime]
            $Result[0].SimpleContent.role | Should -Be 'assistant'
            $Result[0].SimpleContent.type | Should -Be 'text'
            $Result[0].SimpleContent.content | Should -Be 'Hi! How can I help you today?'
        }

        It 'Warn when the run step object has error messages' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "step_warn123",
    "object": "thread.run.step",
    "created_at": 1699063291,
    "run_id": "run_warn123",
    "assistant_id": "asst_warn123",
    "thread_id": "thread_warn123",
    "type": "message_creation",
    "status": "failed",
    "last_error": {"code": "server_error", "message": "TEST ERROR"},
    "step_details": null
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/threads/thread_warn123/runs/run_warn123/steps/step_warn123' -eq $Uri }
            $script:Warn = $null
            { $script:Result = Get-ThreadRunStep -RunId 'run_warn123' -ThreadId 'thread_warn123' -StepId 'step_warn123' -ea Stop -wv Warn1; $script:Warn = $Warn1 } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -Scope It
            $Result.id | Should -BeExactly 'step_warn123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run.Step'
            $script:Warn[0].Message | Should -Match 'TEST ERROR'
        }

        Context 'Parameter Sets' {
            It 'Get_Run' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                }
                # Named
                { Get-ThreadRunStep -Run $InObject -StepId 'step_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRunStep $InObject 'step_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadRunStep -StepId 'step_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps/step_abc123' -eq $Uri }
            }

            It 'Get_RunId' {
                # Named
                { Get-ThreadRunStep -RunId 'run_abc123' -ThreadId 'thread_abc123' -StepId 'step_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRunStep 'run_abc123' 'thread_abc123' 'step_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'run_abc123' | Get-ThreadRunStep -ThreadId 'thread_abc123' -StepId 'step_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123'; run_id = 'run_abc123'; step_id = 'step_abc123' } | Get-ThreadRunStep -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps/step_abc123' -eq $Uri }
            }

            It 'Get_RunStep' {
                $InObject = [pscustomobject]@{
                    PSTypeName   = 'PSOpenAI.Thread.Run.Step'
                    id           = 'step_abc123'
                    run_id       = 'run_abc123'
                    thread_id    = 'thread_abc123'
                    step_details = @{
                        type             = 'message_creation'
                        message_creation = @{message_id = 'msg_abc123' }
                    }
                }
                # Named
                { Get-ThreadRunStep -Step $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRunStep $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadRunStep -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps/step_abc123' -eq $Uri }
            }

            It 'List_Run' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                }
                # Named
                { Get-ThreadRunStep -Run $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRunStep $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadRunStep -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps`?*' }
            }

            It 'List_RunId' {
                # Named
                { Get-ThreadRunStep -RunId 'run_abc123' -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRunStep 'run_abc123' 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'run_abc123' | Get-ThreadRunStep -ThreadId 'thread_abc123' -All -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{run_id = 'run_abc123'; thread_id = 'thread_abc123' } | Get-ThreadRunStep -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123/steps`?*' }
            }
        }
    }
}
