#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-ChatCompletion' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "object": "chat.completion.deleted",
  "id": "chatcmpl-abc123",
  "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove completion with ID' {
            { $script:Result = Remove-ChatCompletion -CompletionId 'chatcmpl-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'Chat' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Chat.Completion'
                    id         = 'chatcmpl-abc123'
                }
                # Named
                { Remove-ChatCompletion -Completion $InObject -ea Stop } | Should -Not -Throw
                # Alias
                { Remove-ChatCompletion -InputObject $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-ChatCompletion $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-ChatCompletion -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'Id' {
                # Named
                { Remove-ChatCompletion -CompletionId 'chatcmpl-abc123' -ea Stop } | Should -Not -Throw
                # Alias
                { Remove-ChatCompletion -Id 'chatcmpl-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-ChatCompletion 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'file-abc123' | Remove-ChatCompletion -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{completion_id = 'file-abc123' } | Remove-ChatCompletion -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 5 -Exactly
            }
        }
    }
}
