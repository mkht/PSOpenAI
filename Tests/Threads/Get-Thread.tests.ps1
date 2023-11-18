#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Thread' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "thread_abc123",
    "object": "thread",
    "created_at": 1699014083,
    "metadata": {}
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get thread with ID' {
            { $script:Result = Get-Thread -InputObject 'thread_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result.id | Should -BeExactly 'thread_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
        }

        It 'Get thread with Thread object' {
            $InObject = [pscustomobject]@{
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { Get-Thread -InputObject $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Pipeline input with ID' {
            $InObject = 'thread_abc123'
            { $InObject | Get-Thread -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Pipeline input with Object' {
            $InObject = [pscustomobject]@{
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $InObject | Get-Thread -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $InObject | Get-Thread -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Get thread' {
            $thread = New-Thread
            { $script:Result = $thread | Get-Thread -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'thread_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Messages | Should -HaveCount 0
        }

        It 'Error on non existent thread' {
            $thread_id = 'thread_notexit'
            { $thread_id | Get-Thread -ea Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }
    }
}
