#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ThreadRun' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "run_abc123",
    "object": "thread.run",
    "created_at": 1699075072,
    "assistant_id": "asst_abc123",
    "thread_id": "thread_abc123",
    "status": "completed",
    "started_at": 1699075072,
    "expires_at": null,
    "cancelled_at": null,
    "failed_at": null,
    "completed_at": 1699075073,
    "last_error": null,
    "model": "gpt-4-turbo",
    "instructions": null,
    "incomplete_details": null,
    "tools": [
        {
        "type": "code_interpreter"
        }
    ],
    "metadata": {},
    "usage": {
        "prompt_tokens": 123,
        "completion_tokens": 456,
        "total_tokens": 579
    },
    "temperature": 1.0,
    "top_p": 1.0,
    "max_prompt_tokens": 1000,
    "max_completion_tokens": 1000,
    "truncation_strategy": {
        "type": "auto",
        "last_messages": null
    },
    "response_format": "auto",
    "tool_choice": "auto"
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "object": "list",
    "data": [
        {
        "id": "run_abc123",
        "object": "thread.run",
        "created_at": 1699075072,
        "assistant_id": "asst_abc123",
        "thread_id": "thread_abc123",
        "status": "completed",
        "started_at": 1699075072,
        "expires_at": null,
        "cancelled_at": null,
        "failed_at": null,
        "completed_at": 1699075073,
        "last_error": null,
        "model": "gpt-4-turbo",
        "instructions": null,
        "incomplete_details": null,
        "metadata": {}
        },
        {
        "id": "run_abc456",
        "object": "thread.run",
        "created_at": 1699063290,
        "assistant_id": "asst_abc123",
        "thread_id": "thread_abc123",
        "status": "completed",
        "started_at": 1699063290,
        "expires_at": null,
        "cancelled_at": null,
        "failed_at": null,
        "completed_at": 1699063291,
        "last_error": null,
        "model": "gpt-4-turbo",
        "instructions": null,
        "incomplete_details": null,
        "metadata": {}
        }
    ],
    "first_id": "run_abc123",
    "last_id": "run_abc456",
    "has_more": false
}
'@
            } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/runs`?*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List thread run objects' {
            { $script:Result = Get-ThreadRun -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/runs`?*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeLike 'run_abc*'
            $Result[1].id | Should -BeLike 'run_abc*'
            $Result[0].created_at | Should -BeOfType [datetime]
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
        }

        It 'Get single thread run object' {
            { $script:Result = Get-ThreadRun -ThreadId 'thread_abc123' -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123' -eq $Uri }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'run_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
        }

        It 'Warn when the run object has error messages' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "run_warn123",
    "object": "thread.run",
    "created_at": 1698107661,
    "assistant_id": "asst_warn123",
    "thread_id": "thread_warn123",
    "status": "failed",
    "failed_at": 1699073498,
    "last_error": {"code": "invalid_prompt", "message": "TEST ERROR"},
    "model": "gpt-4o-mini",
    "incomplete_details": null
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/threads/thread_warn123/runs/run_warn123' -eq $Uri }
            $script:Warn = $null
            { $script:Result = Get-ThreadRun -ThreadId 'thread_warn123' -RunId 'run_warn123' -ea Stop -wv Warn1; $script:Warn = $Warn1 } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -Scope It
            $Result | Should -BeOfType [pscustomobject]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
            $script:Warn[0].Message | Should -Match 'TEST ERROR'
        }

        It 'Warn when the run object has incomplete messages' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "run_warn456",
    "object": "thread.run",
    "created_at": 1698107661,
    "assistant_id": "asst_warn456",
    "thread_id": "thread_warn456",
    "status": "incomplete",
    "failed_at": null,
    "last_error": null,
    "incomplete_details": {"reason": "TEST INCOMPLETE"},
    "model": "gpt-4o-mini"
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/threads/thread_warn456/runs/run_warn456' -eq $Uri }
            $script:Warn = $null
            { $script:Result = Get-ThreadRun -ThreadId 'thread_warn456' -RunId 'run_warn456' -ea Stop -wv Warn1; $script:Warn = $Warn1 } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -Scope It
            $Result | Should -BeOfType [pscustomobject]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
            $script:Warn[0].Message | Should -Match 'TEST INCOMPLETE'
        }

        Context 'Parameter Sets' {
            It 'Get_Id' {
                # Named
                { Get-ThreadRun -ThreadId 'thread_abc123' -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRun 'thread_abc123' 'run_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Get-ThreadRun -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123'; run_id = 'run_abc123' } | Get-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123' -eq $Uri }
            }

            It 'List_Id' {
                # Named
                { Get-ThreadRun -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRun 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Get-ThreadRun -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123' } | Get-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/runs`?*' }
            }

            It 'Get_Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Get-ThreadRun -Thread $InObject -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRun $InObject 'run_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadRun -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123' -eq $Uri }
            }

            It 'List_Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Get-ThreadRun -Thread $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRun $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/runs`?*' }
            }

            It 'Get_ThreadRun' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                }
                # Named
                { Get-ThreadRun -Run $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadRun $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs/run_abc123' -eq $Uri }
            }
        }
    }
}
