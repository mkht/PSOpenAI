#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-Embeddings' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIToken { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Chat completion' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "object": "list",
    "data": [
        {
        "object": "embedding",
        "index": 0,
        "embedding": [
            -0.002913116,
            -0.010672229,
            0.0040442813,
            -0.03419787
        ]
        }
    ],
    "model": "text-embedding-ada-002-v2",
    "usage": {
        "prompt_tokens": 10,
        "total_tokens": 10
    }
}
'@ }
            { $script:Result = Request-Embeddings -Text 'test' -ea Stop } | Should -Not -Throw
            Should -InvokeVerifiable
            $Result.data | Should -HaveCount 1
            , $Result.data[0].embedding | Should -BeOfType [float[]]
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {

        BeforeEach {
            $script:Result = ''
        }

        It 'Get vector representation of text' {
            { $script:Result = Request-Embeddings -Text 'Banana' -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.data | Should -HaveCount 1
            , $Result.data[0].embedding | Should -BeOfType [float[]]
            $Result.data[0].embedding | Should -HaveCount 1536
        }

        It 'Embeddings, multiple inputs' {
            { $script:Result = Request-Embeddings -Text ('Banana', 'Apple') -TimeoutSec 30 -ea Stop } | Should -Not -Throw
            $Result | Should -BeOfType [pscustomobject]
            $Result.data | Should -HaveCount 2
            , $Result.data[0].embedding | Should -BeOfType [float[]]
            $Result.data[0].embedding | Should -HaveCount 1536
            , $Result.data[1].embedding | Should -BeOfType [float[]]
            $Result.data[1].embedding | Should -HaveCount 1536
        }
    }
}
