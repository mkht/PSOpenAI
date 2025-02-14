#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Add-ThreadMessage' {
    Context 'Unit tests (offline)' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                @'
{
    "id": "msg_abc123",
    "object": "thread.message",
    "created_at": 1713226573,
    "assistant_id": null,
    "thread_id": "thread_abc123",
    "run_id": null,
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
    "attachments": [],
    "metadata": {}
}
'@
            }
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
            { $splat = @{
                    ThreadId    = 'thread_abc123'
                    Message     = 'How does AI work? Explain it in simple terms.'
                    ErrorAction = 'Stop'
                }
                $script:Result = Add-ThreadMessage @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Get-Thread -ModuleName $script:ModuleName
            $script:Result | Should -BeNullOrEmpty
        }

        It 'Add thread messages with PassThru' {
            { $splat = @{
                    ThreadId    = 'thread_abc123'
                    Message     = 'How does AI work? Explain it in simple terms.'
                    PassThru    = $true
                    ErrorAction = 'Stop'
                }
                $script:Result = Add-ThreadMessage @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-Thread -ModuleName $script:ModuleName -Times 1 -Exactly
            $script:Result | Should -Not -BeNullOrEmpty
        }

        It 'Wait for run complete - 1' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                    status     = 'in_progress'
                }
            }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-ThreadRun {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
            }
            { $splat = @{
                    ThreadId           = 'thread_abc123'
                    Message            = 'How does AI work? Explain it in simple terms.'
                    WaitForRunComplete = $true
                    ErrorAction        = 'Stop'
                }
                $script:Result = Add-ThreadMessage @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-ThreadRun -ModuleName $script:ModuleName -Times 1
            $script:Result | Should -BeNullOrEmpty
        }

        It 'Wait for run complete - 2' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                    status     = 'requires_action'
                }
            }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-ThreadRun {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
            }
            { $splat = @{
                    ThreadId           = 'thread_abc123'
                    Message            = 'How does AI work? Explain it in simple terms.'
                    WaitForRunComplete = $true
                    ErrorAction        = 'Stop'
                }
                $script:Result = Add-ThreadMessage @splat
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Not -Invoke Wait-ThreadRun -ModuleName $script:ModuleName
            $script:Result | Should -BeNullOrEmpty
        }

        It 'Wait for run complete - timeout' {
            Mock -Verifiable -ModuleName $script:ModuleName Get-ThreadRun {
                [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread.Run'
                    id         = 'run_abc123'
                    thread_id  = 'thread_abc123'
                    status     = 'in_progress'
                }
            }
            { $splat = @{
                    ThreadId           = 'thread_abc123'
                    Message            = 'How does AI work? Explain it in simple terms.'
                    WaitForRunComplete = $true
                    TimeoutSec         = 2
                    ErrorAction        = 'Stop'
                }
                $script:Result = Add-ThreadMessage @splat
            } | Should -Throw -ExceptionType ([OperationCanceledException])
            Should -Not -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            Should -Invoke Get-ThreadRun -ModuleName $script:ModuleName -Times 1
            $script:Result | Should -BeNullOrEmpty
        }

        Context 'Parameter Sets' {
            It 'Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Add-ThreadMessage -Thread $InObject -Message 'Hi' -ea Stop } | Should -Not -Throw
                # Positional
                { Add-ThreadMessage -Thread $InObject 'Hi' -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Add-ThreadMessage -Message 'Hi' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Add-ThreadMessage -ThreadId 'thread_abc123' -Message 'Hi' -ea Stop } | Should -Not -Throw
                # Positional
                { Add-ThreadMessage 'Hi' -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Add-ThreadMessage 'Hi' -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123'; message = 'Hi' } | Add-ThreadMessage -ea Stop } | Should -Not -Throw
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
            $script:Result | Remove-Thread -ea SilentlyContinue
        }

        It 'Add thread message' {
            $thread = New-Thread
            { $splat = @{
                    Message     = 'How does AI work? Explain it in simple terms.'
                    PassThru    = $true
                    ErrorAction = 'Stop'
                }
                $script:Result = $thread | Add-ThreadMessage @splat
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'thread_*'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
            $Result.Messages | Should -HaveCount 1
            $Result.Messages[0].content[0].text.value | Should -BeExactly 'How does AI work? Explain it in simple terms.'
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
                $Result.Messages[0].content[0].text.value | Should -BeExactly 'Hello.'
                $Result.Messages[1].content[0].text.value | Should -BeExactly ' How'
                $Result.Messages[2].content[0].text.value | Should -BeExactly ' are you?'
            }

            It 'Add thread message with image url' {
                $thread = New-Thread
                { $splat = @{
                        Message     = 'Please explain about this image.'
                        Images      = 'https://upload.wikimedia.org/wikipedia/commons/8/8c/Churchillaan_16_%28132%29_-_131070_-_onroerenderfgoed.jpg'
                        PassThru    = $true
                        ErrorAction = 'Stop'
                    }
                    $script:Result = $thread | Add-ThreadMessage @splat
                } | Should -Not -Throw
                $Result.id | Should -BeLike 'thread_*'
                $Result.created_at | Should -BeOfType [datetime]
                $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
                $Result.Messages | Should -HaveCount 1
                $Result.Messages | Should -HaveCount 1
                $Result.Messages[0].content[0].text.value | Should -BeExactly 'Please explain about this image.'
                $Result.Messages[0].content[1].type | Should -Be 'image_url'
            }
        }

        Context 'Integration tests (Azure)' -Tag 'Azure' {

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
                $script:Result | Remove-Thread -ea SilentlyContinue
            }

            AfterAll {
                Clear-OpenAIContext
            }

            It 'Add thread message' {
                $thread = New-Thread
                { $splat = @{
                        Message     = 'How does AI work? Explain it in simple terms.'
                        PassThru    = $true
                        ErrorAction = 'Stop'
                    }
                    $script:Result = $thread | Add-ThreadMessage @splat
                } | Should -Not -Throw
                $Result.id | Should -BeLike 'thread_*'
                $Result.created_at | Should -BeOfType [datetime]
                $Result.Messages.GetType().Fullname | Should -Be 'System.Object[]'
                $Result.Messages | Should -HaveCount 1
                $Result.Messages[0].content[0].text.value | Should -BeExactly 'How does AI work? Explain it in simple terms.'
            }
        }
    }