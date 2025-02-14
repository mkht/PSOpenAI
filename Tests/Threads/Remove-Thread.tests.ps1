#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
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
            { $script:Result = Remove-Thread -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Remove thread with Thread object' {
            $InObject = [pscustomobject]@{
                PSTypeName = 'PSOpenAI.Thread'
                id         = 'thread_abc123'
                object     = 'thread'
                created_at = [datetime]::Today
            }
            { $script:Result = Remove-Thread -Thread $InObject -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        Context 'Parameter Sets' {
            It 'Thread' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.Thread'
                    id         = 'thread_abc123'
                }
                # Named
                { Remove-Thread -Thread $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Thread $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Remove-Thread -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly
            }

            It 'Id' {
                # Named
                { Remove-Thread -ThreadId 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Remove-Thread 'thread_abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'thread_abc123' | Remove-Thread -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{thread_id = 'thread_abc123' } | Remove-Thread -ea Stop } | Should -Not -Throw
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
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterAll {
            Clear-OpenAIContext
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
