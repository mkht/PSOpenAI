#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-OpenAIFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
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
'@
            } -ParameterFilter { 'https://api.openai.com/v1/files/file-abc123' -eq $Uri }

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
            } -ParameterFilter { 'https://api.openai.com/v1/files' -eq $Uri }

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
        }
    ],
    "object": "list"
}
'@
            } -ParameterFilter { 'https://api.openai.com/v1/files?purpose=assistants' -eq $Uri }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Get a single object with file ID' {
            { $script:Result = Get-OpenAIFile -ID 'file-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/files/file-abc123' -eq $Uri }
            $Result.id | Should -BeExactly 'file-abc123'
            $Result.object | Should -BeExactly 'file'
            $Result.created_at | Should -BeOfType [datetime]
        }

        It 'Get all files.' {
            { $script:Result = Get-OpenAIFile -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/files' -eq $Uri }
            $Result | Should -HaveCount 2
        }

        It 'Get specified purpose files.' {
            { $script:Result = Get-OpenAIFile -Purpose 'assistants' -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/files?purpose=assistants' -eq $Uri }
            $Result | Should -HaveCount 1
            $Result.id | Should -BeExactly 'file-abc123'
            $Result.purpose | Should -BeExactly 'assistants'
        }

        Context 'Parameter Sets' {
            It 'Get_File' {
                $InObject = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                # Named
                { Get-OpenAIFile -File $InObject -ea Stop } | Should -Not -Throw
                # Positional
                { Get-OpenAIFile $InObject -ea Stop } | Should -Not -Throw
                # Pipeline
                { $InObject | Get-OpenAIFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { 'https://api.openai.com/v1/files/file-abc123' -eq $Uri }
            }

            It 'Get_Id' {
                # Named
                { Get-OpenAIFile -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-OpenAIFile 'file-abc123' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'file-abc123' | Get-OpenAIFile -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{ID = 'file-abc123' } | Get-OpenAIFile -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { 'https://api.openai.com/v1/files/file-abc123' -eq $Uri }
            }

            It 'List' {
                { Get-OpenAIFile -ea Stop } | Should -Not -Throw
                { Get-OpenAIFile -Purpose 'assistants' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/files' -eq $Uri }
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { 'https://api.openai.com/v1/files?purpose=assistants' -eq $Uri }
            }
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext

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

            # Upload test files
            $script:File1 = Add-OpenAIFile -File ($script:TestData + '/sweets_donut.png') -Purpose assistants
            $script:File2 = Add-OpenAIFile -File ($script:TestData + '/my-data.jsonl') -Purpose fine-tune
        }

        BeforeEach {
            $script:Result = ''
        }

        AfterAll {
            ($script:File1, $script:File2) | Remove-OpenAIFile -ea SilentlyContinue
            Clear-OpenAIContext
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
