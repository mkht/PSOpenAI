#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ChatCompletion' {

    BeforeAll {
        # Test class definitions for Structured Outputs
        class Step {
            [string]$Explanation
            [string]$Output
        }

        class MathReasoning {
            [Step[]]$Steps
            [string]$FinalAnswer
        }
    }

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

        It 'Structured Outputs (Auto parse)' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "chatcmpl-123",
    "object": "chat.completion",
    "created": 1723356481,
    "model": "gpt-4o-2024-08-06",
     "choices": [
        {
        "index": 0,
        "message": {
            "role": "assistant",
            "content": "{\"Steps\":[{\"Explanation\":\"To find the value of x, we need to isolate it on one side of the equation. We'll start by removing the constant term (7) from the left side.\",\"Output\":\"8x + 7 - 7 = -23 - 7\"},{\"Explanation\":\"Subtracting 7 from both sides gives us this simplified equation:\",\"Output\":\"8x = -30\"},{\"Explanation\":\"Now, to solve for x, we need to divide both sides of the equation by 8, which is the coefficient of x.\",\"Output\":\"8x/8 = -30/8\"},{\"Explanation\":\"Simplifying the division gives us the answer. The fraction -30/8 can be simplified by dividing the numerator and the denominator by their greatest common divisor, which is 2.\",\"Output\":\"x = -15/4\"},{\"Explanation\":\"So the solution to the equation is x = -15/4.\",\"Output\":null}],\"FinalAnswer\":\"x = -15/4\"}",
            "refusal": null
        },
        "logprobs": null,
        "finish_reason": "stop"
        }
    ],
    "usage": {
        "prompt_tokens": 46,
        "completion_tokens": 200,
        "total_tokens": 246
    },
    "system_fingerprint": "fp_1633542941"
    }
'@ }
            { $script:Result = Request-ChatCompletion -Message 'test' -ea Stop -Format ([MathReasoning]) } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0].GetType().Name | Should -Be 'MathReasoning'
            $Result.Answer[0].FinalAnswer | Should -BeExactly 'x = -15/4'
            $Result.choices[0].message.parsed.GetType().Name | Should -Be 'MathReasoning'
            $Result.choices[0].message.content | Should -BeOfType ([string])
        }

        It 'Structured Outputs (manual)' {
            $ownSchema = @'
{
  "name": "reasoning_schema",
  "strict": true,
  "schema": {
    "type": "object",
    "properties": {
      "reasoning_steps": {
        "type": "array",
        "items": { "type": "string" }
      },
      "answer": { "type": "string" }
    },
    "required": ["reasoning_steps", "answer"],
    "additionalProperties": false
  }
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "chatcmpl-123",
    "object": "chat.completion",
    "created": 1723356481,
    "model": "gpt-4o-2024-08-06",
     "choices": [
        {
        "index": 0,
        "message": {
            "role": "assistant",
            "content": "{\"reasoning_steps\":[\"Identify the two numbers being compared: 9.11 and 9.9.\",\"Recognize that both numbers take the form of decimals.\",\"Determine which decimal has a larger value by comparing the numbers directly.\",\"9.11 has one digit in the hundredths place (1) while 9.9 has no digits in the hundredths place, effectively being 9.90.\",\"Since 9.11 (9.110) is greater than 9.90, conclude that 9.11 is bigger.\"],\"answer\":\"9.11 is bigger than 9.9.\"}",
            "refusal": null
        },
        "logprobs": null,
        "finish_reason": "stop"
        }
    ],
    "usage": {
        "prompt_tokens": 46,
        "completion_tokens": 200,
        "total_tokens": 246
    },
    "system_fingerprint": "fp_1633542941"
    }
'@ }
            { $script:Result = Request-ChatCompletion -Message 'test' -ea Stop -Format 'json_schema' -JsonSchema $ownSchema } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0].GetType().Name | Should -Be 'String'
            { $script:JsonObject = ($Result.Answer[0] | ConvertFrom-Json -ea Stop) } | Should -Not -Throw
            $JsonObject.answer | Should -BeExactly '9.11 is bigger than 9.9.'
        }

        It 'The model stops to output in half way' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "chatcmpl-123",
    "object": "chat.completion",
    "created": 1677652288,
    "choices": [{
        "index": 0,
        "message": {
        "role": "assistant",
        "content": "Hello there, how may"
        },
        "finish_reason": "length"
    }],
    "usage": {
        "prompt_tokens": 9,
        "completion_tokens": 7,
        "total_tokens": 16
    }
}
'@ }
            { $script:Result = Request-ChatCompletion -Message 'test' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -BeExactly 'Hello there, how may'
        }

        It 'The model refuses to respond' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "chatcmpl-123",
    "object": "chat.completion",
    "created": 1723356481,
    "model": "gpt-4o-2024-08-06",
     "choices": [
        {
        "index": 0,
        "message": {
            "role": "assistant",
            "refusal": "I'm sorry, I cannot assist with that request."
        },
        "logprobs": null,
        "finish_reason": "stop"
        }
    ],
    "usage": {
        "prompt_tokens": 46,
        "completion_tokens": 200,
        "total_tokens": 246
    },
    "system_fingerprint": "fp_1633542941"
    }
