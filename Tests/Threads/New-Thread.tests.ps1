#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-Thread' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Create thread' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "thread_abc1234",
    "object": "thread",
    "created_at": 1700287185,
    "metadata": {}
}
'@ }
            { $script:Result = New-Thread -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.id | Should -BeExactly 'thread_abc1234'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Messages | Should -HaveCount 0
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Result | Remove-Thread -ea SilentlyContinue
        }

        It 'Create thread' {
            { $script:Result = New-Thread -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'thread_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Messages | Should -HaveCount 0
        }
    }
}
