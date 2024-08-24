#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-VectorStore' {
    Context 'End-to-End tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext

            # Prepare test datasets
            $null = Expand-Archive ($script:TestData + '/datasets.zip') -DestinationPath (Join-Path $TestDrive 'datasets') -Force
            $script:dataSet = Get-ChildItem (Join-Path $TestDrive 'datasets') -Recurse -File
            $script:dataSet = $script:dataSet | Where-Object { -not $_.PSIsContainer }
        }

        It 'STEP1: Upload test data sets' {
            { $script:UploadItems = $script:dataSet | Add-OpenAIFile -Purpose assistants -TimeoutSec 300 } | Should -Not -Throw
            $UploadItems | Should -HaveCount $script:dataSet.Count
            $UploadItems[0].id | Should -BeLike 'file*'
            $UploadItems[0].object | Should -Be 'file'
            $UploadItems[0].purpose | Should -Be 'assistants'
        }

        It 'STEP2: Create a new vector store' {
            $params = @{
                Name             = 'TestVectorStore-' + (Get-Random -Maximum 999)
                ExpiresAfterDays = 2
                MaxRetryCount    = 5
            }
            { $script:VectorStore = New-VectorStore @params -ea Stop } | Should -Not -Throw
            $VectorStore | Should -BeOfType [pscustomobject]
            $VectorStore.id | Should -BeLike 'vs_*'
            $VectorStore.name | Should -Be $params.Name
            $VectorStore.created_at | Should -BeOfType [datetime]
            $VectorStore.file_counts.total | Should -Be 0
        }

        It 'STEP3: Add a file to vector store' {
            # So flaky
            { $script:VectorStore = $script:VectorStore | Add-VectorStoreFile -FileId $UploadItems[0].id -MaxRetryCount 5 -PassThru -ea Stop } | Should -Not -Throw
            $VectorStore.file_counts.total | Should -Be 1
        }

        It 'STEP4: Add multiple files to vector store (batch)' {
            # So flaky
            { $script:Batch = $script:VectorStore | Start-VectorStoreFileBatch -FileId $UploadItems[1..2].id -MaxRetryCount 5 -ea Stop | Wait-VectorStoreFileBatch -TimeoutSec 100 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $Batch.id | Should -BeLike 'vsfb_*'
            $Batch.status | Should -Be 'completed'
            $Batch.file_counts.total | Should -Be 2
            $Batch.file_counts.completed | Should -Be 2
        }

        It 'STEP5: Get files info in batch' {
            { $script:FilesInBatch = $script:Batch | Get-VectorStoreFileInBatch -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $FilesInBatch | Should -HaveCount 2
        }

        It 'STEP6: Refresh vector store object' {
            { $script:VectorStore = Get-VectorStore -VectorStore $script:VectorStore -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $VectorStore.file_counts.total | Should -Be $script:dataSet.Count
        }

        It 'STEP7: Clean up' {
            { $script:VectorStore | Remove-VectorStore -ea Stop } | Should -Not -Throw
            { $script:UploadItems | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
        }
    }

    Context 'End-to-End tests (Azure)' -Tag 'Azure' {
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

            # Prepare test datasets
            $null = Expand-Archive ($script:TestData + '/datasets.zip') -DestinationPath (Join-Path $TestDrive 'datasets') -Force
            $script:dataSet = Get-ChildItem (Join-Path $TestDrive 'datasets') -Recurse -File
            $script:dataSet = $script:dataSet | Where-Object { -not $_.PSIsContainer }
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'STEP1: Upload test data sets' {
            { $script:UploadItems = $script:dataSet | Add-OpenAIFile -Purpose assistants -TimeoutSec 300 } | Should -Not -Throw
            $UploadItems | Should -HaveCount $script:dataSet.Count
            $UploadItems[0].id | Should -Not -BeNullOrEmpty
            $UploadItems[0].object | Should -Be 'file'
            $UploadItems[0].purpose | Should -Be 'assistants'
        }

        It 'STEP2: Create a new vector store' {
            $params = @{
                Name             = 'TestVectorStore-' + (Get-Random -Maximum 999)
                ExpiresAfterDays = 2
                MaxRetryCount    = 5
            }
            { $script:VectorStore = New-VectorStore @params -ea Stop } | Should -Not -Throw
            $VectorStore | Should -BeOfType [pscustomobject]
            $VectorStore.id | Should -BeLike 'vs_*'
            $VectorStore.name | Should -Be $params.Name
            $VectorStore.created_at | Should -BeOfType [datetime]
            $VectorStore.file_counts.total | Should -Be 0
        }

        It 'STEP3: Add a file to vector store' {
            { $script:VectorStore = $script:VectorStore | Add-VectorStoreFile -FileId $UploadItems[0].id -MaxRetryCount 5 -PassThru -ea Stop } | Should -Not -Throw
            $VectorStore.file_counts.total | Should -Be 1
        }

        It 'STEP4: Add multiple files to vector store (batch)' {
            { $script:Batch = $script:VectorStore | Start-VectorStoreFileBatch -FileId $UploadItems[1..2].id -MaxRetryCount 5 -ea Stop | Wait-VectorStoreFileBatch -TimeoutSec 100 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $Batch.id | Should -Not -BeNullOrEmpty
            $Batch.status | Should -Be 'completed'
            $Batch.file_counts.total | Should -Be 2
            $Batch.file_counts.completed | Should -Be 2
        }

        It 'STEP5: Get files info in batch' {
            { $script:FilesInBatch = $script:Batch | Get-VectorStoreFileInBatch -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $FilesInBatch | Should -HaveCount 2
        }

        It 'STEP6: Refresh vector store object' {
            { $script:VectorStore = Get-VectorStore -VectorStore $script:VectorStore -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $VectorStore.file_counts.total | Should -Be $script:dataSet.Count
        }

        It 'STEP7: Clean up' {
            { $script:VectorStore | Remove-VectorStore -ea Stop } | Should -Not -Throw
            { $script:UploadItems | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
        }
    }
}
