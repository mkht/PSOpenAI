#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Stop-ThreadRun' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-ThreadRun {
                [pscustomobject]@{
                    'id'           = 'run_abc123'
                    'object'       = 'thread.run'
                    'created_at'   = [datetime]::Today
                    'assistant_id' = 'asst_abc123'
                    'thread_id'    = 'thread_abc123'
                    'status'       = 'cancelled'
                    'started_at'   = [datetime]::Today
                    'expires_at'   = $null
                    'cancelled_at' = [datetime]::Today
                    'failed_at'    = $null
                    'completed_at' = $null
                    'last_error'   = $null
                    'model'        = 'gpt-4'
                    'instructions' = $null
                }
            }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "run_abc123",
    "object": "thread.run",
    "created_at": 1699063290,
    "assistant_id": "asst_abc123",
    "thread_id": "thread_abc123",
    "status": "cancelling",
    "started_at": 1699063290,
    "expires_at": null,
    "cancelled_at": null,
    "failed_at": null,
    "completed_at": null,
    "last_error": null,
    "model": "gpt-4",
    "instructions": null,
    "tools": [],
    "file_ids": [],
    "metadata": {}
    }
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Cancel run' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'Cancel run (PassThru)' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -InputObject $InObject -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result.id | Should -Be 'run_abc123'
            $Result.thread_id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread.run'
            $Result.status | Should -Be 'cancelling'
        }

        It 'Cancel run and wait cancelled' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -InputObject $InObject -Wait -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'Cancel run and wait cancelled (PassThru)' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -InputObject $InObject -Wait -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'run_abc123'
            $Result.thread_id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread.run'
            $Result.status | Should -Be 'cancelled'
        }

        It 'Error when the run status is not valid' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'completed'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -InputObject $InObject -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'When the Force is specified, No error even if the run status is not valid' {
            $InObject = [PSCustomObject]@{
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'completed'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -InputObject $InObject -Force -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 0 -Exactly
            $Result.id | Should -Be 'run_abc123'
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Stop-ThreadRun -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 0 -Exactly
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
            $script:Run = $script:Thread | Start-ThreadRun -Assistant $script:Assistant
            { $script:Result = $script:Run | Stop-ThreadRun -Force -PassThru -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result.id | Should -Be $script:Run.id
            $Result.thread_id | Should -Be $script:Thread.id
            $Result.assistant_id | Should -BeLike $script:Assistant.id
            $Result.object | Should -Be 'thread.run'
            $Result.status | Should -BeIn @('cancelling', 'cancelled')
        }
    }
}
