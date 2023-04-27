#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

$ModuleName = 'PSOpenAI'

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $PSScriptRoot 'TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-MaskedString' {
    InModuleScope $ModuleName {
        Context 'Unit tests (offline)' -Tag 'Offline' {
            BeforeEach {
                $script:Result = $null
            }

            It 'Source is null or empty -> return empty' {
                $TestSource = ''
                Get-MaskedString $TestSource -Target 'x' | Should -Be ''
            }

            It 'Target is null or empty -> return source' {
                $TestSource = 'test'
                $Target = ''
                Get-MaskedString $TestSource -Target $Target | Should -BeExactly $TestSource
            }

            It 'Mask target (1)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : ******************************************* : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                Get-MaskedString -Source $TestSource -Target $Target | Should -BeExactly $TestOutput
            }

            It 'Mask target (2)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : stk-yD************************************* : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 6
                Get-MaskedString -Source $TestSource -Target $Target -First $First | Should -BeExactly $TestOutput
            }

            It 'Mask target (3)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : stk-yD***********************************4X : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 6
                $Last = 2
                Get-MaskedString -Source $TestSource -Target $Target -First $First -Last $Last | Should -BeExactly $TestOutput
            }

            It 'Mask target (4)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : stk-yD*****4X : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 6
                $Last = 2
                $MaxAsterisks = 5
                Get-MaskedString -Source $TestSource -Target $Target -First $First -Last $Last -MaxNumberOfAsterisks $MaxAsterisks | Should -BeExactly $TestOutput
            }

            It 'Mask target (5)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : stk-yD****************************************4X : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 6
                $Last = 2
                $MinAsterisks = 40
                Get-MaskedString -Source $TestSource -Target $Target -First $First -Last $Last -MinNumberOfAsterisks $MinAsterisks | Should -BeExactly $TestOutput
            }

            It 'Mask target (6)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : stk-yD****4X : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 6
                $Last = 2
                $MaxAsterisks = 4
                $MinAsterisks = 40
                Get-MaskedString -Source $TestSource -Target $Target -First $First -Last $Last -MaxNumberOfAsterisks $MaxAsterisks -MinNumberOfAsterisks $MinAsterisks | Should -BeExactly $TestOutput
            }

            It 'Mask target (7)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 1000
                $Last = 2
                Get-MaskedString -Source $TestSource -Target $Target -First $First -Last $Last | Should -BeExactly $TestOutput
            }

            It 'Mask target (8)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 6
                $Last = 1000
                Get-MaskedString -Source $TestSource -Target $Target -First $First -Last $Last | Should -BeExactly $TestOutput
            }

            It 'Mask target (9)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 43
                $Last = 43
                Get-MaskedString -Source $TestSource -Target $Target -First $First -Last $Last | Should -BeExactly $TestOutput
            }

            It 'Mask target (9)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : ******************************************* : Token test'
                $Target = 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X'
                $First = 0
                $Last = 0
                Get-MaskedString -Source $TestSource -Target $Target -First $First -Last $Last | Should -BeExactly $TestOutput
            }

            It 'Mask target (10)' {
                $TestSource = 'Token test : stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X : Token test'
                $TestOutput = 'Token test : ******************************************* : Token test'
                $Target = ConvertTo-SecureString 'stk-yDYabcdefgfBqD6IPNTukJsABCDEFG8l02ksb4X' -AsPlainText -Force
                Get-MaskedString -Source $TestSource -Target $Target | Should -BeExactly $TestOutput
            }
        }
    }
}