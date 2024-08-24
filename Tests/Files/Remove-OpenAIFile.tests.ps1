#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-OpenAIFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "file-abc123",
    "object": "file",
    "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove file with ID' {
            { $script:Result = Remove-OpenAIFile -ID 'file-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'File' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                # Named
                { Remove-OpenAIFile -File $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-OpenAIFile $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Remove-OpenAIFile -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-OpenAIFile 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'file-abc123' | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{file_id = 'file-abc123' } | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
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

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove a file' {
            { Remove-OpenAIFile -ID $script:File1.id -ea Stop } | Should -Not -Throw
        }
    }

    Context 'Integration tests (Azure)' -Tag 'Azure' {
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

        BeforeEach {
            $script:Result = ''
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'Remove a file' {
            { Remove-OpenAIFile -ID $script:File1.id -ea Stop } | Should -Not -Throw
        }
    }
}
