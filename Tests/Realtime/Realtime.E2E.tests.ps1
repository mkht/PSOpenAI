#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Realtime E2E Test' {
    Context 'End-to-End tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext
            $script:ReceiveEventSource = 'PSOpenAI.Realtime.ReceiveMessage'
            $script:SendEventSource = 'PSOpenAI.Realtime.SendMessage'
        }

        Context 'Text In / Text Out' {
            BeforeAll {
                Disconnect-RealtimeSession

                $global:ReceiveStack = [System.Collections.Concurrent.ConcurrentStack[object]]::new()
                $global:SendStack = [System.Collections.Concurrent.ConcurrentStack[string]]::new()

                # Register event handler
                $null = Register-EngineEvent -SourceIdentifier $script:ReceiveEventSource -Action {
                    $global:ReceiveStack.Push($Event.SourceArgs[0])
                }
                $null = Register-EngineEvent -SourceIdentifier $script:SendEventSource -Action {
                    $global:SendStack.Push($Event.SourceArgs[0])
                }

                $script:Instructions = 'You are a helpful assistant.'
                $script:PromptMessage = 'Name one of the most famous people in Spain.'
                $script:PromptNextMessage = 'What about Germany?'
            }

            AfterAll {
                $global:ReceiveStack.Clear()
                $global:SendStack.Clear()
                Unregister-Event -SourceIdentifier $script:ReceiveEventSource
                Unregister-Event -SourceIdentifier $script:SendEventSource
                Get-Job | Remove-Job -Force
            }

            It 'STEP1: Connect to session' {
                { Connect-RealtimeSession -Model 'gpt-4o-mini-realtime-preview-2024-12-17' -ea Stop } | Should -Not -Throw
            }

            It 'STEP1-1: Only one session is allowed' {
                { Connect-RealtimeSession -Model 'gpt-4o-mini-realtime-preview-2024-12-17' -ea Stop } | Should -Throw
            }

            It 'STEP2: Configure session' {
                $item = $null
                { Set-RealtimeSessionConfiguration `
                        -Instructions $script:Instructions `
                        -Modalities 'text' `
                        -Temperature 0.6 `
                        -MaxResponseOutputTokens 32 `
                        -ea Stop } | Should -Not -Throw
                Start-Sleep -Seconds 1

                $null = $global:SendStack.TryPeek([ref]$item)
                $item = $item | ConvertFrom-Json
                $item.type | Should -BeExactly 'session.update'
                $item.session.instructions | Should -BeExactly $script:Instructions

                $null = $global:ReceiveStack.TryPeek([ref]$item)
                $item.type | Should -BeExactly 'session.updated'
                $item.session.instructions | Should -BeExactly $script:Instructions
            }

            It 'STEP3: Input a user message' {
                $item = $null
                { Add-RealtimeSessionItem -Role 'user' -Message $script:PromptMessage -ea Stop } | Should -Not -Throw
                Start-Sleep -Seconds 1

                $null = $global:SendStack.TryPeek([ref]$item)
                $item = $item | ConvertFrom-Json
                $item.type | Should -BeExactly 'conversation.item.create'

                $null = $global:ReceiveStack.TryPeek([ref]$item)
                $item.type | Should -BeExactly 'conversation.item.created'
            }

            It 'STEP4: Trigger response' {
                $item = $null
                { Request-RealtimeSessionResponse -MaxOutputTokens 12 -ea Stop } | Should -Not -Throw
                Start-Sleep -Seconds 5

                $null = $global:SendStack.TryPeek([ref]$item)
                $item = $item | ConvertFrom-Json
                $item.type | Should -BeExactly 'response.create'

                $null = $global:ReceiveStack.TryPeek([ref]$item)
                $item.type | Should -BeExactly 'response.done'
                $item.response.output.role | Should -Be 'assistant'

                $items = $global:ReceiveStack.ToArray() | select -ExpandProperty type
                $items | Should -Not -Contain 'error'
                $items | Should -Contain 'response.content_part.added'
                $items | Should -Contain 'response.text.delta'
                $items | Should -Contain 'response.content_part.done'
                $items | Should -Contain 'response.output_item.done'
            }

            It 'STEP5: Input a next message (with trigger response)' {
                $item = $null
                { Add-RealtimeSessionItem -Role 'user' -Message $script:PromptNextMessage -TriggerResponse -ea Stop } | Should -Not -Throw
                Start-Sleep -Seconds 12

                $null = $global:SendStack.TryPeek([ref]$item)
                $item = $item | ConvertFrom-Json
                $item.type | Should -BeExactly 'response.create'

                $null = $global:ReceiveStack.TryPeek([ref]$item)
                $item.type | Should -BeExactly 'response.done'
                $item.response.output.role | Should -Be 'assistant'
            }

            It 'STEP6: Close session' {
                { Disconnect-RealtimeSession -ea Stop } | Should -Not -Throw
            }
        }
    }
}