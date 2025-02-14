#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-OpenAIFileContent' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                [System.Text.Encoding]::UTF8.GetBytes('ABC')
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Save content to local file' {
            $OutFile = (Join-Path $TestDrive 'abc.txt')
            { $script:Result = Get-OpenAIFileContent -FileId 'file-abc123' -OutFile $OutFile -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
            $OutFile | Should -Exist
            $OutFile | Should -FileContentMatchExactly 'ABC'
        }

        It 'Output content as byte array' {
            { $script:Result = Get-OpenAIFileContent -FileId 'file-abc123'-ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [byte]
            $Result[0] | Should -Be ([byte]65)
        }

        Context 'Parameter Sets' {
            It 'File' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                # Named
                { Get-OpenAIFileContent -File $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-OpenAIFileContent $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-OpenAIFileContent -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Get-OpenAIFileContent -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-OpenAIFileContent 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'file-abc123' | Get-OpenAIFileContent -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{ID = 'thread_abc123' } | Get-OpenAIFileContent -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext

            # Upload test files
            $script:File1 = Add-OpenAIFile -File ($script:TestData + '/my-data.jsonl') -Purpose fine-tune
        }

        AfterEach {
            $script:File1 | Remove-OpenAIFile -ea SilentlyContinue
        }

        It 'Save content to local file' {
            $OutFile = (Join-Path $TestDrive 'my-data.jsonl')
            { Get-OpenAIFileContent -FileId $script:File1.id -OutFile $OutFile -ea Stop } | Should -Not -Throw
            $OutFile | Should -Exist
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
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

            # Upload test files
            $script:File1 = Add-OpenAIFile -File ($script:TestData + '/my-data.jsonl') -Purpose fine-tune
        }

        AfterEach {
            $script:File1 | Remove-OpenAIFile -ea SilentlyContinue
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'Save content to local file' {
            $OutFile = (Join-Path $TestDrive 'my-data.jsonl')
            { Get-OpenAIFileContent -FileId $script:File1.id -OutFile $OutFile -ea Stop } | Should -Not -Throw
            $OutFile | Should -Exist
        }
    }
}
