#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-Assistant' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName New-Assistant {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Assistant'
                    id         = 'asst_abc123'
                    object     = 'assistant'
                    created_at = [datetime]::Today
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Set assistant with ID' {
            { $script:Result = Set-Assistant -AssistantId 'asst_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke New-Assistant -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Assistant'
            $Result.id | Should -Be 'asst_abc123'
        }

        Context 'Parameter Sets' {
            It 'Assistant' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Assistant'
                    id         = 'asst_abc123'
                }
                # Named
                { Set-Assistant -Assistant $InObject -Name 'NewName' -ea Stop } | Should -Not -Throw
                # Position
                { Set-Assistant $InObject -Name 'NewName' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Set-Assistant -Name 'NewName' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName New-Assistant -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'AssistantId' {
                # Named
                { Set-Assistant -AssistantId 'asst_abc123' -Name 'NewName' -ea Stop } | Should -Not -Throw
                # Position
                { Set-Assistant 'asst_abc123' -Name 'NewName' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'asst_abc123' | Set-Assistant -Name 'NewName' -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{assistant_id = 'asst_abc123' } | Set-Assistant -Name 'NewName' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName New-Assistant -ModuleName $script:ModuleName -Times 4 -Exactly
            }
        }
    }
}
