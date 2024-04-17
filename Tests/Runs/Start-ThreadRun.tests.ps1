#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Start-ThreadRun' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

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
    "model": "gpt-4",
    "instructions": null,
    "tools": [
        {
        "type": "code_interpreter"
        }
    ],
    "file_ids": [
        "file-abc123",
        "file-abc456"
    ],
    "metadata": {}
    }
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Start thread run with id' {
            { $script:Result = Start-ThreadRun -Thread 'thread_abc123' -Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result.id | Should -BeExactly 'run_abc123'
            $Result.object | Should -BeExactly 'thread.run'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.started_at | Should -BeOfType [datetime]
            $Result.completed_at | Should -BeOfType [datetime]
        }

        It 'Start thread run with object' {
            $thread = [PSCustomObject]@{
                id     = 'thread_abc123'
                object = 'thread'
            }
            $assistant = [PSCustomObject]@{
                id     = 'asst_abc123'
                object = 'assistant'
            }
            { $script:Result = Start-ThreadRun -Thread $thread -Assistant $assistant -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Start thread run without thread' {
            $assistant = [PSCustomObject]@{
                id     = 'asst_abc123'
                object = 'assistant'
            }
            { $script:Result = Start-ThreadRun -Assistant $assistant -Message 'TEST' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result.id | Should -BeExactly 'run_abc123'
            $Result.object | Should -BeExactly 'thread.run'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.started_at | Should -BeOfType [datetime]
            $Result.completed_at | Should -BeOfType [datetime]
        }

        It 'raw_response format' {
            { $script:Result = Start-ThreadRun -Thread 'thread_abc123' -Assistant 'asst_abc123' -Format 'raw_response' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result | Should -BeOfType [string]
        }

        It 'Pipeline input' {
            $thread = [PSCustomObject]@{
                id     = 'thread_abc123'
                object = 'thread'
            }
            $assistant = [PSCustomObject]@{
                id     = 'asst_abc123'
                object = 'assistant'
            }
            { $script:Result = $thread | Start-ThreadRun -Assistant $assistant -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Start-ThreadRun -Assistant 'asst_abc123' -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Assistant | Remove-Assistant -ea SilentlyContinue
            $script:Thread | Remove-Thread -ea SilentlyContinue
        }

        It 'Create thread' {
            $script:Assistant = New-Assistant -Model gpt-3.5-turbo
            $script:Thread = New-Thread | Add-ThreadMessage -Message 'How many people lives in Canada?' -PassThru
            { $params = @{
                    Assistant   = $script:Assistant
                    ErrorAction = 'Stop'
                }
                $script:Result = $script:Thread | Start-ThreadRun @paramss
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'run_*'
            $Result.thread_id | Should -Be $script:Thread.id
            $Result.assistant_id | Should -BeLike $script:Assistant.id
            $Result.object | Should -Be 'thread.run'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeIn @('queued', 'in_progress', 'completed')
        }
    }
}
