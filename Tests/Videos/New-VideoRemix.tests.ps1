#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-VideoRemix' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "video_f90c",
  "object": "video",
  "created_at": 1760195033,
  "status": "queued",
  "completed_at": null,
  "error": null,
  "expires_at": null,
  "model": "sora-2",
  "progress": 0,
  "remixed_from_video_id": "video_fb4e",
  "seconds": "4",
  "size": "720x1280"
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Create a video remix job' {
            { $script:Result = New-VideoRemix -Prompt 'Dancing Doggo' -VideoId 'video_f90c' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Video.Job'
            $Result.id | Should -BeExactly 'video_f90c'
            $Result.remixed_from_video_id | Should -BeExactly 'video_fb4e'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'queued'
        }
    }
}
