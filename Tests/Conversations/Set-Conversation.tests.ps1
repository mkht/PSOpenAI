#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-Conversation' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName New-Conversation {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation'
                    id         = 'conv_abc123'
                    metadata   = [pscustomobject]@{ meta = 'meta-1' }
                    created_at = [datetime]::Today
                    Items      = @()
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Set conversation with ID' {
            { $script:Result = Set-Conversation -ConversationId 'conv_abc123' -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
            Should -Invoke New-Conversation -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Conversation'
            $Result.id | Should -Be 'conv_abc123'
            $Result.metadata.meta | Should -Be 'meta-1'
        }

        Context 'Parameter Sets' {
            It 'Conversation object' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Conversation'
                    id         = 'conv_abc123'
                    metadata   = [pscustomobject]@{ meta = 'meta-1' }
                    created_at = [datetime]::Today
                    Items      = @()
                }
                # Named
                { Set-Conversation -Conversation $InObject -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Position
                { Set-Conversation $InObject -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Set-Conversation -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName New-Conversation -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Set-Conversation -ConversationId 'conv_abc123' -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Position
                { Set-Conversation 'conv_abc123' -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'conv_abc123' | Set-Conversation -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                # Property name
                { [pscustomobject]@{conversation_id = 'conv_abc123' } | Set-Conversation -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName New-Conversation -ModuleName $script:ModuleName -Times 4 -Exactly
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            $script:Result = $null
        }

        AfterEach {
            if (Get-Command Remove-Conversation -ErrorAction SilentlyContinue) {
                $script:Result | Remove-Conversation -ea SilentlyContinue
            }
        }

        It 'Update conversation' {
            $conv = New-Conversation
            $ConvId = $conv.id
            $conv.id | Should -BeLike 'conv_*'
            { $script:Result = $conv | Set-Conversation -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Not -Throw
            $Result.id | Should -Be $ConvId
            $Result.metadata.meta | Should -Be 'meta-1'
        }

        It 'Error on non existent conversation' {
            $conv_id = 'conv_notexist'
            { $conv | Set-Conversation -MetaData @{meta = 'meta-1' } -ea Stop } | Should -Throw
        }
    }
}
