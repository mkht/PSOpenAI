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
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
        }

        It 'Pipeline input' {
            $InObject = [pscustomobject]@{
                file_id = 'file-abc123'
                object  = 'file'
            }
            { $InObject | Remove-OpenAIFile -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
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
}
