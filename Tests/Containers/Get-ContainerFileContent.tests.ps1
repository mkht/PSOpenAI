#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-ContainerFileContent' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { [System.Text.Encoding]::UTF8.GetBytes('XYZ') }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Save content to local file' {
            $OutFile = (Join-Path $TestDrive 'xyz.txt')
            { $script:Result = Get-ContainerFileContent -ContainerId 'container_abc123' -FileId 'file_abc123' -OutFile $OutFile -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
            $OutFile | Should -Exist
            $OutFile | Should -FileContentMatchExactly 'XYZ'
        }

        It 'Output content as byte array' {
            { $script:Result = Get-ContainerFileContent -ContainerId 'container_abc123' -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [byte]
            $Result[0] | Should -Be ([byte]88) # 'X'
        }

        It 'Input Container File object' {
            $InObject = [pscustomobject]@{
                PSTypeName   = 'PSOpenAI.Container.File'
                id           = 'file_abc123'
                container_id = 'container_abc123'
            }
            { $script:Result = Get-ContainerFileContent -ContainerFile $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [byte]
            $Result[0] | Should -Be ([byte]88) # 'X'
        }

        Context 'Parameter Sets' {
            It 'Id' {
                # Named
                { Get-ContainerFileContent -ContainerId 'container_abc123' -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ContainerFileContent 'container_abc123' 'file_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'container_abc123' | Get-ContainerFileContent -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{ContainerId = 'container_abc123' } | Get-ContainerFileContent -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }

            It 'ContainerFile' {
                $InObject = [pscustomobject]@{
                    PSTypeName   = 'PSOpenAI.Container.File'
                    id           = 'file_abc123'
                    container_id = 'container_abc123'
                }
                # Named
                { Get-ContainerFileContent -ContainerFile $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-ContainerFileContent $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-ContainerFileContent -FileId 'file_abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }
        }
    }
}
