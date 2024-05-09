#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Batch' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "batch_abc123",
    "object": "batch",
    "endpoint": "/v1/completions",
    "errors": null,
    "input_file_id": "file-abc123",
    "completion_window": "24h",
    "status": "completed",
    "output_file_id": "file-cvaTdG",
    "error_file_id": null,
    "created_at": 1711471533,
    "in_progress_at": 1711471538,
    "expires_at": 1711557933,
    "finalizing_at": 1711493133,
    "completed_at": 1711493163,
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
'@ } -ParameterFilter { 'https://api.openai.com/v1/batches/batch_abc123' -eq $Uri }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                @'
{
    "object": "list",
    "data": [
        {"id":"batch_abc123","object":"batch","endpoint":"/v1/completions","errors":null,"input_file_id":"file-abc123","completion_window":"24h","status":"completed","output_file_id":"file-cvaTdG","error_file_id":null,"created_at":1711471533,"in_progress_at":1711471538,"expires_at":1711557933,"finalizing_at":1711493133,"completed_at":1711493163,"failed_at":null,"expired_at":null,"cancelling_at":null,"cancelled_at":null,"request_counts":{"total":5,"completed":5,"failed":0},"metadata":{}},
        {"id":"batch_abc456","object":"batch","endpoint":"/v1/completions","errors":null,"input_file_id":"file-abc123","completion_window":"24h","status":"completed","output_file_id":"file-cvaTdG","error_file_id":null,"created_at":1711471533,"in_progress_at":1711471538,"expires_at":1711557933,"finalizing_at":1711493133,"completed_at":1711493163,"failed_at":null,"expired_at":null,"cancelling_at":null,"cancelled_at":null,"request_counts":{"total":5,"completed":5,"failed":0},"metadata":{}},
        {"id":"batch_abc789","object":"batch","endpoint":"/v1/completions","errors":null,"input_file_id":"file-abc123","completion_window":"24h","status":"completed","output_file_id":"file-cvaTdG","error_file_id":null,"created_at":1711471533,"in_progress_at":1711471538,"expires_at":1711557933,"finalizing_at":1711493133,"completed_at":1711493163,"failed_at":null,"expired_at":null,"cancelling_at":null,"cancelled_at":null,"request_counts":{"total":5,"completed":5,"failed":0},"metadata":{}}
    ],
    "first_id": "batch_abc123",
    "last_id": "batch_abc789",
    "has_more": false
}
'@
            } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/batches`?limit=*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List batch objects' {
            { $script:Result = Get-Batch -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/batches`?limit=*' }
            $Result | Should -HaveCount 3
            $Result[0].id | Should -BeLike 'batch_abc*'
            $Result[1].id | Should -BeLike 'batch_abc*'
            $Result[2].id | Should -BeLike 'batch_abc*'
            $Result[0].created_at | Should -BeOfType [datetime]
        }

        It 'Get single batch object' {
            { $script:Result = Get-Batch -BatchId 'batch_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/batches/batch_abc123' -eq $Uri }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'batch_abc123'
            $Result.created_at | Should -BeOfType [datetime]
        }

        Context 'Parameter Sets' {
            It 'Get_Batch' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Batch'
                    id         = 'batch_abc123'
                }
                # Named
                { Get-Batch -Batch $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Batch $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-Batch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/batches/batch_abc123' -eq $Uri }
            }

            It 'Get_Id' {
                # Named
                { Get-Batch -BatchId 'batch_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Batch 'batch_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'batch_abc123' | Get-Batch -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{batch_id = 'batch_abc123' } | Get-Batch -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/batches/batch_abc123' -eq $Uri }
            }

            It 'List' {
                { Get-Batch -ea Stop } | Should -Not -Throw
                { Get-Batch -Limit 15 -ea Stop } | Should -Not -Throw
                { Get-Batch -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/batches`?limit=*' }
            }
        }
    }
}
