#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-CosineSimilarity' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeEach {
            $script:Result = $null
        }

        It 'Calculate cosine similarity' {
            $v1 = [float[]](-0.01302161, -0.01999075, 0.007301898, -0.005528221, -0.01058555, -0.008293902, -0.01444056, -0.01415174, -0.008218559, -0.01490516, -0.003170644)
            $v2 = [float[]](0.007026904, -0.0226299, 0.007262223, -0.01307985, -0.01040635, -0.0008579359, -0.02503539, 0.001290989, 0.01506045, -0.04311577, 0.01272033)
            [single](Get-CosineSimilarity $v1 $v2) | Should -Be ([single]0.002228366)
        }

        It 'Error if each vector has different dimension' {
            $v1 = [float[]](-0.01302161, -0.01999075, 0.007301898, -0.005528221, -0.01058555, -0.008293902)
            $v2 = [float[]](0.007026904, -0.0226299, 0.007262223)
            { Get-CosineSimilarity $v1 $v2 -ErrorAction Stop } | Should -Throw
        }
    }
}
