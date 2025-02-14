#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Thread' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadMessage {
                [PSCustomObject]@{
                    PSTypeName     = 'PSOpenAI.Thread.Message'
                    'id'           = 'msg_abc123'
                    'object'       = 'thread.message'
                    'created_at'   = [datetime]::Today
                    'thread_id'    = 'thread_abc123'
                    'role'         = 'user'
                    'content'      = @(
                        @{
                            'type' = 'text'
                            'text' = @{
                                'value'       = 'How does AI work? Explain it in simple terms.'
                                'annotations' = @()
                            }
                        }
                    )
                    'assistant_id' = 'asst_abc123'
                    'run_id'       = 'run_abc123'
                }
            }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "thread_abc123",
    "object": "thread",
    "created_at": 1699014083,
    "metadata": {},
    "tool_resources": {
        "code_interpreter": {
        "file_ids": []
        }
    }
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get thread with ID' {
            { $script:Result = Get-Thread -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-ThreadMessage -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -BeExactly 'thread_abc123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Thread'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
        }

        Context 'Parameter Sets' {
            It 'Get_Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Get-Thread -Thread $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Thread $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-Thread -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Get_Id' {
                # Named
                { Get-Thread -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Thread 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Get-Thread -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123' } | Get-Thread -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly
            }
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
            if ($script:thread) {
                $script:thread | Remove-Thread
                $script:thread = $null
            }
        }

        It 'Get thread' {
            $script:thread = New-Thread
            { $script:Result = $thread | Get-Thread -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'thread_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Messages | Should -HaveCount 0
        }

        It 'Error on non existent thread' {
            $thread_id = 'thread_notexit'
            { $thread_id | Get-Thread -ea Stop } | Should -Throw
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            # Set Context for Azure OpenAI
            $AzureContext = @{
                ApiType    = 'Azure'
                AuthType   = 'Azure'
                ApiKey     = $env:AZURE_OPENAI_API_KEY
                ApiBase    = $env:AZURE_OPENAI_ENDPOINT
                TimeoutSec = 30
            }
            Set-OpenAIContext @AzureContext
            $script:Model = 'gpt-4o-mini'
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            if ($script:thread) {
                $script:thread | Remove-Thread
                $script:thread = $null
            }
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'Get thread' {
            $script:thread = New-Thread
            { $script:Result = $thread | Get-Thread -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'thread_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Messages | Should -HaveCount 0
        }

        It 'Error on non existent thread' {
            $thread_id = 'thread_notexit'
            { $thread_id | Get-Thread -ea Stop } | Should -Throw
        }
    }
}
