#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ResponseCompaction' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Simple response compaction' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abcd1234",
  "object": "response.compaction",
  "created_at": 1765028440,
  "output": [
    {
      "id": "msg_defg5678",
      "type": "message",
      "status": "completed",
      "content": [
        {
          "type": "input_text",
          "text": "Hello."
        }
      ],
      "role": "user"
    },
    {
      "id": "cmp_hijk9012",
      "type": "compaction",
      "encrypted_content": "encrypted-data"
    }
  ],
  "usage": {
    "input_tokens": 165,
    "input_tokens_details": {
      "cached_tokens": 0
    },
    "output_tokens": 1366,
    "output_tokens_details": {
      "reasoning_tokens": 896
    },
    "total_tokens": 1531
  }
}
'@ }
            { $script:Result = Request-ResponseCompaction -Message 'Hello.' -SystemMessage 'You are an assistant.' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Response.Compaction'
            $Result.id | Should -Be 'resp_abcd1234'
            $Result.output[0].id | Should -Be 'msg_defg5678'
            $Result.output[1].id | Should -Be 'cmp_hijk9012'
            $Result.output[1].encrypted_content | Should -BeExactly 'encrypted-data'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.History | Should -HaveCount 2
            $Result.History[0] | Should -BeOfType [pscustomobject]
            $Result.History[0].Role | Should -Be 'user'
            $Result.History[0].Content.text | Should -BeExactly 'Hello.'
            $Result.History[1] | Should -BeOfType [pscustomobject]
            $Result.History[1].Id | Should -Be 'cmp_hijk9012'
            $Result.History[1].encrypted_content | Should -BeExactly 'encrypted-data'
        }

        It 'Output as raw response' {
            $Response_json = @'
{
  "id": "resp_abcd1234",
  "object": "response.compaction",
  "created_at": 1765028440,
  "output": [
    {
      "id": "msg_defg5678",
      "type": "message",
      "status": "completed",
      "content": [
        {
          "type": "input_text",
          "text": "Hello."
        }
      ],
      "role": "user"
    },
    {
      "id": "cmp_hijk9012",
      "type": "compaction",
      "encrypted_content": "encrypted-data"
    }
  ],
  "usage": {}
}
'@
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $Response_json }
            { $script:Result = Request-ResponseCompaction -Message 'Hello.' -OutputRawResponse -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result | Should -BeOfType [string]
            $Result | Should -BeExactly $Response_json
        }

        It 'Pipeline input' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abcd1234",
  "object": "response.compaction",
  "created_at": 1765028440,
  "output": [
    {
      "id": "cmp_hijk9012",
      "type": "compaction",
      "encrypted_content": "encrypted-data"
    }
  ],
  "usage": {}
}
'@ }

            $HistoryObject = [pscustomobject]@{
                History = @(
                    [pscustomobject]@{
                        role    = 'user'
                        content = @(
                            [pscustomobject]@{
                                type = 'input_text'
                                text = 'Hello.'
                            }
                        )
                    },
                    [pscustomobject]@{
                        role    = 'assistant'
                        content = @(
                            [pscustomobject]@{
                                type = 'output_text'
                                text = 'Hi there!'
                            }
                        )
                    }
                )
            }

            { $script:Result = $HistoryObject | Request-ResponseCompaction `
                    -Model gpt-5.1 -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
        }

        It 'Image input' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abcd1234",
  "object": "response.compaction",
  "created_at": 1765028440,
  "output": [
    {
      "id": "cmp_hijk9012",
      "type": "compaction",
      "encrypted_content": "encrypted-data"
    }
  ],
  "usage": {}
}
'@ }

            { $script:Result = Request-ResponseCompaction `
                    -Message 'What is this?' `
                    -Images ($script:TestData + '/sweets_donut.png') `
                    -Model gpt-5.1 -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
        }

        It 'File input' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abcd1234",
  "object": "response.compaction",
  "created_at": 1765028440,
  "output": [
    {
      "id": "cmp_hijk9012",
      "type": "compaction",
      "encrypted_content": "encrypted-data"
    }
  ],
  "usage": {}
}
'@ }

            { $script:Result = Request-ResponseCompaction `
                    -Message 'Summarize this text in Japanese' `
                    -Files ($script:TestData + '/日本語テキスト.txt') `
                    -Model gpt-5.1 -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
        }

        It 'Input Message is required' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {}
            { Request-ResponseCompaction -Model 'gpt-5.1' -ea Stop } | Should -Throw 'No message is specified. You must specify one or more messages.'
            Should -Not -InvokeVerifiable
        }


        It 'Full parameters' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "resp_abcd1234",
  "object": "response.compaction",
  "created_at": 1765028440,
  "output": [
    {
      "id": "cmp_hijk9012",
      "type": "compaction",
      "encrypted_content": "encrypted-data"
    }
  ],
  "usage": {}
}
'@ }

            {
                $param = @{
                    Role               = 'User'
                    Message            = 'Hello.'
                    Instructions       = 'You are a senior developer.'
                    Files              = ($script:TestData + '/日本語テキスト.txt')
                    Images             = ($script:TestData + '/sweets_donut.png')
                    Model              = 'o4-mini'
                    PreviousResponseId = 'id_previous1234'
                    TimeoutSec         = 30
                    MaxRetryCount      = 3
                }
                $script:Result = Request-ResponseCompaction @param -ea Stop
            } | Should -Not -Throw
            Should -InvokeVerifiable
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

        It 'Compaction of simple response' {
            { $script:Result = Request-ResponseCompaction -Message 'Hello' -Model gpt-5-nano -TimeoutSec 60 -ea Stop } | Should -Not -Throw
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Response.Compaction'
            $Result | Should -BeOfType [pscustomobject]
            $Result.created_at | Should -BeOfType [datetime]
            $Result.output | Should -HaveCount 2
            $Result.History[0] | Should -BeOfType [pscustomobject]
            $Result.History[0].Type | Should -Be 'message'
            $Result.History[1] | Should -BeOfType [pscustomobject]
            $Result.History[1].Type | Should -Be 'compaction'
        }

        It 'Pipeline input' {
            $HistoryObject = [pscustomobject]@{
                History = @(
                    [pscustomobject]@{
                        role    = 'user'
                        content = @(
                            [pscustomobject]@{
                                type = 'input_text'
                                text = 'Hello.'
                            }
                        )
                    },
                    [pscustomobject]@{
                        role    = 'assistant'
                        content = @(
                            [pscustomobject]@{
                                type = 'output_text'
                                text = 'Hi there!'
                            }
                        )
                    }
                )
            }

            { $script:Result = $HistoryObject | Request-ResponseCompaction `
                    -Model gpt-5-nano -TimeoutSec 60 -ea Stop } | Should -Not -Throw
            $Result.PSTypeNames | Should -Contain 'PSOpenAI.Response.Compaction'
            $Result | Should -BeOfType [pscustomobject]
            $Result.created_at | Should -BeOfType [datetime]
            $Result.output | Should -HaveCount 2
            $Result.History[0] | Should -BeOfType [pscustomobject]
            $Result.History[0].Type | Should -Be 'message'
            $Result.History[1] | Should -BeOfType [pscustomobject]
            $Result.History[1].Type | Should -Be 'compaction'
        }
    }
}