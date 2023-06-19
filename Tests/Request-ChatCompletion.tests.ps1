#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ChatCompletion' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Chat completion' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "chatcmpl-123",
    "object": "chat.completion",
    "created": 1677652288,
    "choices": [{
        "index": 0,
        "message": {
        "role": "assistant",
        "content": "Hello there, how may I assist you today?"
        },
        "finish_reason": "stop"
    }],
    "usage": {
        "prompt_tokens": 9,
        "completion_tokens": 12,
        "total_tokens": 21
    }
}
'@ }
            { $script:Result = Request-ChatCompletion -Message 'test' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer | Should -Be 'Hello there, how may I assist you today?'
            $Result.created | Should -BeOfType [datetime]
            $Result.Message | Should -Be 'test'
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be 'test'
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[1].Content | Should -Be 'Hello there, how may I assist you today?'
        }

        It 'Stream output' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                '{"id":"chatcmpl-sf547Pa","object":"chat.completion.chunk","created":1679839328,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":"ECHO"},"index":0,"finish_reason":null}]}'
            }
            $Result = Request-ChatCompletion -Message 'test' -Stream -InformationVariable StreamOut -ea Stop
            Should -InvokeVerifiable
            $Result | Should -Be 'ECHO'
            $StreamOut | Should -Be 'ECHO'
        }

        It 'Function call (non execution)' {
            Mock Test-Path { return $true }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "chatcmpl-123",
    "object": "chat.completion",
    "created": 1677652288,
    "choices": [{
        "index": 0,
        "message": {
          "role": "assistant",
          "content": null,
          "function_call": {
            "name": "Test-Path",
            "arguments": "{\n  \"Path\": [\"C:\\test.txt\"],\n  \"PathType\": \"Leaf\"\n}"
          }
        },
        "finish_reason": "function_call"
    }],
    "usage": {
        "prompt_tokens": 221,
        "completion_tokens": 30,
        "total_tokens": 251
    }
}
'@ }
            $FunctionSpec = @{
                name        = 'Test-Path'
                description = 'test path'
                parameters  = @{
                    type       = 'object'
                    properties = @{
                        'Path'     = @{type = 'string' }
                        'PathType' = @{type = 'string'; enum = ('Leaf', 'Container', 'Any') }
                    }
                    required   = @('Path')
                }
            }

            { $script:Result = Request-ChatCompletion -Message 'test' -Functions $FunctionSpec -InvokeFunctionOnCallMode None -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName 'Test-Path' -Times 0
            Should -InvokeVerifiable
            $Result.Answer | Should -BeNullOrEmpty
            $Result.Message | Should -Be 'test'
            $Result.choices[0].message.function_call.name | Should -BeExactly 'Test-Path'
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be 'test'
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[1].Content | Should -BeNullOrEmpty
        }

        It 'Use collect endpoint' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @"
{"choices": [{"message": {"content": "$($PesterBoundParameters.Uri)"}}]}
"@ }
            $Result = Request-ChatCompletion -Message 'test'
            $Result.Answer | Should -Match 'chat/completions'
        }

        It 'Request-ChatGPT as alias' {
            $Alias = Get-Alias 'Request-ChatGPT' -ea Ignore
            $Alias.ResolvedCommandName | Should -Be 'Request-ChatCompletion'
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''

            # To avoid api rate limit
            # Free trial tier has 20 requests per minutes
            Start-Sleep -Seconds 3.1
        }

        It 'Chat completion' {
            { $script:Result = Request-ChatCompletion -Message '君の名は？' -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -BeOfType [string]
            $Result.created | Should -BeOfType [datetime]
            $Result.Message | Should -Be '君の名は？'
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be '君の名は？'
            $Result.History[1].Role | Should -Be 'assistant'
        }

        It 'Chat completion, multiple answers' {
            { $script:Result = Request-ChatCompletion -Message 'What your name' -NumberOfAnswers 2 -MaxTokens 10 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 2
        }

        It 'Pipeline input (Message)' {
            { $script:Result = 'What your name' | Request-ChatCompletion -MaxTokens 10 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 1
        }

        It 'Pipeline input (Conversations)' {
            { $script:First = Request-ChatCompletion -Message 'What' -MaxTokens 10 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            { $script:Result = $script:First | Request-ChatCompletion -Message 'When' -MaxTokens 10 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be 'What'
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[2].Role | Should -Be 'user'
            $Result.History[2].Content | Should -Be 'When'
            $Result.History[3].Role | Should -Be 'assistant'
        }

        It 'Pipeline input (Fully parameterized)' {
            $ExampleMessages = [pscustomobject]@{
                History = @(
                    @{
                        'role'    = 'system'
                        'content' = 'You are a helpful, pattern-following assistant that translates corporate jargon into plain English.'
                    },
                    @{
                        'role'    = 'system'
                        'name'    = 'example_user'
                        'content' = 'New synergies will help drive top-line growth.'
                    },
                    @{
                        'role'    = 'system'
                        'name'    = 'example_assistant'
                        'content' = 'Things working well together will increase revenue.'
                    },
                    @{
                        'role'    = 'system'
                        'name'    = 'example_user'
                        'content' = "Let's circle back when we have more bandwidth to touch base on opportunities for increased leverage."
                    },
                    @{
                        'role'    = 'system'
                        'name'    = 'example_assistant'
                        'content' = "Let's talk later when we're less busy about how to do better."
                    },
                    @{
                        'role'    = 'user'
                        'content' = "This late pivot means we don't have time to boil the ocean for the client deliverable."
                    }
                )
            }
            { $script:Result = $ExampleMessages | Request-ChatCompletion -MaxTokens 10 -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -BeOfType [string]
        }

        It 'Function call (non execution)' {
            $FunctionSpec = @{
                name        = 'Test-Connection'
                description = 'The Test-Connection command sends pings to remote computers and returns replies.'
                parameters  = @{
                    type       = 'object'
                    properties = @{
                        'ComputerName' = @{type = 'string'; description = 'Specifies the target host name or ip address, e.g, "8.8.8.8" ' }
                        'Count'        = @{type = 'integer'; description = 'Specifies the number of echo requests to send. The default value is 4.' }
                    }
                    required   = @('ComputerName')
                }
            }

            $Message = 'Ping the Google Public DNS address three times and briefly report the results.'
            { $script:Result = Request-ChatCompletion `
                    -Message $Message `
                    -Model gpt-3.5-turbo-0613 `
                    -Temperature 0.1 `
                    -Functions $FunctionSpec `
                    -InvokeFunctionOnCallMode None `
                    -ea Stop `
            } | Should -Not -Throw
            $Result.Answer | Should -BeNullOrEmpty
            $Result.Message | Should -Be $Message
            $Result.choices[0].message.function_call.name | Should -BeExactly 'Test-Connection'
        }

        It 'Function call (implicit execution)' {
            $FunctionSpec = @{
                name        = 'Test-Connection'
                description = 'The Test-Connection command sends pings to remote computers and returns replies.'
                parameters  = @{
                    type       = 'object'
                    properties = @{
                        'ComputerName' = @{type = 'string'; description = 'Specifies the target host name or ip address, e.g, "8.8.8.8" ' }
                        'Count'        = @{type = 'integer'; description = 'Specifies the number of echo requests to send. The default value is 4.' }
                    }
                    required   = @('ComputerName')
                }
            }

            $Message = 'Ping the Google Public DNS address three times and briefly report the results.'
            { $script:Result = Request-ChatCompletion `
                    -Message $Message `
                    -Model gpt-3.5-turbo-0613 `
                    -Temperature 0.1 `
                    -Functions $FunctionSpec `
                    -InvokeFunctionOnCallMode Auto `
                    -ea Stop `
            } | Should -Not -Throw
            $Result.Answer | Should -Not -BeNullOrEmpty
            $Result.Message | Should -Be $Message
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be $Message
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[1].function_call | Should -Not -BeNullOrEmpty
            $Result.History[2].Role | Should -Be 'function'
            $Result.History[2].Name | Should -Be 'Test-Connection'
            $Result.History[3].Role | Should -Be 'assistant'
            $Result.History[3].Content | Should -Not -BeNullOrEmpty
        }

        It 'Stream output' {
            $Result = Request-ChatCompletion `
                -Message 'Please describe about ChatGPT' `
                -MaxTokens 32 `
                -Stream `
                -InformationVariable Info `
                -TimeoutSec 30 -ea Stop `
            | select -First 10
            $Result | Should -HaveCount 10
            ([string[]]$Info) | Should -Be ([string[]]$Result)
        }

        It 'Retrying with exponential backoff on Rate-Limit exceeds error' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-WebRequest {
                iwr https://httpstat.us/429 -UseBasicParsing
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 3 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 3
            # The retry interval is given a jitter of 0.8 to 1.2 times, so the minimum is 5.6 seconds. ((1+2+4)*0.8)
            $StopWatch.ElapsedMilliseconds | Should -BeGreaterOrEqual 5600
        }

        It 'Retrying with exponential backoff on server error' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-WebRequest {
                iwr https://httpstat.us/500 -UseBasicParsing
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 1 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 1
            # The retry interval is given a jitter of 0.8 to 1.2 times, so the minimum is 0.8 seconds.
            $StopWatch.ElapsedMilliseconds | Should -BeGreaterOrEqual 800
        }
    }
}
