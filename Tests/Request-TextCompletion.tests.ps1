#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-TextCompletion' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Text completion' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "cmpl-uqkvlQyYK7bGYrRHQ0eXlWi7",
    "object": "text_completion",
    "created": 1589478378,
    "model": "text-davinci-003",
    "choices": [
        {
        "text": "\n\nThis is indeed a test",
        "index": 0,
        "logprobs": null,
        "finish_reason": "length"
        }
    ],
    "usage": {
        "prompt_tokens": 5,
        "completion_tokens": 7,
        "total_tokens": 12
    }
}
'@ }
            { $splat = @{
                    Prompt      = 'Say this is a test'
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-TextCompletion @splat
            } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -Be "`n`nThis is indeed a test"
            $Result.Prompt | Should -Be 'Say this is a test'
            $Result.created | Should -BeOfType [datetime]
        }

        It 'Stream output' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                '{"id":"cmpl-sf547Pa","object":"text_completion","created":1679839328,"model":"text-davinci-003","choices":[{"text":"ECHO","index":0,"finish_reason":null}]}'
            }
            $Result = Request-TextCompletion -Prompt 'test' -Stream -InformationVariable StreamOut -ea Stop
            Should -InvokeVerifiable
            $Result | Should -Be 'ECHO'
            $StreamOut | Should -Be 'ECHO'
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Text completion' {
            { $splat = @{
                    Prompt      = 'Say this is a test'
                    MaxTokens   = 16
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-TextCompletion @splat
            } | Should -Not -Throw
            $Result.Answer | Should -HaveCount 1
            $Result.Answer[0] | Should -Not -BeNullOrEmpty
            $Result.Prompt | Should -Be 'Say this is a test'
            $Result.created | Should -BeOfType [datetime]
        }

        It 'Text completion (multiple prompts)' {
            { $splat = @{
                    Prompt      = ('The menu list of a hamburger shop.', 'Top 10 Most Common American Family Names')
                    MaxTokens   = 20
                    TimeoutSec  = 30
                    ErrorAction = 'Stop'
                }
                $script:Result = Request-TextCompletion @splat
            } | Should -Not -Throw
            $Result.Answer | Should -HaveCount 2
            $Result.Answer[0] | Should -Not -BeNullOrEmpty
            $Result.Answer[1] | Should -Not -BeNullOrEmpty
            $Result.Prompt | Should -Be ('The menu list of a hamburger shop.', 'Top 10 Most Common American Family Names')
            $Result.created | Should -BeOfType [datetime]
        }

        It 'Stream output' {
            $splat = @{
                Prompt              = 'Top 10 Most Common American Family Names'
                MaxTokens           = 32
                Stream              = $true
                InformationVariable = 'Info'
                TimeoutSec          = 30
                ErrorAction         = 'Stop'
            }
            $Result = Request-TextCompletion @splat | Select-Object -First 10
            $Result | Should -HaveCount 10
            ([string[]]$Info) | Should -Be ([string[]]$Result)
        }
    }
}
