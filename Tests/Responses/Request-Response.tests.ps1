#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-Response' {

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

        It 'Simple chat response' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abcd1234",
  "object": "response",
  "created_at": 1743924446,
  "status": "completed",
  "error": null,
  "incomplete_details": null,
  "instructions": null,
  "max_output_tokens": null,
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_abcd1234",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "I can help with a variety of things!",
          "annotations": []
        }
      ]
    }
  ],
  "parallel_tool_calls": true,
  "previous_response_id": null,
  "reasoning": {
    "effort": null,
    "generate_summary": null
  },
  "store": true,
  "temperature": 1.0,
  "text": {
    "format": {
      "type": "text"
    }
  },
  "tool_choice": "auto",
  "tools": [],
  "top_p": 1.0,
  "truncation": "disabled",
  "usage": {
    "input_tokens": 32,
    "input_tokens_details": {
      "cached_tokens": 0
    },
    "output_tokens": 65,
    "output_tokens_details": {
      "reasoning_tokens": 0
    },
    "total_tokens": 97
  },
  "user": null,
  "metadata": {}
}
'@ }
            { $script:Result = Request-Response -Message 'What can you do for me?' -SystemMessage 'You are an assistant.' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.id | Should -Be 'resp_abcd1234'
            $Result.output_text | Should -BeOfType [string]
            $Result.output_text | Should -BeExactly 'I can help with a variety of things!'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.LastUserMessage | Should -BeExactly 'What can you do for me?'
            $Result.History[0] | Should -BeOfType [pscustomobject]
            $Result.History[0].Role | Should -Be 'system'
            $Result.History[0].Content.text | Should -BeExactly 'You are an assistant.'
            $Result.History[1] | Should -BeOfType [pscustomobject]
            $Result.History[1].Role | Should -Be 'user'
            $Result.History[1].Content.text | Should -BeExactly 'What can you do for me?'
            $Result.History[2] | Should -BeOfType [pscustomobject]
            $Result.History[2].Role | Should -Be 'assistant'
            $Result.History[2].Content.text | Should -BeExactly 'I can help with a variety of things!'
        }

        It 'Structured Outputs' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abc1234",
  "object": "response",
  "created_at": 1743926825,
  "status": "completed",
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_abc1234",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "{\"Steps\":[{\"Explanation\":\"To isolate the term with x, subtract 9 from both sides.\",\"Output\":\"3x + 9 - 9 = 18 - 9\"},{\"Explanation\":\"This simplifies to 3x = 9.\",\"Output\":null},{\"Explanation\":\"Next, divide both sides by 3 to solve for x.\",\"Output\":\"x = 9 / 3\"},{\"Explanation\":\"This simplifies to x = 3.\",\"Output\":null}],\"FinalAnswer\":\"x = 3\"}",
          "annotations": []
        }
      ]
    }
  ],
  "previous_response_id": null,
  "text": {
    "format": {
      "type": "json_schema",
      "description": null,
      "name": "MathReasoning",
      "schema": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "Steps": {
            "type": [
              "array",
              "null"
            ],
            "items": {
              "$ref": "#/definitions/Step"
            }
          },
          "FinalAnswer": {
            "type": [
              "null",
              "string"
            ]
          }
        },
        "definitions": {
          "Step": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "Explanation": {
                "type": [
                  "null",
                  "string"
                ]
              },
              "Output": {
                "type": [
                  "null",
                  "string"
                ]
              }
            },
            "required": [
              "Explanation",
              "Output"
            ]
          }
        },
        "required": [
          "FinalAnswer",
          "Steps"
        ]
      },
      "strict": true
    }
  },
  "truncation": "disabled",
  "metadata": {}
}
'@ }
            { $script:Result = Request-Response 'How solve 3x+9=18 ?' -OutputType ([MathReasoning]) -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.StructuredOutputs | Should -HaveCount 1
            $Result.StructuredOutputs[0].GetType().Name | Should -Be 'MathReasoning'
            $Result.StructuredOutputs[0].FinalAnswer | Should -Be 'x = 3'
            $Result.output[0].content[0].parsed.GetType().Name | Should -Be 'MathReasoning'
            $Result.output[0].content[0].text | Should -BeOfType ([string])
        }

        It 'The model stops to output in half way' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abc1234",
  "object": "response",
  "created_at": 1743927499,
  "status": "incomplete",
  "error": null,
  "incomplete_details": {
    "reason": "max_output_tokens"
  },
  "instructions": null,
  "max_output_tokens": 16,
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_abc1234",
      "status": "incomplete",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "In the hush",
          "annotations": []
        }
      ]
    }
  ],
  "previous_response_id": null,
  "metadata": {}
}
'@ }
            { $script:Result = Request-Response -Message 'Please write a long poem.' -MaxOutputTokens 16 -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.status | Should -Be 'incomplete'
            $Result.output_text | Should -BeExactly 'In the hush'
        }

        It 'The model refuses to respond' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_67f23ff5",
  "object": "response",
  "created_at": 1743929333,
  "status": "completed",
  "error": null,
  "incomplete_details": null,
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_67f23ff5",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "refusal",
          "refusal": "I'm sorry, I can't assist with that."
        }
      ]
    }
  ],
  "previous_response_id": null,
  "text": {
    "format": {
      "type": "text"
    }
  },
  "metadata": {}
}
'@ }
            { $script:Result = Request-Response -Message 'test' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.output_text | Should -BeNullOrEmpty
            $Result.output[0].content[0].refusal | Should -BeExactly "I'm sorry, I can't assist with that."
        }

        It 'Stream output' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                '{"type":"response.output_text.delta","item_id":"msg_e83","output_index":0,"content_index":0,"delta":"Hello"}',
                '{"type":"response.output_text.delta","item_id":"msg_e83","output_index":0,"content_index":0,"delta":"ECHO"}'
            }
            $Result = Request-Response -Message 'test' -Stream -ea Stop
            Should -InvokeVerifiable
            $Result | Should -HaveCount 2
            $Result[0] | Should -BeExactly 'Hello'
            $Result[1] | Should -BeExactly 'ECHO'
        }

        It 'Background Stream' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                @'
{
    "type": "response.created",
    "sequence_number": 0,
    "response": {
        "id": "resp_abc123",
        "object": "response",
        "created_at": 1748915156,
        "status": "queued",
        "background": true,
        "error": null,
        "model": "gpt-4o-2024-08-06",
        "output": [],
        "previous_response_id": null,
        "store": true,
        "text": {"format": {"type": "text"}}
    }
}
'@
            }
            { $script:Result = Request-Response -Message 'test' -Stream -Background -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequestSSE -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -Be 'resp_abc123'
            $Result.output | Should -HaveCount 0
            $Result.LastUserMessage | Should -BeExactly 'test'
        }

        It 'Stream output as object' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequestSSE {
                '{"type":"response.created","response":{"id":"resp_e83","object":"response","created_at":1743930702,"status":"in_progress","model":"gpt-4o-mini-2024-07-18","output":[]}}',
                '{"type":"response.output_text.delta","item_id":"msg_e83","output_index":0,"content_index":0,"delta":"Hello"}',
                '{"type":"response.output_text.delta","item_id":"msg_e83","output_index":0,"content_index":0,"delta":"ECHO"}',
                '{"type":"response.completed","response":{"id":"resp_e83","object":"response","created_at":1743930702,"status":"completed","model":"gpt-4o-mini-2024-07-18","output":[]}}'
            }
            $Result = Request-Response -Message 'test' -Stream -StreamOutputType 'object' -ea Stop
            Should -InvokeVerifiable
            $Result | Should -HaveCount 4
            $Result[0] | Should -BeOfType [pscustomobject]
            $Result[0].type | Should -Be 'response.created'
            $Result[1] | Should -BeOfType [pscustomobject]
            $Result[1].type | Should -Be 'response.output_text.delta'
            $Result[2] | Should -BeOfType [pscustomobject]
            $Result[2].type | Should -Be 'response.output_text.delta'
            $Result[3] | Should -BeOfType [pscustomobject]
            $Result[3].type | Should -Be 'response.completed'
        }

        It 'Output as raw response' {
            $Response_json = @'
{
  "id": "resp_abcd1234",
  "object": "response",
  "created_at": 1743924446,
  "status": "completed",
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_abcd1234",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "I can help with a variety of things!",
          "annotations": []
        }
      ]
    }
  ],
  "metadata": {}
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $Response_json }
            { $script:Result = Request-Response -Message 'Hello' -OutputRawResponse -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -BeExactly $Response_json
        }

        It 'Image input' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_d014",
  "object": "response",
  "created_at": 1743931953,
  "status": "completed",
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_d014",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "This is an illustration of two donuts.",
          "annotations": []
        }
      ]
    }
  ],
  "text": {
    "format": {
      "type": "text"
    }
  },
  "metadata": {}
}
'@ }

            { $script:Result = Request-Response `
                    -Message 'What is this?' `
                    -Images ($script:TestData + '/sweets_donut.png') `
                    -Model gpt-4o-mini -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.LastUserMessage | Should -BeExactly 'What is this?'
            $Result.output_text | Should -BeExactly 'This is an illustration of two donuts.'
            $Result.History[0].content[1].image_url | Should -Match 'data:image/png;base64,'
        }

        It 'File input' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_26266",
  "object": "response",
  "created_at": 1743937620,
  "status": "completed",
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_26266",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "\u3053\u306e\u6587\u7ae0\u3067\u306f\u3001\u8a9e\u3002",
          "annotations": []
        }
      ]
    }
  ],
  "text": {
    "format": {
      "type": "text"
    }
  },
  "metadata": {}
}
'@ }

            { $script:Result = Request-Response `
                    -Message 'Summarize this text in Japanese' `
                    -Files ($script:TestData + '/日本語テキスト.txt') `
                    -Model gpt-4o-mini -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.LastUserMessage | Should -BeExactly 'Summarize this text in Japanese'
            $Result.output_text | Should -Not -BeNullOrEmpty
        }

        It 'Web Search' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_3cfb",
  "object": "response",
  "created_at": 1743938395,
  "status": "completed",
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "web_search_call",
      "id": "ws_3cfb",
      "status": "completed"
    },
    {
      "type": "message",
      "id": "msg_3cfb",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "Here are the top three recent tech news stories",
          "annotations": [
            {
              "type": "url_citation",
              "start_index": 262,
              "end_index": 426,
              "url": "https://technews.example.com/tech/news1?utm_source=openai",
              "title": "ICYMI: the week's 7 biggest tech stories from the Nintendo Switch 2 launch to Microsoft turning 50"
            },
            {
              "type": "url_citation",
              "start_index": 963,
              "end_index": 1095,
              "url": "https://technews.example.com/technology/news2/?utm_source=openai",
              "title": "Yahoo strikes deal to sell TechCrunch to investment firm"
            }
          ]
        }
      ]
    }
  ],
  "parallel_tool_calls": true,
  "previous_response_id": null,
  "text": {
    "format": {
      "type": "text"
    }
  },
  "tool_choice": "auto",
  "tools": [
    {
      "type": "web_search_preview",
      "search_context_size": "low",
      "user_location": {
        "type": "approximate",
        "city": "London",
        "country": "GB",
        "region": "London",
        "timezone": "Europe/London"
      }
    }
  ],
  "metadata": {}
}
'@ }

            { $script:Result = Request-Response `
                    -Message 'List recent top 3 tech news.' `
                    -UseWebSearch `
                    -WebSearchContextSize low `
                    -WebSearchUserLocationCountry 'GB' `
                    -WebSearchUserLocationCity 'London' `
                    -WebSearchUserLocationRegion 'London' `
                    -WebSearchUserLocationTimeZone 'Europe/London' `
                    -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.output[1].content[0].annotations | Should -HaveCount 2
            $Result.output_text | Should -Not -BeNullOrEmpty
        }

        It 'Conversation State' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_7e5a5",
  "object": "response",
  "created_at": 1743938395,
  "status": "completed",
  "model": "gpt-4o-mini-2024-07-18",
  "output": [
    {
      "type": "message",
      "id": "msg_7e5a5",
      "status": "completed",
      "role": "assistant",
      "content": [
        {
          "type": "output_text",
          "text": "The currency used in Thailand is the Thai Baht, abbreviated as THB.",
          "annotations": []
        }
      ]
    }
  ],
  "previous_response_id": null,
  "text": {
    "format": {
      "type": "text"
    }
  },
  "metadata": {}
}
'@ }

            {
                $InObject = [pscustomobject]@{
                    History = @(
                        @{
                            'role'    = 'user'
                            'content' = 'Hi.'
                        },
                        @{
                            'role'    = 'assistant'
                            'content' = 'Hello! How can I help you?'
                        }
                    )
                }
                $script:Result = $InObject | Request-Response -Message 'What currency used in Thailand?' -ea Stop
            } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.output_text | Should -BeExactly 'The currency used in Thailand is the Thai Baht, abbreviated as THB.'
            $Result.History | Should -HaveCount 4
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[2].Role | Should -Be 'user'
            $Result.History[3].Role | Should -Be 'assistant'
        }

        It 'Batch' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {}
            { $script:Result = Request-Response -Message 'Hello!' -AsBatch -ea Stop } | Should -Not -Throw
            Should -Not -InvokeVerifiable
            $Result.method | Should -Be 'POST'
            $Result.url | Should -Be '/v1/responses'
            $Result.body.model | Should -Be 'gpt-4o-mini'
            $Result.body.input[0].content[0].text | Should -Be 'Hello!'
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeAll {
            Clear-OpenAIContext
        }

        BeforeEach {
            $script:Result = ''

            # To avoid api rate limit
            Start-Sleep -Seconds 3
        }

        It 'Simple chat response' {
            { $script:Result = Request-Response -Message 'Hello' -Model gpt-4o-mini -Store $false -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'response'
            $Result.output | Should -HaveCount 1
            $Result.created_at | Should -BeOfType [datetime]
            $Result.LastUserMessage | Should -Be 'Hello'
            $Result.output_text | Should -Not -BeNullOrEmpty
            $Result.History[0] | Should -BeOfType [pscustomobject]
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[1] | Should -BeOfType [pscustomobject]
            $Result.History[1].Role | Should -Be 'assistant'
        }

        It 'Simple chat response (Full params)' {
            {
                $param = @{
                    Message          = 'What a defference between C# and C++? Please explain briefly.'
                    DeveloperMessage = 'You are a senior developer.'
                    Model            = 'o3-mini'
                    Truncation       = 'auto'
                    MaxOutputTokens  = 1024
                    User             = 'Kevin'
                    OutputType       = 'text'
                    MetaData         = @{'key1' = 'value1' }
                    ReasoningEffort  = 'low'
                    ReasoningSummary = 'detailed'
                    Store            = $false
                    TimeoutSec       = 30
                    MaxRetryCount    = 3
                }
                $script:Result = Request-Response @param -ea Stop
            } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'response'
            $Result.output | Should -HaveCount 2
            $Result.output_text | Should -Not -BeNullOrEmpty
        }

        It 'Structured Outputs' {
            $SystemMsg = 'You are a helpful math tutor. Guide the user through the solution step by step.'
            $Prompt = 'how can I solve 8x + 7 = -23'
            {
                $param = @{
                    Message          = $Prompt
                    DeveloperMessage = $SystemMsg
                    Model            = 'gpt-4o-mini'
                    OutputType       = ([MathReasoning])
                    Store            = $false
                    TimeoutSec       = 30
                    MaxRetryCount    = 1
                }
                $script:Result = Request-Response @param -ea Stop
            } | Should -Not -Throw
            $Result.StructuredOutputs | Should -HaveCount 1
            $Result.StructuredOutputs[0].GetType().Name | Should -Be 'MathReasoning'
            $Result.output[0].content[0].parsed.GetType().Name | Should -Be 'MathReasoning'
            $Result.output[0].content[0].text | Should -BeOfType ([string])
        }

        It 'Pipeline input (Conversations)' {
            { $script:First = Request-Response -Message 'What' -MaxOutputTokens 20 -Store $false -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            { $script:Result = $script:First | Request-Response -Message 'When' -MaxOutputTokens 20 -Store $false -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result.LastUserMessage | Should -Be 'When'
            $Result.output_text | Should -Not -BeNullOrEmpty
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content[0].text | Should -Be 'What'
            $Result.History[1].Role | Should -Be 'assistant'
            $Result.History[2].Role | Should -Be 'user'
            $Result.History[2].Content[0].text | Should -Be 'When'
            $Result.History[3].Role | Should -Be 'assistant'
        }

        It 'Pipeline input (Previous conversation Id)' {
            { $script:First = Request-Response -Message 'Hello' -MaxOutputTokens 20 -Store $true -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            { $script:Result = Request-Response -Message "Do you know Ninomae Ina'nis?" -MaxOutputTokens 64 -PreviousResponseId $script:First.id -Store $false -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result.LastUserMessage | Should -Be "Do you know Ninomae Ina'nis?"
            $Result.output_text | Should -Not -BeNullOrEmpty
        }

        It 'Function calling' {
            $FunctionResult = @'
Ping Source Address Latency(ms) BufferSize(B) Status
---- ------ ------- ----------- ------------- ------
   1 TEST-1 8.8.8.8          10            32 Success
   2 TEST-1 8.8.8.8           9            32 Success
   3 TEST-1 8.8.8.8          10            32 Success
'@

            $FunctionDefinition = @{
                type        = 'function'
                name        = 'Test-Connection'
                description = 'The Test-Connection command sends pings to remote computers and returns replies.'
                parameters  = @{
                    type                 = 'object'
                    properties           = @{
                        'ComputerName' = @{type = 'string'; description = 'Specifies the target host name or ip address, e.g, "8.8.8.8" ' }
                        'Count'        = @{type = 'integer'; description = 'Specifies the number of echo requests to send. The default value is 4.' }
                    }
                    required             = @('ComputerName')
                    additionalProperties = $false
                }
            }

            $Message = 'Ping the Google Public DNS address three times and briefly report the results.'
            { $param = @{
                    Message     = $Message
                    Model       = 'gpt-4o-mini'
                    Temperature = 0
                    Functions   = $FunctionDefinition
                    ToolChoice  = 'auto'
                    Store       = $false
                    TimeoutSec  = 30
                }
                $script:Result1 = Request-Response @param -ea Stop
            } | Should -Not -Throw
            $Result1.output[0].name | Should -Be 'Test-Connection'
            $Result1.History[0].Role | Should -Be 'user'
            $Result1.History[1].type | Should -Be 'function_call'

            $ToolCall = $Result1.output[0]
            $Result1.History += [pscustomobject]@{
                type    = 'function_call_output'
                call_id = $ToolCall.call_id
                output  = $FunctionResult
            }

            { $param = @{
                    Model       = 'gpt-4o-mini'
                    Temperature = 0
                    Functions   = $FunctionDefinition
                    ToolChoice  = 'auto'
                    Store       = $false
                    TimeoutSec  = 30
                }
                $script:Result2 = $script:Result1 | Request-Response @param -ea Stop
            } | Should -Not -Throw
            $Result2.LastUserMessage | Should -BeExactly $Message
            $Result2.output_text | Should -Not -BeNullOrEmpty
            $Result2.History | Should -HaveCount 4
            $Result2.History[0].Role | Should -Be 'user'
            $Result2.History[1].type | Should -Be 'function_call'
            $Result2.History[2].type | Should -Be 'function_call_output'
            $Result2.History[3].Role | Should -Be 'assistant'
        }

        It 'Stream output' {
            $params = @{
                Message         = 'Please describe about ChatGPT'
                Model           = 'gpt-4o-mini'
                MaxOutputTokens = 32
                Store           = $false
                Stream          = $true
                TimeoutSec      = 30
                ErrorAction     = 'Stop'
            }
            $Result = Request-Response @params | Select-Object -First 10
            $Result | Should -HaveCount 10
        }

        It 'Image input (url)' {
            $RemoteImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/a8/Dons_Coaches_coach_1957_Bedford_SB3_Yeates_Europa_NKY_161_at_Aldham_Old_Tyme_Rally_2014.jpg'
            { $script:Result = Request-Response -Model 'gpt-4o-mini' -Message "What's in this image?" -Images ($RemoteImageUrl) -ImageDetail Low  -TimeoutSec 30 -Store $false -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.LastUserMessage | Should -Be "What's in this image?"
            $Result.output_text | Should -Not -BeNullOrEmpty
        }

        It 'Image input (local file)' {
            { $script:Result = Request-Response -Model 'gpt-4o-mini' -Message "What's in this image?" -Images ($script:TestData + '/sweets_donut.png') -ImageDetail Low -TimeoutSec 30 -Store $false -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.LastUserMessage | Should -Be "What's in this image?"
            $Result.output_text | Should -Not -BeNullOrEmpty
        }

        It 'File input (local file)' {
            { $script:Result = Request-Response -Model 'gpt-4o-mini' -Message 'Summarize this text in Japanese' -Files ($script:TestData + '/日本語テキスト.txt') -TimeoutSec 30 -Store $false -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.LastUserMessage | Should -Be 'Summarize this text in Japanese'
            $Result.output_text | Should -Not -BeNullOrEmpty
        }

        It 'Tools - File search (vector store)' {
            { $script:Result = Request-Response -Model 'gpt-4o-mini' `
                    -Message 'Please breifly describe the flow of setup an Azure Stack HCI demo environment.' `
                    -UseFileSearch `
                    -FileSearchVectorStoreIds 'vs_67f3ca64998c81919ab49ba98a827810' `
                    -FileSearchMaxNumberOfResults 10 `
                    -FileSearchRanker 'auto' `
                    -FileSearchScoreThreshold 0.2 `
                    -TimeoutSec 30 -Store $false -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.LastUserMessage | Should -Not -BeNullOrEmpty
            $Result.output_text | Should -Not -BeNullOrEmpty
            $Result.output[0].type | Should -Be 'file_search_call'
            $Result.output[1].type | Should -Be 'message'
            $Result.output[1].content[0].annotations.Count | Should -BeGreaterOrEqual 1
        }

        It 'Tools - Web Search' {
            { $script:Result = Request-Response -Model 'gpt-4o-mini' `
                    -Message 'List recent top 3 tech news.' `
                    -UseWebSearch `
                    -WebSearchContextSize 'low' `
                    -TimeoutSec 30 -Store $false -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.LastUserMessage | Should -Not -BeNullOrEmpty
            $Result.output_text | Should -Not -BeNullOrEmpty
            $Result.output[0].type | Should -Be 'web_search_call'
            $Result.output[1].type | Should -Be 'message'
            $Result.output[1].content[0].annotations.Count | Should -BeGreaterOrEqual 1
        }

        It 'Tools - Computer Use' {
            {
                $param = @{
                    Message                  = 'Check the latest OpenAI news on Google.'
                    Model                    = 'computer-use-preview'
                    UseComputerUse           = $true
                    ComputerUseEnvironment   = 'browser'
                    ComputerUseDisplayHeight = 1024
                    ComputerUseDisplayWidth  = 768
                    Images                   = ($script:TestData + '/google.png')
                    ReasoningSummary         = 'concise'
                    Store                    = $false
                    TimeoutSec               = 30
                }

                $script:Result = Request-Response @param -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.LastUserMessage | Should -Be 'Check the latest OpenAI news on Google.'
            $Result.output.type | Should -Contain 'computer_call'
        }

        It 'Tools - Remote MCP' {
            {
                $param = @{
                    Message                  = 'How does microsoft/markitdown convert pptx to markdown?'
                    Model                    = 'gpt-4.1-mini'
                    UseRemoteMCP             = $true
                    RemoteMCPServerLabel     = 'DeepWiki'
                    RemoteMCPServerUrl       = 'https://mcp.deepwiki.com/mcp'
                    RemoteMCPRequireApproval = 'always'
                    RemoteMCPHeaders         = @{ 'X-Debug-Key' = '1234567890' }  # Only for test, no meaning
                    Store                    = $false
                    TimeoutSec               = 30
                }

                $script:Result = Request-Response @param -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.LastUserMessage | Should -Be 'How does microsoft/markitdown convert pptx to markdown?'
            $Result.output[-1].type | Should -Be 'mcp_approval_request'
        }

        It 'Tools - Code Interpreter' {
            {
                $param = @{
                    Message            = "How Many R's in 'Strawberry'? Solve it use with Python tools."
                    Model              = 'gpt-4.1-mini'
                    UseCodeInterpreter = $true
                    ToolChoice         = 'required'
                    Store              = $false
                    TimeoutSec         = 30
                }

                $script:Result = Request-Response @param -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.output.type | Should -Contain 'code_interpreter_call'
        }

        It 'Tools - Image Generation' {
            {
                $param = @{
                    Message                          = 'Create an illustration of a young man wearing a brown bucket hat, holding a cola in his left hand and chicken in his right hand.'
                    Model                            = 'gpt-4.1-mini'
                    UseImageGeneration               = $true
                    ImageGenerationOutputFormat      = 'jpeg'
                    ImageGenerationQuality           = 'low'
                    ImageGenerationSize              = '1024x1024'
                    ImageGenerationOutputCompression = 80
                    Store                            = $false
                    TimeoutSec                       = 150
                }

                $script:Result = Request-Response @param -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.output.type | Should -Contain 'image_generation_call'
        }

        It 'Tools - Local Shell' {
            {
                $param = @{
                    Message       = 'List all files that the size is larger than 100MB in /var/logs'
                    Model         = 'codex-mini-latest'
                    UseLocalShell = $true
                    Store         = $false
                    TimeoutSec    = 30
                }

                $script:Result = Request-Response @param -ea Stop } | Should -Not -Throw
            $Result.object | Should -Be 'response'
            $Result.output.type | Should -Contain 'local_shell_call'
        }
    }

    Context 'Integration tests (Azure OpenAI)' -Tag 'Azure' {

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

        It 'Simple chat response' {
            { $script:Result = Request-Response -Message 'Hello' -Model gpt-4o-mini -Store $false -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.object | Should -Be 'response'
            $Result.output | Should -HaveCount 1
            $Result.created_at | Should -BeOfType [datetime]
            $Result.LastUserMessage | Should -Be 'Hello'
            $Result.output_text | Should -Not -BeNullOrEmpty
            $Result.History[0] | Should -BeOfType [pscustomobject]
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[1] | Should -BeOfType [pscustomobject]
            $Result.History[1].Role | Should -Be 'assistant'
        }

        It 'Stream output' {
            $params = @{
                Message         = 'Please describe about Azure OpenAI'
                Model           = 'gpt-4o-mini'
                MaxOutputTokens = 32
                Store           = $false
                Stream          = $true
                TimeoutSec      = 30
                ErrorAction     = 'Stop'
            }
            $Result = Request-Response @params | Select-Object -First 10
            $Result | Should -HaveCount 10
        }
    }
}