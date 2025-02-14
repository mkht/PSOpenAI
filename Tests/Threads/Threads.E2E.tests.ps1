#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Threads E2E Test' {
    Context 'End-to-End tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext
            $script:Model = 'gpt-4o-mini'
        }

        Context 'Code interpreter' {
            BeforeAll {
                $script:PromptMessage = @'
Create 20 fictitious user account information and list them in a CSV file.
The CSV file will contain three keys: ID, Name, and Password.
ID should be in the form of 3 random lowercase alphabet letters followed by a 4-digit random number.
Name should be an appropriate person's name.
Password should be between 8 and 12 random alphanumeric characters.
'@
            }

            It 'STEP1: Create an Assistant' {
                $RandomName = ('TEST' + (Get-Random -Maximum 1000))
                { $splat = @{
                        Name               = $RandomName
                        Model              = $script:Model
                        Description        = 'Test assistant'
                        Instructions       = "You are an helpful assistant who is there to fulfill the user's wishes to the fullest."
                        UseCodeInterpreter = $true
                        UseFileSearch      = $false
                        Temperature        = 0
                        TimeoutSec         = 30
                        MaxRetryCount      = 5
                        ErrorAction        = 'Stop'
                    }
                    $script:Assistant = New-Assistant @splat
                } | Should -Not -Throw
                $Assistant.id | Should -BeLike 'asst_*'
                $Assistant.object | Should -BeExactly 'assistant'
                $Assistant.name | Should -Be $RandomName
            }

            It 'STEP2: Create a Thread and Add a message' {
                { $script:Thread = New-Thread -TimeoutSec 30 -MaxRetryCount 5 -ea Stop | Add-ThreadMessage -Message $script:PromptMessage -PassThru -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.GetType().Fullname | Should -Be 'System.Object[]'
                $Thread.Messages | Should -HaveCount 1
            }

            It 'STEP3: Start Thread Run, then wait for run completion and get result.' {
                { $script:Thread = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -ea Stop |
                        Receive-ThreadRun -Wait -TimeoutSec 100 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.Count | Should -BeGreaterOrEqual 2
            }

            It 'STEP4: Get result messages as simple and read suitable format.' {
                $Thread.Messages.SimpleContent[0] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[0].Role | Should -Be 'user'
                $Thread.Messages.SimpleContent[0].Type | Should -Be 'text'
                $Thread.Messages.SimpleContent[0].Content | Should -BeExactly $script:PromptMessage
                $Thread.Messages.SimpleContent[-1] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[-1].Role | Should -Be 'assistant'
                $Thread.Messages.SimpleContent[-1].Type | Should -Be 'text'
            }

            It 'STEP5: Get run step details' {
                { $script:Steps = $script:Thread | Get-ThreadRun -All -ea Stop | Get-ThreadRunStep -All -ea Stop } | Should -Not -Throw
                $Steps.Count | Should -BeGreaterOrEqual 1
                $Steps.SimpleContent[0] | Should -BeOfType [pscustomobject]
                $Steps.SimpleContent.Role | Should -Contain 'assistant'
                $Steps.SimpleContent.Type | Should -Contain 'text'
                $Steps.SimpleContent[0].Content | Should -BeOfType [string]
            }

            It 'STEP6: Download file that has been generated.' {
                $OutFilePath = (Join-Path $TestDrive 'test.csv')
                { $script:Thread.Messages.attachments.file_id | Get-OpenAIFileContent -OutFile $OutFilePath -ea Stop } | Should -Not -Throw
                $OutFilePath | Should -Exist
                $Csv = Get-Content $OutFilePath -Raw | ConvertFrom-Csv
                $csv.Count | Should -BeGreaterThan 1
                $csv[0].ID | Should -Not -BeNullOrEmpty
                $csv[0].Name | Should -Not -BeNullOrEmpty
                $csv[0].Password | Should -Not -BeNullOrEmpty
            }

            It 'STEP7: Cleanup Thread and Assistant' {
                { $script:Thread.Messages.attachments.file_id | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
                { $script:Thread | Remove-Thread -ea Stop } | Should -Not -Throw
                { $script:Assistant | Remove-Assistant -ea Stop } | Should -Not -Throw
            }
        }

        Context 'File Search' {
            BeforeAll {
                $script:Assistant = $null
                $script:Thread = $null

                # Prepare test datasets
                $null = Expand-Archive ($script:TestData + '/datasets.zip') -DestinationPath (Join-Path $TestDrive 'datasets') -Force
                $script:dataSet = Get-ChildItem (Join-Path $TestDrive 'datasets') -Recurse -File
                $script:dataSet = $script:dataSet | ? { -not $_.PSIsContainer }

                $script:Instructions = 'You are a helpful assistant. You have access to the files you need to answer questions. Always answer based on the contents of the file. Do not use any information that is not in the file.'
                $script:PromptMessage = 'Please make a list of vulnerabilities related to FortiOS from the CVEs published in 2024.'
            }

            It 'STEP1: Uploads test data' {
                { $script:UploadItems = $script:dataSet | Add-OpenAIFile -Purpose assistants -TimeoutSec 300 } | Should -Not -Throw
                $UploadItems | Should -HaveCount $script:dataSet.Count
                $UploadItems[0].id | Should -BeLike 'file*'
                $UploadItems[0].object | Should -Be 'file'
                $UploadItems[0].purpose | Should -Be 'assistants'
            }

            It 'STEP2: Create an Assistant' {
                $RandomName = ('TEST' + (Get-Random -Maximum 1000))
                { $splat = @{
                        Name                 = $RandomName
                        Model                = $script:Model
                        Description          = 'Test assistant'
                        Instructions         = $script:Instructions
                        UseCodeInterpreter   = $false
                        UseFileSearch        = $true
                        FileIdsForFileSearch = $script:UploadItems.id
                        Temperature          = 0
                        TimeoutSec           = 30
                        MaxRetryCount        = 5
                        ErrorAction          = 'Stop'
                    }
                    $script:Assistant = New-Assistant @splat
                } | Should -Not -Throw
                $Assistant.id | Should -BeLike 'asst_*'
                $Assistant.object | Should -BeExactly 'assistant'
                $Assistant.name | Should -Be $RandomName
            }

            It 'STEP3: Create a Thread and Add a message' {
                { $script:Thread = New-Thread -TimeoutSec 30 -MaxRetryCount 5 -ea Stop | Add-ThreadMessage -Message $script:PromptMessage -PassThru -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.GetType().Fullname | Should -Be 'System.Object[]'
                $Thread.Messages | Should -HaveCount 1
            }

            It 'STEP4: Start Thread Run, then wait for run completion and get result.' {
                { $script:Thread = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -ea Stop |
                        Receive-ThreadRun -Wait -TimeoutSec 100 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.Count | Should -BeGreaterOrEqual 2
            }

            It 'STEP5: Get result messages as simple and read suitable format.' {
                $Thread.Messages.SimpleContent[0] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[0].Role | Should -Be 'user'
                $Thread.Messages.SimpleContent[0].Type | Should -Be 'text'
                $Thread.Messages.SimpleContent[0].Content | Should -BeExactly $script:PromptMessage
                $Thread.Messages.SimpleContent[-1] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[-1].Role | Should -Be 'assistant'
                $Thread.Messages.SimpleContent[-1].Type | Should -Be 'text'
            }

            It 'STEP6: Get run step details' {
                { $script:Steps = $script:Thread | Get-ThreadRun -All -ea Stop | Get-ThreadRunStep -All -ea Stop } | Should -Not -Throw
                $Steps.Count | Should -BeGreaterOrEqual 1
                $Steps.SimpleContent[-1] | Should -BeOfType [pscustomobject]
                $Steps.SimpleContent.Role | Should -Contain 'assistant'
                $Steps.SimpleContent.Type | Should -Contain 'text'
                $Steps.SimpleContent[-1].Content | Should -BeOfType [string]
            }

            It 'STEP7: Cleanup' {
                { $script:Assistant.tool_resources.file_search.vector_store_ids | Remove-VectorStore -ea Stop } | Should -Not -Throw
                { $script:Thread | Remove-Thread -ea Stop } | Should -Not -Throw
                { $script:Assistant | Remove-Assistant -ea Stop } | Should -Not -Throw
                { $script:UploadItems | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
            }
        }

        Context 'Vision' {
            BeforeAll {
                $script:Assistant = $null
                $script:Thread = $null

                # sample image url
                $script:WikiDonutsImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e4/4_donuts.jpg/640px-4_donuts.jpg'

                $script:Instructions = 'You are an expert in pastries'
                $script:PromptMessage = 'Please explain the relationship between the two images.'
            }

            It 'STEP1: Uploads test image' {
                { $script:UploadItems = Add-OpenAIFile -File ($script:TestData + '/sweets_donut.png') -Purpose vision -ea Stop } | Should -Not -Throw
                $UploadItems.id | Should -BeLike 'file*'
                $UploadItems.purpose | Should -Be 'vision'
            }

            It 'STEP2: Create an Assistant' {
                $RandomName = ('TEST' + (Get-Random -Maximum 1000))
                { $splat = @{
                        Name          = $RandomName
                        Model         = $script:Model
                        Description   = 'Test assistant'
                        Instructions  = $script:Instructions
                        Temperature   = 0
                        TimeoutSec    = 30
                        MaxRetryCount = 5
                        ErrorAction   = 'Stop'
                    }
                    $script:Assistant = New-Assistant @splat
                } | Should -Not -Throw
                $Assistant.id | Should -BeLike 'asst_*'
                $Assistant.object | Should -BeExactly 'assistant'
                $Assistant.name | Should -Be $RandomName
            }

            It 'STEP3: Create a Thread and Add a message' {
                { $script:Thread = New-Thread -TimeoutSec 30 -MaxRetryCount 5 -ea Stop | `
                            Add-ThreadMessage `
                            -Message $script:PromptMessage `
                            -Images @($script:UploadItems, $script:WikiDonutsImageUrl) `
                            -PassThru -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages | Should -HaveCount 1
            }

            It 'STEP4: Start Thread Run, then wait for run completion and get result.' {
                { $script:Thread = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -ea Stop |
                        Receive-ThreadRun -Wait -TimeoutSec 100 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.Count | Should -BeGreaterOrEqual 2
            }

            It 'STEP5: Get result messages as simple and read suitable format.' {
                $Thread.Messages.SimpleContent[0] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[0].Role | Should -Be 'user'
                $Thread.Messages.SimpleContent[0].Type | Should -Be 'text'
                $Thread.Messages.SimpleContent[0].Content | Should -BeExactly $script:PromptMessage
                $Thread.Messages.SimpleContent[-1] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[-1].Role | Should -Be 'assistant'
                $Thread.Messages.SimpleContent[-1].Type | Should -Be 'text'
            }

            It 'STEP6: Get run step details' {
                { $script:Steps = $script:Thread | Get-ThreadRun -All -ea Stop | Get-ThreadRunStep -All -ea Stop } | Should -Not -Throw
                $Steps.Count | Should -BeGreaterOrEqual 1
                $Steps.SimpleContent[-1] | Should -BeOfType [pscustomobject]
                $Steps.SimpleContent.Role | Should -Contain 'assistant'
                $Steps.SimpleContent.Type | Should -Contain 'text'
                $Steps.SimpleContent[-1].Content | Should -BeOfType [string]
            }

            It 'STEP7: Cleanup' {
                { $script:Thread | Remove-Thread -ea Stop } | Should -Not -Throw
                { $script:Assistant | Remove-Assistant -ea Stop } | Should -Not -Throw
                { $script:UploadItems | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
            }
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
            $script:Model = 'gpt-4o-mini'
        }

        AfterAll {
            Clear-OpenAIContext
        }

        Context 'Code interpreter' {
            BeforeAll {
                $script:PromptMessage = @'
Create 20 fictitious user account information and list them in a CSV file.
The CSV file will contain three keys: ID, Name, and Password.
ID should be in the form of 3 random lowercase alphabet letters followed by a 4-digit random number.
Name should be an appropriate person's name.
Password should be between 8 and 12 random alphanumeric characters.
'@
            }

            It 'STEP1: Create an Assistant' {
                $RandomName = ('TEST' + (Get-Random -Maximum 1000))
                { $splat = @{
                        Name               = $RandomName
                        Model              = $script:Model
                        Description        = 'Test assistant'
                        Instructions       = "You are an helpful assistant who is there to fulfill the user's wishes to the fullest."
                        UseCodeInterpreter = $true
                        UseFileSearch      = $false
                        Temperature        = 0
                        TimeoutSec         = 30
                        MaxRetryCount      = 5
                        ErrorAction        = 'Stop'
                    }
                    $script:Assistant = New-Assistant @splat
                } | Should -Not -Throw
                $Assistant.id | Should -BeLike 'asst_*'
                $Assistant.object | Should -BeExactly 'assistant'
                $Assistant.name | Should -Be $RandomName
            }

            It 'STEP2: Create a Thread and Add a message' {
                { $script:Thread = New-Thread -TimeoutSec 30 -MaxRetryCount 5 -ea Stop | Add-ThreadMessage -Message $script:PromptMessage -PassThru -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.GetType().Fullname | Should -Be 'System.Object[]'
                $Thread.Messages | Should -HaveCount 1
            }

            It 'STEP3: Start Thread Run, then wait for run completion and get result.' {
                { $script:Thread = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -ea Stop |
                        Receive-ThreadRun -Wait -TimeoutSec 100 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.Count | Should -BeGreaterOrEqual 2
            }

            It 'STEP4: Get result messages as simple and read suitable format.' {
                $Thread.Messages.SimpleContent[0] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[0].Role | Should -Be 'user'
                $Thread.Messages.SimpleContent[0].Type | Should -Be 'text'
                $Thread.Messages.SimpleContent[0].Content | Should -BeExactly $script:PromptMessage
                $Thread.Messages.SimpleContent[-1] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[-1].Role | Should -Be 'assistant'
                $Thread.Messages.SimpleContent[-1].Type | Should -Be 'text'
            }

            It 'STEP5: Get run step details' {
                { $script:Steps = $script:Thread | Get-ThreadRun -All -ea Stop | Get-ThreadRunStep -All -ea Stop } | Should -Not -Throw
                $Steps.Count | Should -BeGreaterOrEqual 1
                $Steps.SimpleContent[0] | Should -BeOfType [pscustomobject]
                $Steps.SimpleContent.Role | Should -Contain 'assistant'
                $Steps.SimpleContent.Type | Should -Contain 'text'
                $Steps.SimpleContent[0].Content | Should -BeOfType [string]
            }

            It 'STEP6: Download file that has been generated.' {
                $OutFilePath = (Join-Path $TestDrive 'test.csv')
                { $script:Thread.Messages.attachments.file_id | Get-OpenAIFileContent -OutFile $OutFilePath -ea Stop } | Should -Not -Throw
                $OutFilePath | Should -Exist
                $Csv = Get-Content $OutFilePath -Raw | ConvertFrom-Csv
                $csv.Count | Should -BeGreaterThan 1
                $csv[0].ID | Should -Not -BeNullOrEmpty
                $csv[0].Name | Should -Not -BeNullOrEmpty
                $csv[0].Password | Should -Not -BeNullOrEmpty
            }

            It 'STEP7: Cleanup Thread and Assistant' {
                { $script:Thread.Messages.attachments.file_id | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
                { $script:Thread | Remove-Thread -ea Stop } | Should -Not -Throw
                { $script:Assistant | Remove-Assistant -ea Stop } | Should -Not -Throw
            }
        }

        Context 'File Search' {
            BeforeAll {
                $script:Assistant = $null
                $script:Thread = $null

                # Prepare test datasets
                $null = Expand-Archive ($script:TestData + '/datasets.zip') -DestinationPath (Join-Path $TestDrive 'datasets') -Force
                $script:dataSet = Get-ChildItem (Join-Path $TestDrive 'datasets') -Recurse -File
                $script:dataSet = $script:dataSet | ? { -not $_.PSIsContainer }

                $script:Instructions = 'You are a helpful assistant. You have access to the files you need to answer questions. Always answer based on the contents of the file. Do not use any information that is not in the file.'
                $script:PromptMessage = 'Please make a list of vulnerabilities related to FortiOS from the CVEs published in 2024.'
            }

            It 'STEP1: Uploads test data' {
                { $script:UploadItems = $script:dataSet | Add-OpenAIFile -Purpose assistants -TimeoutSec 300 } | Should -Not -Throw
                $UploadItems | Should -HaveCount $script:dataSet.Count
                $UploadItems[0].id | Should -Not -BeNullOrEmpty
                $UploadItems[0].object | Should -Be 'file'
                $UploadItems[0].purpose | Should -Be 'assistants'
            }

            It 'STEP2: Create an Assistant' {
                $RandomName = ('TEST' + (Get-Random -Maximum 1000))
                { $splat = @{
                        Name                 = $RandomName
                        Model                = $script:Model
                        Description          = 'Test assistant'
                        Instructions         = $script:Instructions
                        UseCodeInterpreter   = $false
                        UseFileSearch        = $true
                        FileIdsForFileSearch = $script:UploadItems.id
                        Temperature          = 0
                        TimeoutSec           = 30
                        MaxRetryCount        = 5
                        ErrorAction          = 'Stop'
                    }
                    $script:Assistant = New-Assistant @splat
                } | Should -Not -Throw
                $Assistant.id | Should -BeLike 'asst_*'
                $Assistant.object | Should -BeExactly 'assistant'
                $Assistant.name | Should -Be $RandomName
            }

            It 'STEP3: Create a Thread and Add a message' {
                { $script:Thread = New-Thread -TimeoutSec 30 -MaxRetryCount 5 -ea Stop | Add-ThreadMessage -Message $script:PromptMessage -PassThru -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.GetType().Fullname | Should -Be 'System.Object[]'
                $Thread.Messages | Should -HaveCount 1
            }

            It 'STEP4: Start Thread Run, then wait for run completion and get result.' {
                { $script:Thread = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -ea Stop |
                        Receive-ThreadRun -Wait -TimeoutSec 100 -ea Stop } | Should -Not -Throw
                $Thread.id | Should -BeLike 'thread_*'
                $Thread.Messages.Count | Should -BeGreaterOrEqual 2
            }

            It 'STEP5: Get result messages as simple and read suitable format.' {
                $Thread.Messages.SimpleContent[0] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[0].Role | Should -Be 'user'
                $Thread.Messages.SimpleContent[0].Type | Should -Be 'text'
                $Thread.Messages.SimpleContent[0].Content | Should -BeExactly $script:PromptMessage
                $Thread.Messages.SimpleContent[-1] | Should -BeOfType [pscustomobject]
                $Thread.Messages.SimpleContent[-1].Role | Should -Be 'assistant'
                $Thread.Messages.SimpleContent[-1].Type | Should -Be 'text'
            }

            It 'STEP6: Get run step details' {
                { $script:Steps = $script:Thread | Get-ThreadRun -All -ea Stop | Get-ThreadRunStep -All -ea Stop } | Should -Not -Throw
                $Steps.Count | Should -BeGreaterOrEqual 1
                $Steps.SimpleContent[-1] | Should -BeOfType [pscustomobject]
                $Steps.SimpleContent.Role | Should -Contain 'assistant'
                $Steps.SimpleContent.Type | Should -Contain 'text'
                $Steps.SimpleContent[-1].Content | Should -BeOfType [string]
            }

            It 'STEP7: Cleanup' {
                { $script:Assistant.tool_resources.file_search.vector_store_ids | Remove-VectorStore -ea Stop } | Should -Not -Throw
                { $script:Thread | Remove-Thread -ea Stop } | Should -Not -Throw
                { $script:Assistant | Remove-Assistant -ea Stop } | Should -Not -Throw
                { $script:UploadItems | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
            }
        }
    }
}