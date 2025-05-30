#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Start-ThreadRun' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        Context 'Create run' {

            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "run_abc123",
    "object": "thread.run",
    "created_at": 1699063290,
    "assistant_id": "asst_abc123",
    "thread_id": "thread_abc123",
    "status": "queued",
    "started_at": 1699063290,
    "expires_at": null,
    "cancelled_at": null,
    "failed_at": null,
    "completed_at": 1699063291,
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
    "usage": null,
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
'@ } -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs' -eq $uri }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Start thread run with thread id' {
                { $script:Result = Start-ThreadRun -ThreadId 'thread_abc123' -AssistantId 'asst_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs' -eq $uri }
                $Result.id | Should -BeExactly 'run_abc123'
                $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
                $Result.created_at | Should -BeOfType [datetime]
                $Result.started_at | Should -BeOfType [datetime]
                $Result.completed_at | Should -BeOfType [datetime]
                $Result.status | Should -Be 'queued'
            }

            It 'Start thread run with object' {
                $thread = [PSCustomObject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                    object     = 'thread'
                }
                $assistant = [PSCustomObject]@{
                    PSTypeName = 'PSOpenAI.Assistant'
                    id         = 'asst_abc123'
                    object     = 'assistant'
                }
                { $script:Result = Start-ThreadRun -Thread $thread -Assistant $assistant -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs' -eq $uri }
                $Result.id | Should -BeExactly 'run_abc123'
                $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
                $Result.created_at | Should -BeOfType [datetime]
                $Result.started_at | Should -BeOfType [datetime]
                $Result.completed_at | Should -BeOfType [datetime]
                $Result.status | Should -Be 'queued'
            }

            It 'More parameters' {
                $params = @{
                    ThreadId               = 'thread_abc123'
                    AssistantId            = 'asst_abc123'
                    Model                  = 'gpt-4-turbo'
                    Instructions           = 'You are a math teacher.'
                    AdditionalInstructions = 'Your name is Kojima.'
                    AdditionalMessages     = @(
                        @{role = 'user'; content = 'Kojima-sensei. I could not solve this question.' }
                    )
                    MaxCompletionTokens    = 1024
                    Temperature            = 1.4
                }
                { $script:Result = Start-ThreadRun @params -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs' -eq $uri }
                $Result.id | Should -BeExactly 'run_abc123'
                $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
            }

            It 'raw_response format' {
                { $script:Result = Start-ThreadRun -ThreadId 'thread_abc123' -Assistant 'asst_abc123' -Format 'raw_response' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs' -eq $uri }
                $Result | Should -BeOfType [string]
            }
        }

        Context 'Create thread and run' {

            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "run_abc123",
    "object": "thread.run",
    "created_at": 1699076792,
    "assistant_id": "asst_abc123",
    "thread_id": "thread_abc123",
    "status": "queued",
    "started_at": null,
    "expires_at": 1699077392,
    "cancelled_at": null,
    "failed_at": null,
    "completed_at": null,
    "required_action": null,
    "last_error": null,
    "model": "gpt-4-turbo",
    "instructions": "You are a helpful assistant.",
    "tools": [],
    "tool_resources": {},
    "metadata": {},
    "temperature": 1.0,
    "top_p": 1.0,
    "max_completion_tokens": null,
    "max_prompt_tokens": null,
    "truncation_strategy": {
        "type": "auto",
        "last_messages": null
    },
    "incomplete_details": null,
    "usage": null,
    "response_format": "auto",
    "tool_choice": "auto"
}
'@ } -ParameterFilter { 'https://api.openai.com/v1/threads/runs' -eq $uri }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Start thread and run' {
                { $script:Result = Start-ThreadRun -Message 'Hello' -AssistantId 'asst_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/runs' -eq $uri }
                $Result.id | Should -BeExactly 'run_abc123'
                $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
                $Result.created_at | Should -BeOfType [datetime]
                $Result.status | Should -Be 'queued'
            }

            It 'More parameters' {
                $params = @{
                    Message             = 'Please teach me again.'
                    AssistantId         = 'asst_abc123'
                    Model               = 'gpt-4-turbo'
                    Instructions        = 'You are a math teacher.'
                    AdditionalMessages  = @(
                        @{role = 'user'; content = 'Kojima-sensei. I could not solve this question.' }
                        @{role = 'assistant'; content = 'Have you tried using the formula I taught in class yesterday?' }
                    )
                    MaxCompletionTokens = 1024
                    Temperature         = 1.4
                }
                { $script:Result = Start-ThreadRun @params -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/runs' -eq $uri }
                $Result.id | Should -BeExactly 'run_abc123'
                $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Run'
            }

            It 'raw_response format' {
                { $script:Result = Start-ThreadRun -Message 'Hello' -Assistant 'asst_abc123' -Format 'raw_response' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/runs' -eq $uri }
                $Result | Should -BeOfType [string]
            }
        }

        Context 'Stream' {

            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE { @'
{
    "id":"msg_123",
    "object":"thread.message.delta",
    "delta":{
        "content": [
        {
            "index": 0,
            "type": "text",
            "text": { "value": "Hello", "annotations": [] }
        }
        ]
    }
}
'@
                    @'
{
    "id":"msg_123",
    "object":"thread.message.delta",
    "delta":{
        "content": [
        {
            "index": 0,
            "type": "text",
            "text": { "value": "How", "annotations": [] }
        }
        ]
    }
}
'@
                }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Streaming' {
                { $script:Result = Start-ThreadRun -ThreadId 'thread_abc123' -AssistantId 'asst_abc123' -Stream -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result | Should -HaveCount 2
                $Result[0] | Should -Be 'Hello'
                $Result[1] | Should -Be 'How'
            }

            It 'More parameters' {
                $params = @{
                    Message             = 'Please teach me again.'
                    AssistantId         = 'asst_abc123'
                    Model               = 'gpt-4-turbo'
                    Instructions        = 'You are a math teacher.'
                    AdditionalMessages  = @(
                        @{role = 'user'; content = 'Kojima-sensei. I could not solve this question.' }
                        @{role = 'assistant'; content = 'Have you tried using the formula I taught in class yesterday?' }
                    )
                    MaxCompletionTokens = 1024
                    Temperature         = 1.4
                    Stream              = $true
                }
                { $script:Result = Start-ThreadRun @params -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result | Should -HaveCount 2
                $Result[0] | Should -Be 'Hello'
                $Result[1] | Should -Be 'How'
            }

            It 'raw_response format' {
                { $script:Result = Start-ThreadRun -Message 'Hello' -Assistant 'asst_abc123' -Format 'raw_response' -Stream -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
                $Result | Should -HaveCount 2
                $Result[0] | Should -Match '"id":"msg_123"'
                $Result[0] | Should -Match '"id":"msg_123"'
            }
        }

        Context 'Parameter Sets' {
            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {}
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Run_Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Start-ThreadRun -Thread $InObject -Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Start-ThreadRun $InObject -Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Start-ThreadRun -Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs' -eq $uri }
            }

            It 'Run_ThreadId' {
                # Named
                { Start-ThreadRun -ThreadId 'thread_abc123' -Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                # Position
                { Start-ThreadRun 'thread_abc123' -Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Start-ThreadRun -Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{thread_id = 'thread_abc123'; assistant_id = 'asst_abc123' } | Start-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/runs' -eq $uri }
            }

            It 'ThreadAndRun' {
                # Named
                { Start-ThreadRun -Message 'Hello' -Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/runs' -eq $uri }
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext
            $script:Assistant = New-Assistant -Model gpt-4o-mini
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Thread | Remove-Thread -ea SilentlyContinue
            $script:Thread = $null
        }

        AfterAll {
            $script:Assistant | Remove-Assistant -ea SilentlyContinue
        }

        It 'Start run' {
            $script:Thread = New-Thread | Add-ThreadMessage -Message 'How many people lives in Canada?' -PassThru
            {
                $script:Result = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -TimeoutSec 40 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'run_*'
            $Result.thread_id | Should -Be $script:Thread.id
            $Result.assistant_id | Should -BeLike $script:Assistant.id
            $Result.object | Should -Be 'thread.run'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeIn @('queued', 'in_progress', 'completed')
        }

        It 'Start run (Stream)' {
            $script:Thread = New-Thread | Add-ThreadMessage -Message 'How many people lives in Canada?' -PassThru
            {
                $script:Result = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -Stream -TimeoutSec 40 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Result.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Count | Should -BeGreaterOrEqual 1
            $Result[0] | Should -BeOfType [string]
        }

        It 'Start thread and run' {
            $params = @{
                Message             = 'Please teach me again.'
                Assistant           = $script:Assistant
                Instructions        = 'You are a math teacher. Your name is kojima.'
                AdditionalMessages  = @(
                    @{role = 'user'; content = 'Kojima-sensei. I could not solve this question.' }
                    @{role = 'assistant'; content = 'Have you tried using the quadratic formula I taught in class yesterday?' }
                )
                MaxCompletionTokens = 256
                Temperature         = 0
            }
            {
                $script:Result = Start-ThreadRun @params -TimeoutSec 40 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'run_*'
            $Result.thread_id | Should -BeLike 'thread_*'
            $Result.assistant_id | Should -BeLike $script:Assistant.id
            $Result.object | Should -Be 'thread.run'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeIn @('queued', 'in_progress', 'completed')
        }

        It 'Start thread and run (Stream)' {
            $params = @{
                Message             = "Kojima-sensei. Why can't numbers be divided by zero?"
                Assistant           = $script:Assistant
                Instructions        = 'You are a math teacher. Your name is kojima.'
                MaxCompletionTokens = 256
                Temperature         = 0
                ToolChoice          = 'none'
                Stream              = $true
            }
            {
                $script:Result = Start-ThreadRun @params -TimeoutSec 200 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Result.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Count | Should -BeGreaterOrEqual 1
            $Result[0] | Should -BeOfType [string]
        }
    }

    Context 'Integration tests (Azure)' -Tag 'Azure' {

        BeforeAll {
            # Set Context for Azure OpenAI
            $AzureContext = @{
                ApiType    = 'Azure'
                AuthType   = 'Azure'
                ApiKey     = $env:AZURE_OPENAI_API_KEY
                ApiBase    = $env:AZURE_OPENAI_ENDPOINT
                TimeoutSec = 30
            }
            Set-OpenAIContext @AzureContext

            $script:Model = 'gpt-4o-mini'

            $script:Assistant = New-Assistant -Model $script:Model
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Thread | Remove-Thread -ea SilentlyContinue
            $script:Thread = $null
        }

        AfterAll {
            $script:Assistant | Remove-Assistant -ea SilentlyContinue
            Clear-OpenAIContext
        }

        It 'Start run' {
            $script:Thread = New-Thread | Add-ThreadMessage -Message 'How many people lives in Antarctic?' -PassThru
            {
                $script:Result = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -TimeoutSec 40 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'run_*'
            $Result.thread_id | Should -Be $script:Thread.id
            $Result.assistant_id | Should -BeLike $script:Assistant.id
            $Result.object | Should -Be 'thread.run'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeIn @('queued', 'in_progress', 'completed')
        }

        It 'Start run (Stream)' {
            $script:Thread = New-Thread | Add-ThreadMessage -Message 'How many people lives in Antarctic?' -PassThru
            {
                $script:Result = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -Stream -TimeoutSec 40 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Result.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Count | Should -BeGreaterOrEqual 1
            $Result[0] | Should -BeOfType [string]
        }

        It 'Start thread and run' {
            $params = @{
                Message             = 'Please teach me again.'
                Assistant           = $script:Assistant
                Instructions        = 'You are a math teacher. Your name is kojima.'
                AdditionalMessages  = @(
                    @{role = 'user'; content = 'Kojima-sensei. I could not solve this question.' }
                    @{role = 'assistant'; content = 'Have you tried using the quadratic formula I taught in class yesterday?' }
                )
                MaxCompletionTokens = 256
                Temperature         = 0
            }
            {
                $script:Result = Start-ThreadRun @params -TimeoutSec 40 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'run_*'
            $Result.thread_id | Should -BeLike 'thread_*'
            $Result.assistant_id | Should -BeLike $script:Assistant.id
            $Result.object | Should -Be 'thread.run'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeIn @('queued', 'in_progress', 'completed')
        }

        It 'Start thread and run (Stream)' {
            $params = @{
                Message             = "Kojima-sensei. Why can't numbers be divided by zero?"
                Assistant           = $script:Assistant
                Instructions        = 'You are a math teacher. Your name is kojima.'
                MaxCompletionTokens = 256
                Temperature         = 0
                ToolChoice          = 'none'
                Stream              = $true
            }
            {
                $script:Result = Start-ThreadRun @params -TimeoutSec 200 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Result.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Count | Should -BeGreaterOrEqual 1
            $Result[0] | Should -BeOfType [string]
        }
    }
}
