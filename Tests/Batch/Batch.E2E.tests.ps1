#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Batch E2E Test' {
    Context 'End-to-End tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext
            $script:BatchInputs = @()
            $script:Batch = $null
        }

        It 'STEP1: Create multiple batch input objects' {
            # Create 4 input objects
            { (1..4) | ForEach-Object {
                    $script:BatchInputs += Request-ChatCompletion -Message 'Hello.' -Model gpt-4o-mini -AsBatch -CustomBatchId ("custom-batchtest-$_") -MaxCompletionTokens 15 -ea Stop
                } } | Should -Not -Throw
            $script:BatchInputs | Should -HaveCount 4
            $script:BatchInputs[0].custom_id | Should -Be 'custom-batchtest-1'
            $script:BatchInputs[0].method | Should -Be 'POST'
            $script:BatchInputs[0].url | Should -Be '/v1/chat/completions'
            $script:BatchInputs[0].body | Should -Not -BeNullOrEmpty
        }

        It 'STEP2: Start batch' {
            { $script:Batch = $script:BatchInputs | Start-Batch -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            $script:Batch.id | Should -BeLike 'batch_*'
            $script:Batch.status | Should -BeIn ('validating', 'in_progress')
        }

        It 'STEP2: Wait for batch completion' {
            { $script:Batch = $script:Batch | Wait-Batch -TimeoutSec 600 -PollIntervalSec 20 -ea Stop } | Should -Not -Throw
            $script:Batch.id | Should -BeLike 'batch_*'
            $script:Batch.status | Should -Be 'completed'
            $script:Batch.request_counts.completed | Should -Be 4
        }

        It 'STEP3: Get batch output' {
            { $script:BatchOutputs = $script:Batch | Get-BatchOutput -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            $script:BatchOutputs | Should -HaveCount 4
            $script:BatchOutputs[0].custom_id | Should -BeLike 'custom-batchtest-*'
            $script:BatchOutputs[1].custom_id | Should -BeLike 'custom-batchtest-*'
            $script:BatchOutputs[2].custom_id | Should -BeLike 'custom-batchtest-*'
            $script:BatchOutputs[3].custom_id | Should -BeLike 'custom-batchtest-*'
            $script:BatchOutputs[0].response.body.object | Should -Be 'chat.completion'
        }

        It 'STEP4: Get Batch' {
            { $script:tempBatch = Get-Batch -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            $script:tempBatch.Count | Should -BeGreaterOrEqual 1
            $script:tempBatch | Select-Object -ExpandProperty id | Should -Contain $script:Batch.id
        }

        It 'STEP5(extra): Start Batch, Then Cancel it' {
            { $script:NewBatch = Start-Batch -FileId $script:Batch.input_file_id -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            { $script:NewBatch = $script:NewBatch | Stop-Batch -Force -PassThru -TimeoutSec 20 -ea Stop } | Should -Not -Throw
            $script:NewBatch.status | Should -BeIn ('cancelling', 'cancelled')
        }

        It 'Cleanup: Remove batch input/output file from storage' {
            { $script:Batch.input_file_id | Remove-OpenAIFile -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            { $script:Batch.output_file_id | Remove-OpenAIFile -TimeoutSec 10 -ea Stop } | Should -Not -Throw
        }
    }

    Context 'End-to-End tests (Azure OpenAI)' -Tag 'Azure' {
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

            # Deploymenet name
            $script:Model = 'gpt-4o-mini-batch'

            # Initialize variables
            $script:BatchInputs = @()
            $script:Batch = $null
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'STEP1: Create multiple batch input objects' {
            # Create 2 input objects
            { (1..2) | ForEach-Object {
                    $script:BatchInputs += Request-ChatCompletion -Message 'Hello.' -Model $script:Model -AsBatch -CustomBatchId ("custom-batchtest-$_") -MaxCompletionTokens 15 -ea Stop
                } } | Should -Not -Throw
            $script:BatchInputs | Should -HaveCount 2
            $script:BatchInputs[0].custom_id | Should -Be 'custom-batchtest-1'
            $script:BatchInputs[0].method | Should -Be 'POST'
            $script:BatchInputs[0].url | Should -Be '/chat/completions'
            $script:BatchInputs[0].body | Should -Not -BeNullOrEmpty
            $script:BatchInputs[0].body.model | Should -Be $script:Model
        }

        It 'STEP2: Start batch' {
            { $script:Batch = $script:BatchInputs | Start-Batch -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            $script:Batch.id | Should -BeLike 'batch_*'
            $script:Batch.status | Should -BeIn ('validating', 'in_progress')
        }

        It 'STEP2: Wait for batch completion' {
            { $script:Batch = $script:Batch | Wait-Batch -TimeoutSec 720 -PollIntervalSec 20 -ea Stop } | Should -Not -Throw
            $script:Batch.id | Should -BeLike 'batch_*'
            $script:Batch.status | Should -Be 'completed'
            $script:Batch.request_counts.completed | Should -Be 2
        }

        It 'STEP3: Get batch output' {
            { $script:BatchOutputs = $script:Batch | Get-BatchOutput -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            $script:BatchOutputs | Should -HaveCount 2
            $script:BatchOutputs[0].custom_id | Should -BeLike 'custom-batchtest-*'
            $script:BatchOutputs[1].custom_id | Should -BeLike 'custom-batchtest-*'
            $script:BatchOutputs[2].custom_id | Should -BeLike 'custom-batchtest-*'
            $script:BatchOutputs[3].custom_id | Should -BeLike 'custom-batchtest-*'
            $script:BatchOutputs[0].response.body.object | Should -Be 'chat.completion'
        }

        It 'STEP4: Get Batch' {
            { $script:tempBatch = Get-Batch -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            $script:tempBatch.Count | Should -BeGreaterOrEqual 1
            $script:tempBatch | Select-Object -ExpandProperty id | Should -Contain $script:Batch.id
        }

        It 'STEP5(extra): Start Batch, Then Cancel it' {
            { $script:NewBatch = Start-Batch -FileId $script:Batch.input_file_id -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            { $script:NewBatch = $script:NewBatch | Stop-Batch -Force -PassThru -TimeoutSec 20 -ea Stop } | Should -Not -Throw
            $script:NewBatch.status | Should -BeIn ('cancelling', 'cancelled')
        }

        It 'Cleanup: Remove batch input/output file from storage' {
            { $script:Batch.input_file_id | Remove-OpenAIFile -TimeoutSec 10 -ea Stop } | Should -Not -Throw
            { $script:Batch.output_file_id | Remove-OpenAIFile -TimeoutSec 10 -ea Stop } | Should -Not -Throw
        }
    }
}
