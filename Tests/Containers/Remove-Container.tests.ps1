#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-Container' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "container_abc123",
    "object": "container.deleted",
    "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove container with ID' {
            { $script:Result = Remove-Container -ContainerId 'container_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'Id' {
                # Named
                { Remove-Container -ContainerId 'container_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Container 'container_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'container_abc123' | Remove-Container -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{container_id = 'container_abc123' } | Remove-Container -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'Container' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Container'
                    id         = 'container_abc123'
                }
                # Named
                { Remove-Container -Container $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Container $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-Container -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
