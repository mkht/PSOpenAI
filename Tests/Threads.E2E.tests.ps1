#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Threads E2E Test' {
    Context 'End-to-End tests (online)' -Tag 'Online' {

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
            { $script:Assistant = New-Assistant `
                    -Name $RandomName `
                    -Model gpt-3.5-turbo-1106 `
                    -Description 'Test assistant' `
                    -Instructions "You are an helpful assistant who is there to fulfill the user's wishes to the fullest." `
                    -UseCodeInterpreter $true `
                    -UseRetrieval $false `
                    -TimeoutSec 30 -MaxRetryCount 5 -ea Stop } | Should -Not -Throw
            $Assistant.id | Should -BeLike 'asst_*'
            $Assistant.object | Should -BeExactly 'assistant'
            $Assistant.name | Should -Be $RandomName
        }

        It 'STEP2: Create a Thread and Add a message' {
            { $script:Thread = New-Thread -TimeoutSec 30 -MaxRetryCount 5 -ea Stop |`
                    Add-ThreadMessage -Message $script:PromptMessage -PassThru -TimeoutSec 30 -MaxRetryCount 5 -ea Stop
            } | Should -Not -Throw
            $Thread.id | Should -BeLike 'thread_*'
            $Thread.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Thread.Messages | Should -HaveCount 1
        }

        It 'STEP3: Start Thread Run, then wait for run completion and get result.' {
            { $script:Thread = $script:Thread | Start-ThreadRun -Assistant $script:Assistant -ea Stop |`
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
            { $script:Thread.Messages.file_ids | Get-OpenAIFileContent -OutFile $OutFilePath -ea Stop } | Should -Not -Throw
            $OutFilePath | Should -Exist
            $Csv = Get-Content $OutFilePath -Raw | ConvertFrom-Csv
            $csv.Count | Should -BeGreaterThan 1
            $csv[0].ID | Should -Not -BeNullOrEmpty
            $csv[0].Name | Should -Not -BeNullOrEmpty
            $csv[0].Password | Should -Not -BeNullOrEmpty
        }

        It 'STEP7: Cleanup Thread and Assistant' {
            { $script:Thread | Remove-Thread -ea Stop } | Should -Not -Throw
            { $script:Assistant | Remove-Assistant -ea Stop } | Should -Not -Throw
        }
    }
}
