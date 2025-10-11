#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Remove-Video' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "video_68ea",
  "object": "video.deleted",
  "deleted": true
}
'@ } -ParameterFilter { $Method -eq 'DELETE' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Remove video job' {
            { $script:Result = Remove-Video -VideoId 'video_68ea' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Method -eq 'DELETE' }
            $Result | Should -BeNullOrEmpty
        }

        It 'Parameter Sets' {
            # Named
            { Remove-Video -VideoId 'video_fb4e' -ea Stop } | Should -Not -Throw
            # Alias
            { Remove-Video -video_id 'video_fb4e' -ea Stop } | Should -Not -Throw
            # Positional
            { Remove-Video 'video_fb4e' -ea Stop } | Should -Not -Throw
            # Pipeline
            { 'video_fb4e' | Remove-Video -ea Stop } | Should -Not -Throw
            # Pipeline by property name
            { [pscustomobject]@{PSTypeName = 'PSOpenAI.Video.Job'; id = 'video_fb4e' } | Remove-Video -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 5 -Exactly -ParameterFilter { $Method -eq 'DELETE' }
        }
    }
}
