#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Start-Batch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -Verifiable -ModuleName $script:ModuleName Add-OpenAIFile {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
            }
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
            Should -Not -Invoke -CommandName Add-OpenAIFile -ModuleName $script:ModuleName
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'batch_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'validating'
        }

        It 'Start batch with input objects' {
            $BatchInputs = @(
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Batch.Input'
                    'custom_id' = 'custom-1'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-4o-mini' }
                },
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Batch.Input'
                    'custom_id' = 'custom-2'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-4o-mini' }
                }
            )
            { $script:Result = Start-Batch -InputObject $BatchInputs -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke -CommandName Add-OpenAIFile -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'batch_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'validating'
        }

        It 'Start batch with input objects (pipeline input)' {
            $BatchInputs = @(
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Batch.Input'
                    'custom_id' = 'custom-1'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-4o-mini' }
                },
                [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Batch.Input'
                    'custom_id' = 'custom-2'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-4o-mini' }
                }
            )
            { $script:Result = $BatchInputs | Start-Batch -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke -CommandName Add-OpenAIFile -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'batch_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'validating'
        }

        It 'Input file object should not mulitple.' {
            $InputFiles = @(
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                },
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc456'
                }
            )
            { Start-Batch -File $InputFiles -ea Stop } | Should -Throw
        }

        Context 'Parameter Sets' {
            It 'File' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                # Named
                { Start-Batch -File $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Start-Batch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Start-Batch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Start-Batch -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Start-Batch 'file-abc123'-ea Stop } | Should -Not -Throw
                # Pipeline
                { 'file-abc123' | Start-Batch -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{input_file_id = 'file-abc123' } | Start-Batch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'BatchObject (Single)' {
                $InObject = [pscustomobject]@{
                    PSTypeName  = 'PSOpenAI.Batch.Input'
                    'custom_id' = 'custom-1'
                    'method'    = 'POST'
                    'url'       = '/v1/chat/completions'
                    'body'      = [pscustomobject]@{'model' = 'gpt-4o-mini' }
                }
                # Named
                { Start-Batch -BatchInput $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Start-Batch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Start-Batch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'BatchObject (Multiple)' {
                $InObject = @(
                    [pscustomobject]@{
                        PSTypeName  = 'PSOpenAI.Batch.Input'
                        'custom_id' = 'custom-1'
                        'method'    = 'POST'
                        'url'       = '/v1/chat/completions'
                        'body'      = [pscustomobject]@{'model' = 'gpt-4o-mini' }
                    },
                    [pscustomobject]@{
                        PSTypeName  = 'PSOpenAI.Batch.Input'
                        'custom_id' = 'custom-2'
                        'method'    = 'POST'
                        'url'       = '/v1/chat/completions'
                        'body'      = [pscustomobject]@{'model' = 'gpt-4o-mini' }
                    },
                    [pscustomobject]@{
                        PSTypeName  = 'PSOpenAI.Batch.Input'
                        'custom_id' = 'custom-3'
                        'method'    = 'POST'
                        'url'       = '/v1/chat/completions'
                        'body'      = [pscustomobject]@{'model' = 'gpt-4o-mini' }
                    }
                )
                # Named
                { Start-Batch -BatchInput $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Start-Batch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Start-Batch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
