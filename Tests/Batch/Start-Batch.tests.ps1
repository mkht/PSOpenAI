#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Start-Batch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -Verifiable -ModuleName $script:ModuleName Register-OpenAIFile { @{id = 'file-abc123' } }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "batch_abc123",
    "object": "batch",
    "endpoint": "/v1/completions",
    "errors": null,
    "input_file_id": "file-abc123",
    "completion_window": "24h",
    "status": "validating",
    "output_file_id": null,
    "error_file_id": null,
    "created_at": 1711471533,
    "in_progress_at": null,
    "expires_at": null,
    "finalizing_at": null,
    "completed_at": null,
    "failed_at": null,
    "expired_at": null,
    "cancelling_at": null,
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

        It 'Start batch with file_input_id' {
            { $script:Result = Start-Batch -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke -CommandName Register-OpenAIFile -ModuleName $script:ModuleName
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'batch_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'validating'
        }

        It 'Start batch with input objects' {
            $BatchInputs = @(
                [pscustomobject]@{
                    'custom_id' = 'custom-1'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-3.5-turbo' }
                },
                [pscustomobject]@{
                    'custom_id' = 'custom-2'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-3.5-turbo' }
                }
            )
            { $script:Result = Start-Batch -InputObject $BatchInputs -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke -CommandName Register-OpenAIFile -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'batch_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'validating'
        }

        It 'Start batch with input objects (pipeline input)' {
            $BatchInputs = @(
                [pscustomobject]@{
                    'custom_id' = 'custom-1'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-3.5-turbo' }
                },
                [pscustomobject]@{
                    'custom_id' = 'custom-2'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-3.5-turbo' }
                }
            )
            { $script:Result = $BatchInputs | Start-Batch -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke -CommandName Register-OpenAIFile -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'batch_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'validating'
        }
    }
}
