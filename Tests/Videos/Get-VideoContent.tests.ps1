#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Get-VideoContent' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                [System.Text.Encoding]::UTF8.GetBytes('ABC')
            }
            Mock -Verifiable -ModuleName $script:ModuleName Wait-Video {
                $CurrentDate = Get-Date
                [PSCustomObject]@{
                    PSTypeName   = 'PSOpenAI.Video.Job'
                    object       = 'video'
                    id           = 'video_abc123'
                    status       = 'completed'
                    created_at   = $CurrentDate.AddMinutes(-5)
                    completed_at = $CurrentDate
                    expires_at   = $CurrentDate.AddHours(1)
                    model        = 'sora-2'
                    progress     = 100
                }
            }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Save video to local file' {
            $OutFile = (Join-Path $TestDrive 'abc.mp4')
            { $script:Result = Get-VideoContent -VideoId 'video_abc123' -OutFile $OutFile -Variant video -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeNullOrEmpty
            $OutFile | Should -Exist
            $OutFile | Should -FileContentMatchExactly 'ABC'
        }

        It 'Output video as byte array' {
            { $script:Result = Get-VideoContent -VideoId 'video_abc123'-ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -HaveCount 3
            $Result[0] | Should -BeOfType [byte]
            $Result[0] | Should -Be ([byte]65)
        }

        It 'Wait for completion' {
            $OutFile = (Join-Path $TestDrive 'abc123.mp4')
            { $script:Result = Get-VideoContent -VideoId 'video_abc123' -OutFile $OutFile -WaitForCompletion -ea Stop } | Should -Not -Throw
            Should -Invoke Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            Should -Invoke Wait-Video -ModuleName $script:ModuleName -Times 1
            $Result | Should -BeNullOrEmpty
            $OutFile | Should -Exist
            $OutFile | Should -FileContentMatchExactly 'ABC'
        }
    }
}
