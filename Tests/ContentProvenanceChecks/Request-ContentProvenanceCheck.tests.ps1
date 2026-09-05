#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-ContentProvenanceCheck' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                '{"created_at":0,"object":"content_provenance_check","results":[{"type":"c2pa","outcome":"detected","generated_at":"2026-09-01T00:00:00Z","issuer":"OpenAI","model":"image-model","validation_state":"trusted"},{"type":"synthid","outcome":"not_detected","generated_at":null,"model":null}]}'
            }
        }

        BeforeEach {
            Clear-OpenAIContext
        }

        It 'Posts an image or audio file as multipart form data: <Name>' -TestCases @(
            @{ Name = 'sweets_donut.png' }
            @{ Name = 'voice_japanese.mp3' }
        ) {
            param($Name)
            $Result = Request-ContentProvenanceCheck -File (Join-Path $script:TestData $Name) -ErrorAction Stop
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Post' -and
                $Uri -eq 'https://api.openai.com/v1/content_provenance_checks' -and
                $ContentType -eq 'multipart/form-data' -and
                $Body.Count -eq 1 -and
                $Body.file -is [System.IO.FileInfo] -and
                $Body.file.Name -eq $Name
            }
            $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.ContentProvenanceCheck'
            $Result.object | Should -BeExactly 'content_provenance_check'
            $Result.created_at | Should -Be ([DateTimeOffset]::FromUnixTimeSeconds(0).LocalDateTime)
            $Result.results | Should -HaveCount 2
            $Result.results[0].validation_state | Should -BeExactly 'trusted'
            $Result.results[0].generated_at | Should -Not -BeNullOrEmpty
            $Result.results[1].outcome | Should -BeExactly 'not_detected'
            $Result.results[1].model | Should -BeNullOrEmpty
        }

        It 'Processes each pipeline path separately' {
            $Result = @(
                (Join-Path $script:TestData 'sweets_donut.png')
                (Join-Path $script:TestData 'voice_japanese.mp3')
            ) | Request-ContentProvenanceCheck -ErrorAction Stop
            $Result | Should -HaveCount 2
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest -Times 2 -Exactly
        }

        It 'Rejects a missing file or directory before sending a request' {
            { Request-ContentProvenanceCheck -File (Join-Path $TestDrive 'missing.png') } | Should -Throw
            { Request-ContentProvenanceCheck -File $TestDrive } | Should -Throw
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest -Times 0 -Exactly
        }

        It 'Resolves relative paths with non-ASCII filenames' {
            Copy-Item (Join-Path $script:TestData 'sweets_donut.png') (Join-Path $TestDrive '画像.png')
            Push-Location $TestDrive
            try {
                Request-ContentProvenanceCheck -File './画像.png' -ErrorAction Stop | Out-Null
            }
            finally {
                Pop-Location
            }
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest -Times 1 -Exactly -ParameterFilter {
                $Body.file.Name -eq '画像.png' -and $Body.file.Exists
            }
        }

        It 'Uses context and explicit request options' {
            Set-OpenAIContext -ApiBase 'https://example.test/custom/v1' -TimeoutSec 15 -MaxRetryCount 2
            Request-ContentProvenanceCheck -File (Join-Path $script:TestData 'sweets_donut.png') -TimeoutSec 30 -Organization 'org-test' -AdditionalQuery @{ key = 'value' } -AdditionalHeaders @{ 'X-Test' = 'test' } -AdditionalBody @{ extra = 'value' } | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://example.test/custom/v1/content_provenance_checks' -and
                $TimeoutSec -eq 30 -and $MaxRetryCount -eq 2 -and
                $Organization -eq 'org-test' -and
                $AdditionalQuery.key -eq 'value' -and
                $AdditionalHeaders['X-Test'] -eq 'test' -and
                $AdditionalBody.extra -eq 'value'
            }
        }

        It 'Does not output an object when the HTTP request fails' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $null }
            Request-ContentProvenanceCheck -File (Join-Path $script:TestData 'sweets_donut.png') | Should -BeNullOrEmpty
        }

        It 'Reports malformed JSON without emitting a result' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { 'invalid json' }
            $Result = Request-ContentProvenanceCheck -File (Join-Path $script:TestData 'sweets_donut.png') -ErrorAction SilentlyContinue -ErrorVariable ParseError
            $Result | Should -BeNullOrEmpty
            $ParseError | Should -Not -BeNullOrEmpty
        }

        It 'Rejects unsupported Azure endpoint before sending a request' {
            { Request-ContentProvenanceCheck -File (Join-Path $script:TestData 'sweets_donut.png') -ApiType Azure -ApiBase 'https://example.openai.azure.com' -ErrorAction Stop } | Should -Throw
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest -Times 0 -Exactly
        }

        AfterAll {
            Clear-OpenAIContext
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext
            $script:ProvenanceTestData = Join-Path $script:TestData 'ContentProvenanceChecks'
        }

        It 'Detects C2PA and SynthID in the original OpenAI-generated image' {
            $params = @{
                File          = Join-Path $script:ProvenanceTestData 'detected.png'
                TimeoutSec    = 60
                MaxRetryCount = 2
                ErrorAction   = 'Stop'
            }
            $Result = Request-ContentProvenanceCheck @params
            $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.ContentProvenanceCheck'
            $Result.object | Should -BeExactly 'content_provenance_check'
            $Result.created_at | Should -BeOfType [datetime]
            $C2PA = @($Result.results | Where-Object type -EQ 'c2pa')
            $SynthID = @($Result.results | Where-Object type -EQ 'synthid')
            $C2PA | Should -HaveCount 1
            $SynthID | Should -HaveCount 1
            $C2PA[0].outcome | Should -BeExactly 'detected'
            $C2PA[0].validation_state | Should -BeIn @('trusted', 'valid')
            $SynthID[0].outcome | Should -BeExactly 'detected'
        }

        It 'Does not detect C2PA or SynthID in the programmatically drawn image' {
            $params = @{
                File          = Join-Path $script:ProvenanceTestData 'not-detected.png'
                TimeoutSec    = 60
                MaxRetryCount = 2
                ErrorAction   = 'Stop'
            }
            $Result = Request-ContentProvenanceCheck @params
            $Result.object | Should -BeExactly 'content_provenance_check'
            $Result.results | Should -HaveCount 2
            $C2PA = @($Result.results | Where-Object type -EQ 'c2pa')
            $SynthID = @($Result.results | Where-Object type -EQ 'synthid')
            $C2PA | Should -HaveCount 1
            $SynthID | Should -HaveCount 1
            $C2PA[0].outcome | Should -BeExactly 'not_detected'
            $C2PA[0].validation_state | Should -BeExactly 'not_present'
            $SynthID[0].outcome | Should -BeExactly 'not_detected'
        }
    }
}
