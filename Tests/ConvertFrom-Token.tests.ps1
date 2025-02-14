#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'ConvertFrom-Token' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeEach {
            $script:Result = $null
        }

        It 'Encoding: cl100k_base (<Id>)' -Foreach @(
            @{ Id = 1; Text = ''; Token = @() }
            @{ Id = 2; Text = 'a'; Token = , 64 }
            @{ Id = 3; Text = 'Hello, World! How are you today? 🌍'; Token = (9906, 11, 4435, 0, 2650, 527, 499, 3432, 30, 11410, 234, 235) }
            @{ Id = 4; Text = 'こんにちは、世界！お元気ですか？'; Token = (90115, 5486, 3574, 244, 98220, 6447, 33334, 24186, 95221, 38641, 32149, 11571) }
            @{ Id = 5; Text = 'Здравствуйте, это мой первый раз здесь. Что мне делать?'; Token = (36551, 7094, 28086, 20812, 83680, 51627, 11, 68979, 11562, 16742, 77901, 35723, 39479, 11122, 7094, 92691, 13, 1301, 100, 25657, 11562, 79862, 95369, 18482, 30) }
            @{ Id = 6; Text = '🍏🍎🍐🍊🍋🍌🍉🍇🍓🍈🍒🍑'; Token = (9468, 235, 237, 9468, 235, 236, 9468, 235, 238, 9468, 235, 232, 9468, 235, 233, 9468, 235, 234, 9468, 235, 231, 9468, 235, 229, 9468, 235, 241, 9468, 235, 230, 9468, 235, 240, 9468, 235, 239) }
        ) {
            ConvertFrom-Token -Token $Token -Encoding 'cl100k_base' | Should -Be $Text
        }

        It 'Encoding: o200k_base (<Id>)' -Foreach @(
            @{ Id = 1; Text = ''; Token = @() }
            @{ Id = 2; Text = 'a'; Token = , 64 }
            @{ Id = 3; Text = 'Hello, World! How are you today? 🌍'; Token = (13225, 11, 5922, 0, 3253, 553, 481, 4044, 30, 130321, 235) }
            @{ Id = 4; Text = 'こんにちは、世界！お元気ですか？'; Token = (95839, 1395, 28428, 3393, 8930, 6753, 25717, 15121, 7128, 4802) }
            @{ Id = 5; Text = 'Здравствуйте, это мой первый раз здесь. Что мне делать?'; Token = (182298, 11, 8577, 65733, 62134, 4702, 44039, 13, 53319, 27934, 45321, 30) }
            @{ Id = 6; Text = '🍏🍎🍐🍊🍋🍌🍉🍇🍓🍈🍒🍑'; Token = (102415, 237, 102415, 236, 102415, 238, 102415, 232, 102415, 233, 102415, 234, 102415, 231, 102415, 229, 102415, 241, 102415, 230, 102415, 240, 102415, 239) }
        ) {
            ConvertFrom-Token -Token $Token -Encoding 'o200k_base' | Should -Be $Text
        }

        It 'Input from pipeline' {
            $script:Result = (9468, 235, 237, 9468, 235, 236, 9468, 235, 238, 9468, 235, 232, 9468, 235, 233, 9468, 235, 234, 9468, 235, 231, 9468, 235, 229, 9468, 235, 241, 9468, 235, 230, 9468, 235, 240, 9468, 235, 239) | ConvertFrom-Token
            $script:Result | Should -Be '🍏🍎🍐🍊🍋🍌🍉🍇🍓🍈🍒🍑'
        }

        It 'Input from pipeline (jagged array)' {
            $JaggedArray = @(@(9906, 856, 5575, 13), @(4438, 527, 499, 3432, 30))
            $script:Result = $JaggedArray | ConvertFrom-Token
            $script:Result | Should -HaveCount 2
            $script:Result[0] | Should -BeExactly 'Hello my student.'
            $script:Result[1] | Should -BeExactly 'How are you today?'
        }

        It 'AsArray option' {
            $script:Result = (9906, 11, 4435, 0) | ConvertFrom-Token -AsArray
            $script:Result | Should -Be @('Hello', ',', ' world', '!')
        }
    }
}
