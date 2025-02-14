#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Stop-ThreadRun' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-ThreadRun {
                [pscustomobject]@{
                    PSTypeName     = 'PSOpenAI.Thread.Run'
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
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    PSTypeName     = 'PSOpenAI.Thread.Run'
                    'id'           = 'run_abc123'
                    'object'       = 'thread.run'
                    'created_at'   = [datetime]::Today
                    'assistant_id' = 'asst_abc123'
                    'thread_id'    = 'thread_abc123'
                    'status'       = 'in_progress'
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
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -Run $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Get-ThreadRun -ModuleName $script:ModuleName
            Should -Not -Invoke Wait-ThreadRun -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
        }

        It 'Cancel run (PassThru)' {
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -Run $InObject -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Get-ThreadRun -ModuleName $script:ModuleName
            Should -Not -Invoke Wait-ThreadRun -ModuleName $script:ModuleName
            $Result.id | Should -Be 'run_abc123'
            $Result.thread_id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread.run'
            $Result.status | Should -Be 'cancelling'
        }

        It 'Cancel run and wait cancelled' {
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -Run $InObject -Wait -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Get-ThreadRun -ModuleName $script:ModuleName
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'Cancel run and wait cancelled (PassThru)' {
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'in_progress'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -Run $InObject -Wait -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Get-ThreadRun -ModuleName $script:ModuleName
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'run_abc123'
            $Result.thread_id | Should -Be 'thread_abc123'
            $Result.object | Should -Be 'thread.run'
            $Result.status | Should -Be 'cancelled'
        }

        It 'Error when the run status is not valid' {
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'completed'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -Run $InObject -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Not -Invoke Get-ThreadRun -ModuleName $script:ModuleName
            Should -Not -Invoke Wait-ThreadRun -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
        }

        It 'When the Force is specified, No error even if the run status is not valid' {
            $InObject = [PSCustomObject]@{
                PSTypeName = 'PSOpenAI.Thread.Run'
                id         = 'run_abc123'
                thread_id  = 'thread_abc123'
                object     = 'thread.run'
                status     = 'completed'
                started_at = [datetime]::Today
            }
            { $script:Result = Stop-ThreadRun -InputObject $InObject -Force -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Get-ThreadRun -ModuleName $script:ModuleName
            Should -Not -Invoke Wait-ThreadRun -ModuleName $script:ModuleName
            $Result.id | Should -Be 'run_abc123'
        }

        Context 'Parameter Sets' {
            It 'Run' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                    status     = 'in_progress'
                }
                # Named
                { Stop-ThreadRun -Run $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Stop-ThreadRun $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Stop-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
                Should -Not -Invoke Get-ThreadRun -ModuleName $script:ModuleName
                Should -Not -Invoke Wait-ThreadRun -ModuleName $script:ModuleName
            }

            It 'Id' {
                # Named
                { Stop-ThreadRun -RunId 'run_abc123' -ThreadId 'thread_abc123' -Wait -ea Stop } | Should -Not -Throw
                # Positional
                { Stop-ThreadRun 'run_abc123' 'thread_abc123' -Wait -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'run_abc123' | Stop-ThreadRun -ThreadId 'thread_abc123' -Wait -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123'; run_id = 'run_abc123' } | Stop-ThreadRun -Wait -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
                Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 4 -Exactly
                Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 4 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Assistant | Remove-Assistant -ea SilentlyContinue
            $script:Thread | Remove-Thread -ea SilentlyContinue
        }

        It 'Create thread, then cancel it' {
            $script:Assistant = New-Assistant -Model gpt-4o-mini
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
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Assistant | Remove-Assistant -ea SilentlyContinue
            $script:Thread | Remove-Thread -ea SilentlyContinue
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'Create thread, then cancel it' {
            $script:Assistant = New-Assistant -Model $script:Model
            $script:Thread = New-Thread | Add-ThreadMessage -Message 'How many people lives in China?' -PassThru
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
