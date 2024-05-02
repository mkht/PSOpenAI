#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-OpenAIFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        Context 'Get Single File' {
            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "file-abc123",
    "object": "file",
    "bytes": 120000,
    "created_at": 1677610602,
    "filename": "mydata.csv",
    "purpose": "assistants"
}
'@ }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Get a single object with file ID' {
                { $script:Result = Get-OpenAIFile -ID 'file-abc123' -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result.id | Should -BeExactly 'file-abc123'
                $Result.object | Should -BeExactly 'file'
                $Result.created_at | Should -BeOfType [datetime]
            }

            It 'Pipeline input' {
                $InObject = [pscustomobject]@{
                    file_id = 'file-abc123'
                    object  = 'file'
                }
                { $InObject | Get-OpenAIFile -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            }
        }

        Context 'List Files' {
            BeforeAll {
                Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
                Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
                Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "data": [
        {
        "id": "file-abc123",
        "object": "file",
        "bytes": 175,
        "created_at": 1613677385,
        "filename": "salesOverview.pdf",
        "purpose": "assistants"
        },
        {
        "id": "file-def456",
        "object": "file",
        "bytes": 140,
        "created_at": 1613779121,
        "filename": "puppy.jsonl",
        "purpose": "fine-tune"
        }
    ],
    "object": "list"
}
'@
                }
            }

            BeforeEach {
                $script:Result = ''
            }

            It 'Get all files.' {
                { $script:Result = Get-OpenAIFile -ea Stop } | Should -Not -Throw
                Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
                $Result | Should -HaveCount 2
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            # Upload test files
            $script:File1 = Add-OpenAIFile -File ($script:TestData + '/sweets_donut.png') -Purpose assistants
            $script:File2 = Add-OpenAIFile -File ($script:TestData + '/my-data.jsonl') -Purpose fine-tune
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterAll {
            ($script:File1, $script:File2) | Remove-OpenAIFile -ea SilentlyContinue
        }

        It 'Get a single object with file ID' {
            { $script:Result = Get-OpenAIFile -ID $script:File1.id -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeExactly $script:File1.id
            $Result.object | Should -BeExactly 'file'
            $Result.filename | Should -Be 'sweets_donut.png'
        }

        It 'Get all files.' {
            { $script:Result = Get-OpenAIFile -ea Stop } | Should -Not -Throw
            @($Result).Count | Should -BeGreaterOrEqual 2
        }

        It 'Get specified purpose files.' {
            { $script:Result = Get-OpenAIFile -Purpose fine-tune -ea Stop } | Should -Not -Throw
            @($Result).Count | Should -BeGreaterOrEqual 1
            $Result.id | Should -Contain $script:File2.id
            $Result.filename | Should -Contain 'my-data.jsonl'
        }
    }
}
