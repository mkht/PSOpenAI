#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-Thread' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName New-Thread {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                    metadata   = @{}
                    created_at = [datetime]::Today
                    Messages   = @()
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Set thread with ID' {
            { $script:Result = Set-Thread -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke New-Thread -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread'
            $script:Result.id | Should -Be 'thread_abc123'
        }

        Context 'Parameter Sets' {
            It 'Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Set-Thread -Thread $InObject -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Position
                { Set-Thread $InObject -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Set-Thread -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName New-Thread -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Set-Thread -ThreadId 'thread_abc123' -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Position
                { Set-Thread 'thread_abc123' -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Set-Thread -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{thread_id = 'thread_abc123' } | Set-Thread -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName New-Thread -ModuleName $script:ModuleName -Times 4 -Exactly
            }
        }
    }
}