'@ }
            { $script:Result = Request-ChatCompletion -Message 'test' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -BeExactly "I'm sorry, I cannot assist with that request."
            $Result.choices[0].message.content | Should -BeNullOrEmpty
            $Result.choices[0].message.refusal | Should -BeExactly "I'm sorry, I cannot assist with that request."
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

        It 'Structured Outputs' {
            $SystemMsg = 'You are a helpful math tutor. Guide the user through the solution step by step.'
            $Prompt = 'how can I solve 8x + 7 = -23'
            { $script:Result = Request-ChatCompletion -Message $Prompt -SystemMessage $SystemMsg -Model 'gpt-4o-mini' -Format ([MathReasoning]) -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'chat.completion'
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0].GetType().Name | Should -Be 'MathReasoning'
            $Result.choices[0].message.parsed.GetType().Name | Should -Be 'MathReasoning'
            $Result.choices[0].message.content | Should -BeOfType ([string])
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
                    Model       = 'gpt-4o-mini'
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
                    Model       = 'gpt-4o-mini'
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

        It 'Parallel Tool calls (implicit execution)' {
            Mock -ModuleName $script:ModuleName Invoke-ChatCompletionFunction {
                @{Weather = 'Sunny'; Temperature = 25 }
            }

            $ToolsSpec = @(@{
                    type     = 'function'
                    function = @{
                        name        = 'get_current_weather'
                        description = 'Get the current weather in a given location'
                        parameters  = @{
                            type       = 'object'
                            properties = @{
                                'location' = @{type = 'string'; description = 'The city and state, e.g. San Francisco, CA' }
                            }
                            required   = @('location')
                        }
                    }
                })

            $Message = "What's the weather like in San Francisco, Tokyo, and Paris?"
            { $params = @{
                    Message           = $Message
                    Model             = 'gpt-4o'
                    Temperature       = 0
                    Tools             = $ToolsSpec
                    ToolChoice        = 'auto'
                    ParallelToolCalls = $true
                    InvokeTools       = 'Auto'
                    ErrorAction       = 'Stop'
                }
                $script:Result = Request-ChatCompletion @params
            } | Should -Not -Throw
            Should -Invoke Invoke-ChatCompletionFunction -ModuleName $script:ModuleName -Times 3 -Exactly
            $Result.Answer | Should -Not -BeNullOrEmpty
            $Result.Message | Should -Be $Message
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content | Should -Be $Message
            $Result.History[-1].Role | Should -Be 'assistant'
            $Result.History[-1].Content | Should -Not -BeNullOrEmpty
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
            { $script:Result = Request-ChatCompletion -Model 'gpt-4o' -Message "What's in this image?" -Images ($RemoteImageUrl) -ImageDetail Low  -TimeoutSec 30 -ea Stop } | Should -Not -Throw
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
            { $script:Result = Request-ChatCompletion -Model 'gpt-4o' -Message "What's in this image?" -Images ($script:TestData + '/sweets_donut.png')  -TimeoutSec 30 -ea Stop } | Should -Not -Throw
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
