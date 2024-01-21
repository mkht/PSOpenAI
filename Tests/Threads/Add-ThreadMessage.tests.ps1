#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Set-Thread' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "msg_abc123",
    "object": "thread.message",
    "created_at": 1699017614,
    "thread_id": "thread_abc123",
    "role": "user",
    "content": [
        {
        "type": "text",
        "text": {
            "value": "How does AI work? Explain it in simple terms.",
            "annotations": []
        }
        }
    ],
    "file_ids": [],
    "assistant_id": null,
    "run_id": null,
    "metadata": {}
    }
'@ }
            Mock -Verifiable -ModuleName $script:ModuleName Get-Thread {
                [pscustomobject]@{
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

        It 'Add thread messages' {
            { $script:Result = Add-ThreadMessage `
                    -InputObject 'thread_abc123' `
                    -Message 'How does AI work? Explain it in simple terms.' `
                    -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
            $script:Result | Should -BeNullOrEmpty
        }

        It 'Input from pipeline with thread object. And PassThru' {
            $thread = [pscustomobject]@{
                id         = 'thread_abc123'
                metadata   = @{}
                created_at = [datetime]::Today
                Messages   = @()
            }
            { $script:Result = $thread | Add-ThreadMessage `
                    -Message 'How does AI work? Explain it in simple terms.' `
                    -PassThru `
                    -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 1 -Exactly
            $script:Result.id | Should -Be 'thread_abc123'
        }


        It 'Error on invalid input' {
            $InObject = [datetime]::Today
            { $script:Result = Add-ThreadMessage `
                    -InputObject $InObject `
                    -Message 'How does AI work? Explain it in simple terms.' `
                    -ea Stop } | Should -Throw
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 0 -Exactly
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            $script:Result | Remove-Thread -ea SilentlyContinue
        }

        It 'Add thread message' {
            $thread = New-Thread
            { $script:Result = $thread | Add-ThreadMessage `
                    -Message 'How does AI work? Explain it in simple terms.' `
                    -PassThru `
                    -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'thread_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Messages | Should -HaveCount 1
            $Result.Messages[0].content.text.value | Should -BeExactly 'How does AI work? Explain it in simple terms.'
        }

        It 'Add 3 thread messages' {
            $thread = New-Thread
            { $script:Result = $thread |`
                    Add-ThreadMessage -Message 'Hello.' -PassThru -ea Stop | `
                    Add-ThreadMessage -Message ' How' -PassThru -ea Stop | `
                    Add-ThreadMessage -Message ' are you?' -PassThru -ea Stop
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'thread_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Messages | Should -HaveCount 3
            $Result.Messages[0].content.text.value | Should -BeExactly 'Hello.'
            $Result.Messages[1].content.text.value | Should -BeExactly ' How'
            $Result.Messages[2].content.text.value | Should -BeExactly ' are you?'
        }
    }
}
