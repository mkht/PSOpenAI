#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-Video' {
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
'@ } -ParameterFilter { $Uri -eq 'https://api.openai.com/v1/videos/video_fb4e' }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
  "object": "list",
  "data": [
    {
      "id": "video_fb4e",
      "object": "video",
      "created_at": 1760194265,
      "status": "completed",
      "completed_at": 1760194348,
      "error": null,
      "expires_at": 1760197948,
      "model": "sora-2",
      "progress": 100,
      "remixed_from_video_id": null,
      "seconds": "4",
      "size": "720x1280"
    },
    {
    "id": "video_f90c",
    "object": "video",
    "created_at": 1760195033,
    "status": "in_progress",
    "completed_at": null,
    "error": null,
    "expires_at": null,
    "model": "sora-2",
    "progress": 66,
    "remixed_from_video_id": "video_fb4e",
    "seconds": "4",
    "size": "720x1280"
    }
  ],
  "first_id": "video_fb4e",
  "has_more": false,
  "last_id": "video_f90c"
}
'@ } -ParameterFilter { $Uri -like 'https://api.openai.com/v1/videos?limit=*' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'List video jobs' {
            { $script:Result = Get-Video -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/videos?limit=*' }
            $Result | Should -HaveCount 2
            $Result[0].id | Should -BeLike 'video_fb4e'
            $Result[1].id | Should -BeLike 'video_f90c'
            $Result[1].psobject.TypeNames | Should -Contain 'PSOpenAI.Video.Job'
        }

        It 'Get single video job' {
            { $script:Result = Get-Video -VideoId 'video_fb4e' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter { $Uri -eq 'https://api.openai.com/v1/videos/video_fb4e' }
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -BeExactly 'video_fb4e'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Video.Job'
        }

        Context 'Parameter Sets' {
            It 'Get' {
                # Named
                { Get-Video -VideoId 'video_fb4e' -ea Stop } | Should -Not -Throw
                # Positional
                { Get-Video 'video_fb4e' -ea Stop } | Should -Not -Throw
                # Pipeline
                { 'video_fb4e' | Get-Video -ea Stop } | Should -Not -Throw
                # Pipeline by property name
                { [pscustomobject]@{PSTypeName = 'PSOpenAI.Video.Job'; id = 'video_fb4e' } | Get-Video -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 4 -Exactly -ParameterFilter { $Uri -eq 'https://api.openai.com/v1/videos/video_fb4e' }
            }

            It 'List' {
                { Get-Video -ea Stop } | Should -Not -Throw
                { Get-Video -Limit 5 -Order desc -ea Stop } | Should -Not -Throw
                { Get-Video -All -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 3 -Exactly -ParameterFilter { $Uri -like 'https://api.openai.com/v1/videos?limit=*' }
            }
        }
    }
}
