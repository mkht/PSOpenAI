#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Stop-Batch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-Batch {
                [pscustomobject]@{
                    'id'           = 'batch_abc123'
                    'created_at'   = [datetime]::Today
                    'status'       = 'cancelled'
                    'cancelled_at' = [datetime]::Today
                }
            }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "batch_abc123",
    "object": "batch",
    "endpoint": "/v1/completions",
    "errors": null,
    "input_file_id": "file-abc123",
    "completion_window": "24h",
    "status": "cancelling",
    "output_file_id": null,
    "error_file_id": null,
    "created_at": 1711471533,
    "in_progress_at": 1711471538,
    "expires_at": 1711557933,
    "finalizing_at": null,
    "completed_at": null,
    "failed_at": null,
    "expired_at": null,
    "cancelling_at": 1711493163,
    "cancelled_at": null,
    "request_counts": {
        "total": 5,
        "completed": 5,
        "failed": 0
    },
    "metadata": {}
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Cancel batch' {
            $InObject = [PSCustomObject]@{
                id     = 'batch_abc123'
                status = 'in_progress'
            }
            { $script:Result = Stop-Batch -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Wait-Batch -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
        }

        It 'Cancel batch (PassThru)' {
            $InObject = [PSCustomObject]@{
                id     = 'batch_abc123'
                status = 'in_progress'
            }
            { $script:Result = Stop-Batch -InputObject $InObject -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Wait-Batch -ModuleName $script:ModuleName
            $Result.id | Should -Be 'batch_abc123'
            $Result.status | Should -Be 'cancelling'
        }

        It 'Cancel run and wait cancelled' {
            $InObject = [PSCustomObject]@{
                id     = 'batch_abc123'
                status = 'in_progress'
            }
            { $script:Result = Stop-Batch -InputObject $InObject -Wait -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-Batch -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        It 'Cancel run and wait cancelled (PassThru)' {
            $InObject = [PSCustomObject]@{
                id     = 'batch_abc123'
                status = 'in_progress'
            }
            { $script:Result = Stop-Batch -InputObject $InObject -Wait -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-Batch -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'batch_abc123'
            $Result.status | Should -Be 'cancelled'
        }

        It 'Error when the run status is not valid' {
            $InObject = [PSCustomObject]@{
                id     = 'batch_abc123'
                status = 'completed'
            }
            { $script:Result = Stop-Batch -InputObject $InObject -ea Stop } | Should -Throw
            Should -Not -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            Should -Not -Invoke Wait-Batch -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
        }

        It 'When the Force is specified, No error even if the run status is not valid' {
            $InObject = [PSCustomObject]@{
                id     = 'batch_abc123'
                status = 'completed'
            }
            { $script:Result = Stop-Batch -InputObject $InObject -Force -PassThru -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Wait-Batch -ModuleName $script:ModuleName
            $Result.id | Should -Be 'batch_abc123'
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Stop-Batch -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Wait-Batch -ModuleName $script:ModuleName -Times 0 -Exactly
        }
    }
}
