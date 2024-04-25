#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-BatchOutput' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                [pscustomobject]@{id = 'batch_incomplete'; output_file_id = $null; status = 'in_progress' }
            } -ParameterFilter { $BatchId -eq 'batch_incomplete' }
            Mock -Verifiable -ModuleName $script:ModuleName Get-Batch {
                [pscustomobject]@{id = 'batch_completed'; output_file_id = 'file-abc123'; status = 'completed' }
            } -ParameterFilter { $BatchId -eq 'batch_completed' }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-Batch { [pscustomobject]@{id = 'batch_abc123'; output_file_id = 'file-abc123' } }
            Mock -Verifiable -ModuleName $script:ModuleName Get-OpenAIFileContent { $s = @'
            {"id": "batch_req_abc123", "custom_id": "request-3", "response": {"status_code": 200, "request_id": "b9deb0", "body": {"id": "chatcmpl-9GTV", "object": "chat.completion", "created": 1713713704, "model": "gpt-3.5-turbo-0125", "choices": [{"index": 0, "message": {"role": "assistant", "content": "AWS stands for Amazon Web Services."}, "logprobs": null, "finish_reason": "stop"}], "usage": {"prompt_tokens": 12, "completion_tokens": 70, "total_tokens": 82}, "system_fingerprint": "fp_123"}}, "error": null}
            {"id": "batch_req_abc456", "custom_id": "request-1", "response": {"status_code": 200, "request_id": "d4f362", "body": {"id": "chatcmpl-mOVq", "object": "chat.completion", "created": 1713713704, "model": "gpt-3.5-turbo-0125", "choices": [{"index": 0, "message": {"role": "assistant", "content": "\u306f\u3058\u3081\u307e\u3057"}, "logprobs": null, "finish_reason": "stop"}], "usage": {"prompt_tokens": 28, "completion_tokens": 78, "total_tokens": 106}, "system_fingerprint": "fp_c22"}}, "error": null}
            {"id": "batch_req_abc789", "custom_id": "request-2", "response": {"status_code": 200, "request_id": "20a0f", "body": {"id": "chatcmpl-FQDj", "object": "chat.completion", "created": 1713713704, "model": "gpt-3.5-turbo-0125", "choices": [{"index": 0, "message": {"role": "assistant", "content": "Good night! Have a restful sleep."}, "logprobs": null, "finish_reason": "stop"}], "usage": {"prompt_tokens": 10, "completion_tokens": 9, "total_tokens": 19}, "system_fingerprint": "fp_95e7"}}, "error": null}

'@
                [System.Text.Encoding]::UTF8.GetBytes($s)
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get output from completed batch' {
            $In = [pscustomobject]@{
                id             = 'batch_completed'
                output_file_id = 'file-abc123'
                status         = 'completed'
            }
            { $script:Result = Get-BatchOutput -InputObject $In -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Get-OpenAIFileContent -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke -CommandName Wait-Batch -ModuleName $script:ModuleName
            Should -Not -Invoke -CommandName Get-Batch -ModuleName $script:ModuleName
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [pscustomobject]
            $Result[0].id | Should -BeLike 'batch_req_abc*'
            $Result[0].response.body.created | Should -BeOfType [datetime]
        }

        It 'Get output from completed batch (pipeline input)' {
            $In = [pscustomobject]@{
                id             = 'batch_completed'
                output_file_id = 'file-abc123'
                status         = 'completed'
            }
            { $script:Result = $In | Get-BatchOutput -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Get-OpenAIFileContent -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke -CommandName Wait-Batch -ModuleName $script:ModuleName
            Should -Not -Invoke -CommandName Get-Batch -ModuleName $script:ModuleName
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [pscustomobject]
            $Result[0].id | Should -BeLike 'batch_req_abc*'
            $Result[0].response.body.created | Should -BeOfType [datetime]
        }

        It 'Get output from completed batch (with -Wait)' {
            $In = [pscustomobject]@{
                id             = 'batch_completed'
                output_file_id = 'file-abc123'
                status         = 'completed'
            }
            { $script:Result = Get-BatchOutput -InputObject $In -Wait -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Get-OpenAIFileContent -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke -CommandName Wait-Batch -ModuleName $script:ModuleName
            Should -Not -Invoke -CommandName Get-Batch -ModuleName $script:ModuleName
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [pscustomobject]
            $Result[0].id | Should -BeLike 'batch_req_abc*'
            $Result[0].response.body.created | Should -BeOfType [datetime]
        }

        It 'Throw Error when the batch is not completed. (Without -Wait)' {
            $In = [pscustomobject]@{
                id             = 'batch_incomplete'
                output_file_id = $null
                status         = 'in_progress'
            }
            { $script:Result = Get-BatchOutput -InputObject $In -ea Stop } | Should -Throw
            Should -Not -Invoke -CommandName Get-OpenAIFileContent -ModuleName $script:ModuleName
            Should -Not -Invoke -CommandName Wait-Batch -ModuleName $script:ModuleName
            Should -Invoke -CommandName Get-Batch -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $BatchId -eq 'batch_incomplete' }
            $Result | Should -BeNullOrEmpty
        }

        It 'No Error when the batch is done on the server. (Without -Wait)' {
            $In = [pscustomobject]@{
                id             = 'batch_completed'
                output_file_id = $null
                status         = 'in_progress'
            }
            { $script:Result = Get-BatchOutput -InputObject $In -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Get-OpenAIFileContent -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke -CommandName Wait-Batch -ModuleName $script:ModuleName
            Should -Invoke -CommandName Get-Batch -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $BatchId -eq 'batch_completed' }
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [pscustomobject]
            $Result[0].id | Should -BeLike 'batch_req_abc*'
            $Result[0].response.body.created | Should -BeOfType [datetime]
        }

        It 'Wait until the batch completion. (with -Wait)' {
            $In = [pscustomobject]@{
                id             = 'batch_incomplete'
                output_file_id = $null
                status         = 'in_progress'
            }
            { $script:Result = Get-BatchOutput -InputObject $In -Wait -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Get-OpenAIFileContent -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke -CommandName Wait-Batch -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke -CommandName Get-Batch -ModuleName $script:ModuleName
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [pscustomobject]
            $Result[0].id | Should -BeLike 'batch_req_abc*'
            $Result[0].response.body.created | Should -BeOfType [datetime]
        }
    }
}
