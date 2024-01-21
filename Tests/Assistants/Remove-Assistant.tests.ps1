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
            { $script:Result = Remove-Assistant -InputObject 'asst_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Remove assistant with assistant object' {
            $InObject = [pscustomobject]@{
                id         = 'asst_abc123'
                object     = 'assistant'
                created_at = [datetime]::Today
            }
            { $script:Result = Remove-Assistant -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Pipeline input with ID' {
            $InObject = 'asst_abc123'
            { $InObject | Remove-Assistant -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Pipeline input with Object' {
            $InObject = [pscustomobject]@{
                id         = 'asst_abc123'
                object     = 'assistant'
                created_at = [datetime]::Today
            }
            { $InObject | Remove-Assistant -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Remove-Assistant -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
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
