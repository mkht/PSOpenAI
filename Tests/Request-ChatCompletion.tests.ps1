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

        It 'Output format = raw_response' {
            $Response_json = @'
{
    "id": "chatcmpl-123",
    "object": "chat.completion"
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $Response_json }
            { $script:Result = Request-ChatCompletion -Message 'test' -Format raw_response -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeExactly $Response_json
        }

        It 'Function call (non execution) - Legacy' {
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
            Should -Invoke -CommandName 'Test-Path' -Times 0 -Exactly
            Should -InvokeVerifiable
            $Result.Answer | Should -BeNullOrEmpty
            $Result.Message | Should -Be 'test'
            $Result.choices[0].message.function_call.name | Should -BeExactly 'Test-Path'
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be 'test'
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[1].Content | Should -BeNullOrEmpty
        }

        It 'Tool calls (non execution)' {
            Mock Test-Path { return $true }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "chatcmpl-8Iv2FuLeNiC4TLvU0q1fYBUt4WFop",
    "object": "chat.completion",
    "created": 1699458335,
    "model": "gpt-3.5-turbo-0125",
    "choices": [
        {
        "index": 0,
        "message": {
            "role": "assistant",
            "content": null,
            "tool_calls": [
            {
                "id": "call_WBhNSCSE4saHB4KXuSxLXiRW",
                "type": "function",
                "function": {
                "name": "Test-Path",
                "arguments": "{\"Path\":[\"C:\\test.txt\"],\"PathType\":\"Leaf\"}"
                }
            }
            ]
        },
        "finish_reason": "tool_calls"
        }
    ],
    "usage": {
        "prompt_tokens": 255,
        "completion_tokens": 23,
        "total_tokens": 278
    },
    "system_fingerprint": "fp_eeff13180a"
    }
'@ }
            $ToolsSpec = @(@{
                    type     = 'function'
                    function = @{
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
                })

            { $script:Result = Request-ChatCompletion -Message 'test' -Tools $ToolsSpec -InvokeTools None -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName 'Test-Path' -Times 0 -Exactly
            Should -InvokeVerifiable
            $Result.Answer | Should -BeNullOrEmpty
            $Result.Message | Should -Be 'test'
            $Result.choices[0].message.tool_calls.GetType().Name | Should -Be 'Object[]'
            $Result.choices[0].message.tool_calls[0].id | Should -BeOfType [string]
            $Result.choices[0].message.tool_calls[0].type | Should -Be 'function'
            $Result.choices[0].message.tool_calls[0].function.name | Should -BeExactly 'Test-Path'
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

    Context 'Retry Strategies' -Tag 'Offline' {

        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-WebRequest {
                if ($PSVersionTable.PSVersion.Major -le 5) { $e = [System.Net.WebException]::new('error') }
                else { $e = [System.Net.Http.HttpRequestException]::new() }
                throw $e
            }
        }

        It 'Should NOT Retry except 429 and 5xx error.' {
            Mock -ModuleName $script:ModuleName Parse-WebExceptionResponse {
                class MockException : System.Exception {
                    [int]$StatusCode = 404
                    [string]$ErrorReason = 'NotFound'
                    [hashtable]$Response = $null
                    MockException() : base ('NotFound') {}
                }
                return ([MockException]::new())
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 3 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Should NOT Retry on Quota-Limit exceeds error.' {
            Mock -ModuleName $script:ModuleName Parse-WebExceptionResponse {
                class MockException : System.Exception {
                    [int]$StatusCode = 429
                    [string]$ErrorReason = 'TooManyRequests'
                    [hashtable]$Response = $null
                    MockException() : base ('Quota Limit Error') {}
                }
                return ([MockException]::new())
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 3 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Should retry if the response contains x-should-retry header and the value is "true"' {
            Mock -ModuleName $script:ModuleName Parse-WebExceptionResponse {
                class MockHeaders : System.Net.Http.Headers.HttpHeaders {
                    [hashtable]$Headers = @{'x-should-retry' = 'true'; 'retry-after-ms' = '20' }
                    [bool] Contains([string]$header) { return ($this.Headers.Contains($header)) }
                    [string[]] GetValues([string]$header) { return [string[]]@($this.Headers[$header]) }
                }
                class MockException : System.Exception {
                    [int]$StatusCode = 404
                    [string]$ErrorReason = 'NotFound'
                    [hashtable]$Response = @{ Headers = ([MockHeaders]::new()) }
                    MockException() : base ('NotFound') {}
                }
                return ([MockException]::new())
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 1 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 2 -Exactly
        }

        It 'Should NOT retry if the response contains x-should-retry header and the value is "false"' {
            Mock -ModuleName $script:ModuleName Parse-WebExceptionResponse {
                class MockHeaders : System.Net.Http.Headers.HttpHeaders {
                    [hashtable]$Headers = @{'x-should-retry' = 'false'; 'retry-after-ms' = '20' }
                    [bool] Contains([string]$header) { return ($this.Headers.Contains($header)) }
                    [string[]] GetValues([string]$header) { return [string[]]@($this.Headers[$header]) }
                }
                class MockException : System.Exception {
                    [int]$StatusCode = 429
                    [string]$ErrorReason = 'TooManyRequests'
                    [hashtable]$Response = @{ Headers = ([MockHeaders]::new()) }
                    MockException() : base ('Rate-Limit') {}
                }
                return ([MockException]::new())
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 1 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        It 'Retry on Rate-Limit exceeds error and the interval follows retry-after-ms header value.' {
            Mock -ModuleName $script:ModuleName Parse-WebExceptionResponse {
                class MockHeaders : System.Net.Http.Headers.HttpHeaders {
                    [hashtable]$Headers = @{'retry-after-ms' = '200'; 'retry-after' = '3' }
                    [bool] Contains([string]$header) { return ($this.Headers.Contains($header)) }
                    [string[]] GetValues([string]$header) { return [string[]]@($this.Headers[$header]) }
                }
                class MockException : System.Exception {
                    [int]$StatusCode = 429
                    [string]$ErrorReason = 'TooManyRequests'
                    [hashtable]$Response = @{ Headers = ([MockHeaders]::new()) }
                    MockException() : base ('Rate-Limit') {}
                }
                return ([MockException]::new())
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 1 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 2 -Exactly
            # The retry interval should around 200ms
            $StopWatch.ElapsedMilliseconds | Should -BeGreaterOrEqual 200
            $StopWatch.ElapsedMilliseconds | Should -BeLessThan 400
        }

        It 'Retry on Rate-Limit exceeds error and the interval follows retry-after header value.' {
            Mock -ModuleName $script:ModuleName Parse-WebExceptionResponse {
                class MockHeaders : System.Net.Http.Headers.HttpHeaders {
                    [hashtable]$Headers = @{'retry-after' = '1' }
                    [bool] Contains([string]$header) { return ($this.Headers.Contains($header)) }
                    [string[]] GetValues([string]$header) { return [string[]]@($this.Headers[$header]) }
                }
                class MockException : System.Exception {
                    [int]$StatusCode = 429
                    [string]$ErrorReason = 'TooManyRequests'
                    [hashtable]$Response = @{ Headers = ([MockHeaders]::new()) }
                    MockException() : base ('Rate-Limit') {}
                }
                return ([MockException]::new())
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 1 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 2 -Exactly
            # The retry interval should around 1s
            $StopWatch.ElapsedMilliseconds | Should -BeGreaterOrEqual 1000
            $StopWatch.ElapsedMilliseconds | Should -BeLessThan 1500
        }

        It 'Retrying with exponential backoff on Rate-Limit exceeds error' {
            Mock -ModuleName $script:ModuleName Parse-WebExceptionResponse {
                class MockException : System.Exception {
                    [int]$StatusCode = 429
                    [string]$ErrorReason = 'TooManyRequests'
                    [hashtable]$Response = $null
                    MockException() : base ('Rate-Limit') {}
                }
                return ([MockException]::new())
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 3 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 4 -Exactly
            # The retry interval is given a jitter of 0.8 to 1.2 times, so the minimum is 5.6s ((1+2+4)*0.8) and the maximum is 8.4s
            $StopWatch.ElapsedMilliseconds | Should -BeGreaterOrEqual 5600
            $StopWatch.ElapsedMilliseconds | Should -BeLessThan 8400
        }

        It 'Retrying with exponential backoff on server error' {
            Mock -ModuleName $script:ModuleName Parse-WebExceptionResponse {
                class MockHeaders : System.Net.Http.Headers.HttpHeaders {
                    [hashtable]$Headers = @{'retry-after-ms' = '20' }
                    [bool] Contains([string]$header) { return ($this.Headers.Contains($header)) }
                    [string[]] GetValues([string]$header) { return [string[]]@($this.Headers[$header]) }
                }
                class MockException : System.Exception {
                    [int]$StatusCode = 500
                    [string]$ErrorReason = 'InternalServerError'
                    [hashtable]$Response = @{ Headers = ([MockHeaders]::new()) }
                    MockException() : base ('Internal Server Error') {}
                }
                return ([MockException]::new())
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 1 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 2 -Exactly
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

        It 'Tool calls (non execution)' {
            $ToolsSpec = @(@{
                    type     = 'function'
                    function = @{
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
                })

            $Message = 'Ping the Google Public DNS address three times and briefly report the results.'
            { $params = @{
                    Message     = $Message
                    Model       = 'gpt-3.5-turbo-0125'
                    Temperature = 0.1
                    Tools       = $ToolsSpec
                    InvokeTools = 'None'
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ChatCompletion @params
            } | Should -Not -Throw
            $Result.Answer | Should -BeNullOrEmpty
            $Result.Message | Should -Be $Message
            $Result.choices[0].message.tool_calls[0].function.name | Should -BeExactly 'Test-Connection'
        }

        It 'Tool calls (implicit execution)' {
            $ToolsSpec = @(@{
                    type     = 'function'
                    function = @{
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
                })

            $Message = 'Ping the Google Public DNS address three times and briefly report the results.'
            { $params = @{
                    Message     = $Message
                    Model       = 'gpt-3.5-turbo-0125'
                    Temperature = 0
                    Tools       = $ToolsSpec
                    InvokeTools = 'Auto'
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-ChatCompletion @params
            } | Should -Not -Throw
            $Result.Answer | Should -Not -BeNullOrEmpty
            $Result.Message | Should -Be $Message
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be $Message
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[1].tool_calls | Should -Not -BeNullOrEmpty
            $Result.History[2].Role | Should -Be 'tool'
            $Result.History[2].tool_call_id | Should -BeExactly ($Result.History[1].tool_calls[0].id)
            $Result.History[-1].Role | Should -Be 'assistant'
            $Result.History[-1].Content | Should -Not -BeNullOrEmpty
        }

        It 'Function call (non execution) - Legacy' {
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
            { $params = @{
                    Message                  = $Message
                    Model                    = 'gpt-3.5-turbo-0613'
                    Temperature              = 0.1
                    Functions                = $FunctionSpec
                    InvokeFunctionOnCallMode = 'None'
                    ErrorAction              = 'Stop'
                }
                $script:Result = Request-ChatCompletion @params
            } | Should -Not -Throw
            $Result.Answer | Should -BeNullOrEmpty
            $Result.Message | Should -Be $Message
            $Result.choices[0].message.function_call.name | Should -BeExactly 'Test-Connection'
        }

        It 'Function call (implicit execution) - Legacy' {
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
            { $params = @{
                    Message                  = $Message
                    Model                    = 'gpt-3.5-turbo-0613'
                    Temperature              = 0.1
                    Functions                = $FunctionSpec
                    InvokeFunctionOnCallMode = 'Auto'
                    ErrorAction              = 'Stop'
                }
                $script:Result = Request-ChatCompletion @params
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
            $params = @{
                Message             = 'Please describe about ChatGPT'
                MaxTokens           = 32
                Stream              = $true
                InformationVariable = 'Info'
                TimeoutSec          = 30
                ErrorAction         = 'Stop'
            }
            $Result = Request-ChatCompletion @params | Select-Object -First 10
            $Result | Should -HaveCount 10
            ([string[]]$Info) | Should -Be ([string[]]$Result)
        }

        It 'Retrying with exponential backoff on server error' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-WebRequest {
                iwr https://httpstat.us/500 -UseBasicParsing
            }
            $StopWatch = [System.Diagnostics.Stopwatch]::new()
            $StopWatch.Start()
            { Request-ChatCompletion -Message 'test' -MaxRetryCount 1 -MaxTokens 16 -ea Stop } | Should -Throw
            $StopWatch.Stop()
            Should -Invoke -CommandName 'Invoke-WebRequest' -ModuleName $script:ModuleName -Times 2 -Exactly
            # The retry interval is given a jitter of 0.8 to 1.2 times, so the minimum is 0.8 seconds.
            $StopWatch.ElapsedMilliseconds | Should -BeGreaterOrEqual 800
        }

        It 'Image input (url)' {
            $RemoteImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/a8/Dons_Coaches_coach_1957_Bedford_SB3_Yeates_Europa_NKY_161_at_Aldham_Old_Tyme_Rally_2014.jpg'
            { $script:Result = Request-ChatCompletion -Model 'gpt-4-vision-preview' -Message "What's in this image?" -Images ($RemoteImageUrl) -ImageDetail Low  -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -BeOfType [string]
            $Result.created | Should -BeOfType [datetime]
            $Result.Message | Should -Be "What's in this image?"
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[1].Role | Should -Be 'assistant'
        }

        It 'Image input (local file)' {
            { $script:Result = Request-ChatCompletion -Model 'gpt-4-vision-preview' -Message "What's in this image?" -Images ($script:TestData + '/sweets_donut.png')  -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -BeOfType [string]
            $Result.created | Should -BeOfType [datetime]
            $Result.Message | Should -Be "What's in this image?"
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[1].Role | Should -Be 'assistant'
        }
    }
}
