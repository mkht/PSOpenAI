#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-ContainerFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    id: "file-xyz789",
    object: "container.file.deleted",
    deleted: true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Delete a container file' {
            { $script:Result = Remove-ContainerFile -ContainerId 'cont_123456' -FileId 'file-xyz789' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'Id' {
                # Named
                { Remove-ContainerFile -ContainerId 'cont_123456' -FileId 'file-xyz789' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-ContainerFile 'cont_123456' 'file-xyz789' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'cont_123456' | Remove-ContainerFile -FileId 'file-xyz789' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{ContainerId = 'cont_123456'; FileId = 'file-xyz789' } | Remove-ContainerFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'ContainerFile' {
                $InObject = [pscustomobject]@{
                    PSTypeName   = 'PSOpenAI.Container.File'
                    id           = 'file-xyz789'
                    container_id = 'cont_123456'
                }
                # Named
                { Remove-ContainerFile -ContainerFile $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-ContainerFile $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-ContainerFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
