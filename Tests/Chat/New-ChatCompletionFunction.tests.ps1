#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-ChatCompletionFunction' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeEach {
            $script:Result = $null
        }

        It 'Convert built-in command' {
            $FuncSpec = New-ChatCompletionFunction 'Test-Path'
            $FuncSpec | Should -BeOfType [System.Collections.IDictionary]
            $FuncSpec.name | Should -Be 'Test-Path'
            $FuncSpec.description | Should -Not -BeNullOrEmpty
            $FuncSpec.parameters.properties | Should -Not -BeNullOrEmpty
            $FuncSpec.parameters.properties.Path.type | Should -Be 'array'
        }

        It 'Strict mode, all param should be required' {
            $FuncSpec = New-ChatCompletionFunction 'Test-Path' -Strict
            $FuncSpec | Should -BeOfType [System.Collections.IDictionary]
            $FuncSpec.name | Should -Be 'Test-Path'
            $FuncSpec.strict | Should -Be $true
            $FuncSpec.parameters.additionalProperties | Should -Be $false
            $FuncSpec.parameters.required | Should -HaveCount ($FuncSpec.parameters.properties.Keys.Count)
        }

        It 'IncludeParameters' {
            $FuncSpec = New-ChatCompletionFunction 'Test-Path' -IncludeParameters ('Path', 'PathType')
            $FuncSpec | Should -BeOfType [System.Collections.IDictionary]
            $FuncSpec.name | Should -Be 'Test-Path'
            $FuncSpec.description | Should -Not -BeNullOrEmpty
            $FuncSpec.parameters.properties.Keys | Should -HaveCount 2
            $FuncSpec.parameters.properties.Path.type | Should -Be 'array'
            $FuncSpec.parameters.properties.PathType.type | Should -Be @('string', 'null')
        }

        It 'ExcludeParameters' {
            $FuncSpec = New-ChatCompletionFunction 'Test-Path' -ExcludeParameters ('Credential', 'OlderThan', 'NewerThan')
            $FuncSpec | Should -BeOfType [System.Collections.IDictionary]
            $FuncSpec.name | Should -Be 'Test-Path'
            $FuncSpec.description | Should -Not -BeNullOrEmpty
            $FuncSpec.parameters.properties.Path.type | Should -Be 'array'
            $FuncSpec.parameters.properties.Credential | Should -BeNullOrEmpty
            $FuncSpec.parameters.properties.OlderThan | Should -BeNullOrEmpty
            $FuncSpec.parameters.properties.NewerThan | Should -BeNullOrEmpty
        }

        It 'ParameterSetName' {
            $FuncSpec = New-ChatCompletionFunction 'Test-Path' -ParameterSetName 'LiteralPath'
            $FuncSpec | Should -BeOfType [System.Collections.IDictionary]
            $FuncSpec.name | Should -Be 'Test-Path'
            $FuncSpec.description | Should -Not -BeNullOrEmpty
            $FuncSpec.parameters.properties.Path | Should -BeNullOrEmpty
            $FuncSpec.parameters.properties.LiteralPath.type | Should -Be 'array'
        }

        It 'Resolve alias' {
            $FuncSpec = New-ChatCompletionFunction 'gc'
            $FuncSpec | Should -BeOfType [System.Collections.IDictionary]
            $FuncSpec.name | Should -Be 'Get-Content'
        }

        It 'Specifies description' {
            $FuncSpec = New-ChatCompletionFunction 'Test-Path' -Description 'TEST DESCRIPTION'
            $FuncSpec | Should -BeOfType [System.Collections.IDictionary]
            $FuncSpec.name | Should -Be 'Test-Path'
            $FuncSpec.description | Should -BeExactly 'TEST DESCRIPTION'
        }
    }
}
