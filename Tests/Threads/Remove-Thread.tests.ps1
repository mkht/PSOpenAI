#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-Thread' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "thread_abc123",
    "object": "thread.deleted",
    "deleted": true
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove thread with ID' {
            { $script:Result = Remove-Thread -InputObject 'thread_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Remove thread with Thread object' {
            $InObject = [pscustomobject]@{
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $script:Result = Remove-Thread -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Pipeline input with ID' {
            $InObject = 'thread_abc123'
            { $InObject | Remove-Thread -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Pipeline input with Object' {
            $InObject = [pscustomobject]@{
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $InObject | Remove-Thread -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Remove-Thread -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove thread' {
            $thread = New-Thread
            { $thread | Remove-Thread -ea Stop } | Should -Not -Throw
            $thread = try { $thread | Get-Thread -ea Ignore }catch {}
            $thread | Should -BeNullOrEmpty
        }

        It 'Error on non existent thread' {
            $thread_id = 'thread_notexit'
            { $thread_id | Remove-Thread -ea Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }
    }
}
