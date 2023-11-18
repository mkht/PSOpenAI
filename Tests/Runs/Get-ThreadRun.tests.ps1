#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ThreadRun' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        Context 'Get Single Run' {
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
    "model": "gpt-3.5-turbo",
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

            It 'Get a single object with run ID' {
                { $script:Result = Get-ThreadRun -InputObject 'thread_abc123' -RunId 'run_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result.id | Should -BeExactly 'run_abc123'
                $Result.object | Should -BeExactly 'thread.run'
                $Result.created_at | Should -BeOfType [datetime]
                $Result.started_at | Should -BeOfType [datetime]
                $Result.completed_at | Should -BeOfType [datetime]
            }

            It 'Pipeline input' {
                $InObject = [pscustomobject]@{
                    run_id    = 'run_abc123'
                    thread_id = 'thread_abc123'
                }
                { $InObject | Get-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            }
        }

        Context 'List Runs' {
            BeforeAll {
                $script:thread = [PSCustomObject]@{
                    id         = 'thread_abc123'
                    object     = 'thread'
                    created_at = [datetime]::Today
                }
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                    $msgobj = @'
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
    "model": "gpt-3.5-turbo",
    "instructions": null,
    "tools": [],
    "file_ids": []
}
'@
                    $list = '{{"object": "list", "data": [{0}], "first_id": "run_abc123", "last_id": "run_abc456", "has_more": false }}'
                    $list -f ([string[]]$msgobj * 20 -join ',')
                }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'List runs.' {
                { $script:Result = $script:thread | Get-ThreadRun -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 20
            }

            It 'Get all runs.' {
                { $script:Result = $script:thread | Get-ThreadRun -All -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 20
            }

            It 'Error on invalid input' {
                $InObject = [datetime]::Today
                { $InObject | Get-ThreadRun -ea Stop } | Should -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0
            }
        }
    }
}
