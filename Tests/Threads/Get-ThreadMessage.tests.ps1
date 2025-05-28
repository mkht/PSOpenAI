#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ThreadMessage' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

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
'@ } -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/messages/msg_abc123' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "object": "list",
    "data": [
      {
        "id": "msg_abc123",
        "object": "thread.message",
        "created_at": 1699016383,
        "assistant_id": null,
        "thread_id": "thread_abc123",
        "run_id": null,
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
        "attachments": [],
        "metadata": {}
      },
      {
        "id": "msg_abc456",
        "object": "thread.message",
        "created_at": 1699016383,
        "assistant_id": null,
        "thread_id": "thread_abc123",
        "run_id": null,
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": {
              "value": "Hello, what is AI?",
              "annotations": []
            }
          }
        ],
        "attachments": [],
        "metadata": {}
      }
    ],
    "first_id": "msg_abc123",
    "last_id": "msg_abc456",
    "has_more": false
  }
'@ } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "object": "list",
    "data": [
      {
        "id": "msg_xyz123",
        "object": "thread.message",
        "created_at": 1699016383,
        "assistant_id": null,
        "thread_id": "thread_abc123",
        "run_id": null,
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
        "attachments": [],
        "metadata": {}
      },
      {
        "id": "msg_xyz456",
        "object": "thread.message",
        "created_at": 1699016383,
        "assistant_id": null,
        "thread_id": "thread_abc123",
        "run_id": null,
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": {
              "value": "Hello, what is AI?",
              "annotations": []
            }
          }
        ],
        "attachments": [],
        "metadata": {}
      }
    ],
    "first_id": "msg_abc123",
    "last_id": "msg_abc456",
    "has_more": false
  }
'@ } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' -and $Uri -like '*run_id=run_abc123*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get single thread message with message ID' {
            { $script:Result = Get-ThreadMessage -ThreadId 'thread_abc123' -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/messages/msg_abc123' -eq $Uri }
            $Result.id | Should -BeExactly 'msg_abc123'
            $Result.thread_id | Should -BeExactly 'thread_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.content.type | Should -Be 'text'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Message'
        }

        It 'List thread messages.' {
            { $script:Result = Get-ThreadMessage -ThreadId 'thread_abc123' -All -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeExactly 'msg_abc123'
            $Result[1].id | Should -BeExactly 'msg_abc456'
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Message'
            $Result[1].psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Message'
        }

        It 'List thread messages with run id.' {
            { $script:Result = Get-ThreadMessage -ThreadId 'thread_abc123' -RunId 'run_abc123' -All -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' -and $Uri -like '*run_id=run_abc123*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeExactly 'msg_xyz123'
            $Result[1].id | Should -BeExactly 'msg_xyz456'
            $Result[0].psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Message'
            $Result[1].psobject.TypeNames | Should -Contain 'PSOpenAI.Thread.Message'
        }

        Context 'Parameter Sets' {
            It 'Get_Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Get-ThreadMessage -Thread $InObject -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadMessage $InObject 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadMessage -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/messages/msg_abc123' -eq $Uri }
            }

            It 'Get_ThreadId' {
                # Named
                { Get-ThreadMessage -ThreadId 'thread_abc123' -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadMessage 'thread_abc123' 'msg_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Get-ThreadMessage -MessageId 'msg_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/messages/msg_abc123' -eq $Uri }
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
                { Get-ThreadMessage -Step $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadMessage $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadMessage -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/threads/thread_abc123/messages/msg_abc123' -eq $Uri }
            }

            It 'List_Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Get-ThreadMessage -Thread $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadMessage $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadMessage -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' }
            }

            It 'List_Thread (with RunId)' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Get-ThreadMessage -Thread $InObject -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadMessage $InObject -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadMessage -RunId 'run_abc123' -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' -and $Uri -like '*run_id=run_abc123*' }
            }

            It 'List_ThreadId' {
                # Named
                { Get-ThreadMessage -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadMessage 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Get-ThreadMessage -All -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123' } | Get-ThreadMessage -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' }
            }

            It 'List_ThreadId (with RunId)' {
                # Named
                { Get-ThreadMessage -ThreadId 'thread_abc123' -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadMessage 'thread_abc123' -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Get-ThreadMessage -RunId 'run_abc123' -All -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123' } | Get-ThreadMessage -RunId 'run_abc123' -Limit 5 -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' -and $Uri -like '*run_id=run_abc123*' }
            }

            It 'List_Run' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                }
                # Named
                { Get-ThreadMessage -Run $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ThreadMessage $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ThreadMessage -All -Order desc -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/threads/thread_abc123/messages`?*' -and $Uri -like '*run_id=run_abc123*' }
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext

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

            #Prepare test thread object with 25 messages
            $msgs = [string[]]'Hi' * 25
            $script:thread = New-Thread -Messages $msgs
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterAll {
            $script:thread | Remove-Thread -ea SilentlyContinue
            Clear-OpenAIContext
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
