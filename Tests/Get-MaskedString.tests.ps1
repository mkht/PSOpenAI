#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

$ModuleName = 'PSOpenAI'

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-MaskedString' {
    InModuleScope $ModuleName {
        Context 'Unit tests (offline)' -Tag 'Offline' {
            BeforeEach {
                $script:Result = $null
            }

            It 'By default, input is returned as-is' {
                $TestInput = 'Hello, World!'
                Get-MaskedString $TestInput | Should -BeExactly $TestInput
            }

            It 'Input is null or empty -> return empty' {
                $TestInput = ''
                Get-MaskedString $TestInput | Should -BeExactly $TestInput
            }

            It 'Input is whitespaces -> return whitespaces' {
                $TestInput = '       '
                Get-MaskedString $TestInput | Should -BeExactly $TestInput
            }

            It 'Input is too long -> return truncated' {
                $TestInput = 'a' * 200
                Get-MaskedString $TestInput -MaxLength 10 | Should -BeExactly 'aaaaaaaaaa ...<truncated>'
            }

            It 'Mask Test : (<Idx>)' -ForEach @(
                @{ Idx = 1; InputString = 'test : NOMATCH : test'; Expect = 'test : NOMATCH : test' }
                @{ Idx = 2; InputString = 'test : stk-abcdEFGH0123 : test'; Expect = 'test : stk-ab***23 : test' }
                @{ Idx = 3; InputString = 'test : SeCReT : test'; Expect = 'test : <MASKED> : test' }
                @{ Idx = 4; InputString = "abc`ndef`nSECRET`nend"; Expect = "abc`ndef`n<MASKED>`nend" }
                @{ Idx = 5; InputString = "abc`ndef`nSEC`nRET`nend"; Expect = "abc`ndef`nSEC`nRET`nend" }
            ) {
                $MaskPatterns = [System.Collections.Generic.List[Tuple[regex, string]]]::new()
                $MaskPatterns.Add([Tuple[regex, string]]::new('(stk-.{2})[a-z0-9\-_.~+/]+([^\s]{2})', '$1***$2'))
                $MaskPatterns.Add([Tuple[regex, string]]::new('SECRET', '<MASKED>'))
                Get-MaskedString -InputString $InputString -MaskPatterns $MaskPatterns | Should -BeExactly $Expect
            }
        }
    }
}