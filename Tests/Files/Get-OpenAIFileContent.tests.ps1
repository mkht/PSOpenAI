#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path (Split-Path $PSScriptRoot -Parent) 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-OpenAIFileContent' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                [System.Text.Encoding]::UTF8.GetBytes('ABC')
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Save content to local file' {
            $OutFile = (Join-Path $TestDrive 'abc.txt')
            { $script:Result = Get-OpenAIFileContent -ID 'file-abc123' -OutFile $OutFile -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result | Should -BeNullOrEmpty
            $OutFile | Should -Exist
            $OutFile | Should -FileContentMatchExactly 'ABC'
        }

        It 'Output content as byte array' {
            { $script:Result = Get-OpenAIFileContent -ID 'file-abc123'-ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [byte]
            $Result[0] | Should -Be ([byte]65)
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            # Upload test files
            $script:File1 = Add-OpenAIFile -File ($script:TestData + '/my-data.jsonl') -Purpose fine-tune
        }

        AfterEach {
            $script:File1 | Remove-OpenAIFile -ea SilentlyContinue
        }

        It 'Save content to local file' {
            $OutFile = (Join-Path $TestDrive 'my-data.jsonl')
            { Get-OpenAIFileContent -ID $script:File1.id -OutFile $OutFile -ea Stop } | Should -Not -Throw
            $OutFile | Should -Exist
        }
    }
}
