#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Register-OpenAIFile' {
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
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Upload single file' {
            { $script:Result = Register-OpenAIFile -File ($script:TestData + '/sweets_donut.png') -Purpose assistants -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result.id | Should -BeExactly 'file-abc123'
            $Result.object | Should -BeExactly 'file'
            $Result.created_at | Should -BeOfType [datetime]
        }

        It 'Pipeline input (FileInfo)' {
            $InObject = Get-Item ($script:TestData + '/sweets_donut.png')
            { $InObject | Register-OpenAIFile -Purpose assistants -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
        }

        It 'Upload from raw bytes' {
            { $script:Result = Register-OpenAIFile -Content ([byte[]](97..99)) -Name 'test.txt' -Purpose assistants -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result.id | Should -BeExactly 'file-abc123'
            $Result.object | Should -BeExactly 'file'
            $Result.created_at | Should -BeOfType [datetime]
        }

        It 'Error if the file does not exist' {
            { Register-OpenAIFile -File ($script:TestData + '/notexist.txt') -Purpose assistants -ea Stop } | Should -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 0 -Exactly
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeEach {
            $script:Result = ''
        }

        AfterEach {
            if ($script:Result.id) {
                $script:Result | Remove-OpenAIFile -ea SilentlyContinue
            }
        }

        It 'Upload test file' {
            { $script:Result = Register-OpenAIFile -File ($script:TestData + '/my-data.jsonl') -Purpose fine-tune -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'file*'
            $Result.object | Should -BeExactly 'file'
            $Result.filename | Should -Be 'my-data.jsonl'
        }

        It 'Upload test content' {
            {
                $rawcontent = [System.IO.File]::ReadAllBytes(($script:TestData + '/my-data.jsonl'))
                $script:Result = Register-OpenAIFile -Content $rawcontent -Name 'raw-data.jsonl' -Purpose batch -ea Stop
            } | Should -Not -Throw
            $Result.id | Should -BeLike 'file*'
            $Result.object | Should -BeExactly 'file'
            $Result.filename | Should -Be 'raw-data.jsonl'
        }

        It 'Upload test file (non-latin file name)' {
            { $script:Result = Register-OpenAIFile -File ($script:TestData + '/日本語テキスト.txt') -Purpose assistants -ea Stop } | Should -Not -Throw
            $Result.id | Should -BeLike 'file*'
            $Result.object | Should -BeExactly 'file'
            $Result.filename | Should -Be '日本語テキスト.txt'
        }
    }
}
