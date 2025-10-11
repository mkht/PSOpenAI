#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-Video' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "id": "video_fb4e",
  "object": "video",
  "created_at": 1760194265,
  "status": "queued",
  "completed_at": null,
  "error": null,
  "expires_at": null,
  "model": "sora-2",
  "progress": 0,
  "remixed_from_video_id": null,
  "seconds": "4",
  "size": "720x1280"
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Create a video job' {
            { $script:Result = New-Video -Prompt 'Dancing Doggo' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Video.Job'
            $Result.id | Should -BeExactly 'video_fb4e'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'queued'
        }

        It 'Create a video job(full param)' {
            {
                $Params = @{
                    Prompt         = 'Dancing Donuts'
                    Model          = 'sora-2-pro'
                    InputReference = (Join-Path $script:TestData 'sweets_donut.png')
                    Seconds        = 12
                }
                $script:Result = New-Video @Params -ea Stop
            } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }
    }
}
