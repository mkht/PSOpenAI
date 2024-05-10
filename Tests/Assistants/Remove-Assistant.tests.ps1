#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-Assistant' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "asst_abc123",
    "object": "assistant.deleted",
    "deleted": true
    }
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove assistant with ID' {
            { $script:Result = Remove-Assistant -AssistantId 'asst_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'Id' {
                # Named
                { Remove-Assistant -AssistantId 'asst_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Assistant 'asst_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'asst_abc123' | Remove-Assistant -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{assistant_id = 'asst_abc123' } | Remove-Assistant -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'VectorStore' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Assistant'
                    id         = 'asst_abc123'
                }
                # Named
                { Remove-Assistant -Assistant $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Assistant $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-Assistant -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove assistant' {
            $assistant = New-Assistant
            { $assistant | Remove-Assistant -ea Stop } | Should -Not -Throw
            $assistant = try { $assistant | Get-Assistant -ea Ignore }catch {}
            $assistant | Should -BeNullOrEmpty
        }

        It 'Error on non existent assistant' {
            $assistant_id = 'asst_notexit'
            { $assistant_id | Remove-Assistant -ea Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }
    }
}
