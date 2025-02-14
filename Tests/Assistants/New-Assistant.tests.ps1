#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-Assistant' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "asst_abc123",
    "object": "assistant",
    "created_at": 1698984975,
    "name": "Math Tutor",
    "description": null,
    "model": "gpt-4-turbo",
    "instructions": "You are a personal math tutor. When asked a question, write and run Python code to answer the question.",
    "tools": [
        {
        "type": "code_interpreter"
        }
    ],
    "metadata": {},
    "top_p": 1.0,
    "temperature": 1.0,
    "response_format": "auto"
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Create assistant' {
            { $script:Result = New-Assistant -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -BeExactly 'asst_abc123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Assistant'
            $Result.created_at | Should -BeOfType [datetime]
        }

        It 'Create assistant (full param)' {
            { $params = @{
                    Name               = 'TEST'
                    Model              = 'gpt-4-turbo'
                    Description        = 'Math Tutor'
                    Instructions       = 'You are a personal math tutor. When asked a question, write and run Python code to answer the question.'
                    UseCodeInterpreter = $true
                    UseFileSearch      = $false
                    ErrorAction        = 'Stop'
                }
                $script:Result = New-Assistant @params
            } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result.id | Should -BeExactly 'asst_abc123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Assistant'
            $Result.created_at | Should -BeOfType [datetime]
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
            $script:Result | Remove-Assistant -ea SilentlyContinue
        }

        It 'Create assistant (full param)' {
            $RandomName = ('TEST' + (Get-Random -Maximum 1000))
            { $params = @{
                    Name                         = $RandomName
                    Model                        = 'gpt-4o-mini'
                    Description                  = 'Test assistant'
                    Instructions                 = 'Do it'
                    UseCodeInterpreter           = $true
                    UseFileSearch                = $true
                    MaxNumberOfFileSearchResults = 5
                    RankerForFileSearch          = 'default_2024_08_21'
                    ScoreThresholdForFileSearch  = 0.5
                    ErrorAction                  = 'Stop'
                }
                $script:Result = New-Assistant @params
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'asst_*'
            $Result.object | Should -BeExactly 'assistant'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.name | Should -Be $RandomName
            $Result.description | Should -Be 'Test assistant'
            $Result.model | Should -Be 'gpt-4o-mini'
            $Result.instructions | Should -Be 'Do it'
            $Result.tools | Should -HaveCount 2
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
            $script:Result | Remove-Assistant -ea SilentlyContinue
        }

        AfterAll {
            Clear-OpenAIContext
        }

        It 'Create assistant (full param)' {
            $RandomName = ('TEST' + (Get-Random -Maximum 1000))
            { $params = @{
                    Name               = $RandomName
                    Model              = $script:Model
                    Description        = 'Test assistant'
                    Instructions       = 'Do it'
                    UseCodeInterpreter = $true
                    UseFileSearch      = $true
                    ErrorAction        = 'Stop'
                }
                $script:Result = New-Assistant @params
            } | Should -Not -Throw
            $Result.object | Should -BeExactly 'assistant'
            $Result.name | Should -Be $RandomName
            $Result.description | Should -Be 'Test assistant'
            $Result.tools | Should -HaveCount 2
        }
    }
}
