#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-OpenAIFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } { @'
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
            Should -Invoke Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } -ModuleName $script:ModuleName -Times 1 -Exactly
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
                Should -Invoke -CommandName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } -ModuleName $script:ModuleName -Times 3 -Exactly
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
                Should -Invoke -CommandName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } -ModuleName $script:ModuleName -Times 4 -Exactly
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


}
