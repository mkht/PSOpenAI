#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-Conversation' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Create conversation' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "conv_abc1234",
  "object": "conversation",
  "created_at": 1755880318,
  "metadata": {"data": "example"}
}
'@ }
            { $script:Result = New-Conversation -MetaData @{'data' = 'example' } -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.id | Should -BeExactly 'conv_abc1234'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Conversation'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Items.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Items | Should -HaveCount 0
            $Result.metadata.data | Should -BeExactly 'example'
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            # Remove-Conversation コマンドが存在する場合のみ
            if (Get-Command Remove-Conversation -ErrorAction SilentlyContinue) {
                $script:Result | Remove-Conversation -ea SilentlyContinue
            }
        }

        It 'Create conversation' {
            { $script:Result = New-Conversation -MetaData @{'foo' = 'bar' } -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'conv_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Items.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Items | Should -HaveCount 0
        }
    }
}
