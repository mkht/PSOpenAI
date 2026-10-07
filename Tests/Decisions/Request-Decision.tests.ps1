#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="6.0.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Request-Decision' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            $script:Predicate = @{ type = 'predicate'; name = 'damaged'; instructions = 'Is the item damaged?' }
            # Synthetic response based on the official Decisions schema, not a live
            # API recording. Scores and probabilities are only parser test values.
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } {
                '{"model":"gpt-6-luna","answers":[{"type":"predicate","name":"damaged","probability":0.95},{"type":"choice","name":"accepted","choice":false,"confidence":0.8,"probabilities":[{"value":false,"probability":0.8},{"value":"false","probability":0.2}]},{"type":"score","name":"severity","score":1.1,"confidence":0.7,"probabilities":[{"label":"Low","value":0,"probability":0.1},{"label":"Medium","value":1,"probability":0.7},{"label":"High","value":2,"probability":0.2}]},{"type":"refusal","name":null}],"usage":{"input_tokens":42,"input_tokens_details":{"cached_tokens":0,"cache_write_tokens":0},"output_tokens":0,"output_tokens_details":{"reasoning_tokens":0},"total_tokens":42,"compute_units":null}}'
            }
        }

        BeforeEach {
            Clear-OpenAIContext
        }

        It 'Sends one question as an array with the default model and endpoint' {
            Request-Decision -Input 'A cracked display.' -Question $script:Predicate -ErrorAction Stop | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { if ($Stream) { return $false };
                $Method -eq 'Post' -and $Uri -eq 'https://api.openai.com/v1/decisions' -and
                $ContentType -eq 'application/json' -and $Body.model -eq 'gpt-6-luna' -and
                $Body.input -is [string] -and $Body.input -eq 'A cracked display.' -and
                $Body.questions -is [array] -and $Body.questions.Count -eq 1 -and
                $Body.questions[0].name -eq 'damaged' -and -not $Body.Contains('safety_identifier')
            }
        }

        It 'Preserves question order, typed choice values, and ordered score levels through JSON' {
            $Questions = @(
                $script:Predicate
                [pscustomobject]@{
                    type         = 'choice'
                    instructions = 'Should the return be accepted?'
                    choices      = @(@{ value = $false }, @{ value = 'false' })
                }
                @{
                    type         = 'score'
                    instructions = 'Rate the severity.'
                    levels       = @(@{ label = 'Low' }, @{ label = 'Medium' }, @{ label = 'High' })
                }
            )
            Request-Decision -Message 'A cracked display.' -Questions $Questions | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { if ($Stream) { return $false };
                $WireBody = $Body | ConvertTo-Json -Depth 100 | ConvertFrom-Json
                $WireBody.questions.Count -eq 3 -and
                $WireBody.questions[0].type -eq 'predicate' -and
                $WireBody.questions[1].choices[0].value -is [bool] -and
                $WireBody.questions[1].choices[0].value -eq $false -and
                $WireBody.questions[1].choices[1].value -is [string] -and
                $WireBody.questions[2].levels[0].label -eq 'Low' -and
                $WireBody.questions[2].levels[2].label -eq 'High'
            }
        }

        It 'Preserves all answer shapes including false choices, fractional scores, refusal, and usage' {
            $Result = Request-Decision -Text 'A cracked display.' -Questions $script:Predicate
            $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.Decision'
            $Result.answers | Should -HaveCount 4
            $Result.answers[0].probability | Should -Be 0.95
            $Result.answers[1].choice | Should -BeOfType [bool]
            $Result.answers[1].choice | Should -BeFalse
            $Result.answers[1].probabilities[1].value | Should -BeOfType [string]
            $Result.answers[2].score | Should -Be 1.1
            $Result.answers[2].probabilities[0].value | Should -Be 0
            $Result.answers[3].type | Should -BeExactly 'refusal'
            $Result.answers[3].name | Should -BeNullOrEmpty
            $Result.usage.total_tokens | Should -Be 42
            $Result.usage.output_tokens | Should -Be 0
            $Result.usage.input_tokens_details.cache_write_tokens | Should -Be 0
            $Result.usage.compute_units | Should -BeNullOrEmpty
        }

        It 'Parses a recorded live response without losing its fields: <Fixture>' -TestCases @(
            @{ Fixture = 'text' }
            @{ Fixture = 'image' }
        ) {
            param($Fixture)
            $Request = Get-Content -LiteralPath (Join-Path $script:TestData "Decisions/$Fixture-request.json") -Raw | ConvertFrom-Json
            $script:RecordedDecisionResponse = Get-Content -LiteralPath (Join-Path $script:TestData "Decisions/$Fixture-response.json") -Raw
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } { $script:RecordedDecisionResponse }
            $Params = @{ Questions = $Request.questions; Model = $Request.model; ErrorAction = 'Stop' }
            if ($Fixture -eq 'text') {
                $Params.Message = $Request.input
                $Params.SafetyIdentifier = $Request.safety_identifier
            }
            else {
                $Params.Message = $Request.message
                $Params.Images = Join-Path $script:TestData $Request.image_file
                $Params.ImageDetail = $Request.image_detail
            }
            $Expected = $script:RecordedDecisionResponse | ConvertFrom-Json
            $Result = Request-Decision @Params
            $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.Decision'
            ($Result | ConvertTo-Json -Depth 100 -Compress) | Should -BeExactly ($Expected | ConvertTo-Json -Depth 100 -Compress)
            $Result.answers | Should -HaveCount $Request.questions.Count
            ($Result.answers.name -join ',') | Should -BeExactly ($Request.questions.name -join ',')
        }

        It 'Processes each pipeline text as a separate request' {
            $Results = 'First report', 'Second report' | Request-Decision -Questions $script:Predicate
            $Results | Should -HaveCount 2
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { -not $Stream -and $Body.input -eq 'First report' }
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { -not $Stream -and $Body.input -eq 'Second report' }
        }

        It 'Preserves native message/part order and per-image detail without changing the caller input' {
            $Messages = @(
                @{ role = 'user'; content = 'First evidence' }
                [pscustomobject]@{
                    type    = 'message'
                    role    = 'user'
                    content = @(
                        @{ type = 'input_image'; image_url = 'data:image/png;base64,AA=='; detail = 'original' }
                        @{ type = 'input_text'; text = 'Second evidence' }
                    )
                }
            )
            $Original = $Messages | ConvertTo-Json -Depth 100
            Request-Decision -InputMessages $Messages -Questions $script:Predicate | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { if ($Stream) { return $false };
                $Body.input -is [array] -and $Body.input.Count -eq 2 -and
                $Body.input[0].content -eq 'First evidence' -and
                $Body.input[1].content[0].detail -eq 'original' -and
                $Body.input[1].content[1].text -eq 'Second evidence'
            }
            ($Messages | ConvertTo-Json -Depth 100) | Should -BeExactly $Original
        }

        It 'Wraps a single native message in an input array' {
            Request-Decision -InputMessages @{ role = 'user'; content = 'Evidence' } -Questions $script:Predicate | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                -not $Stream -and $Body.input -is [array] -and $Body.input.Count -eq 1
            }
        }

        It 'Converts local images to inline data URLs and retains inline image input' {
            $ImagePath = Join-Path $script:TestData 'sweets_donut.png'
            Request-Decision -Message 'Inspect these images.' -Images $ImagePath, 'data:image/png;base64,AA==' -ImageDetail original -Questions $script:Predicate | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { if ($Stream) { return $false };
                $Body.input -is [array] -and $Body.input.Count -eq 1 -and
                $Body.input[0].role -eq 'user' -and $Body.input[0].content.Count -eq 3 -and
                $Body.input[0].content[0].text -eq 'Inspect these images.' -and
                $Body.input[0].content[1].image_url -match '^data:image/png;base64,' -and
                $Body.input[0].content[1].detail -eq 'original' -and
                $Body.input[0].content[2].image_url -eq 'data:image/png;base64,AA=='
            }
        }

        It 'Supports image-only requests without inserting an empty text part' {
            Request-Decision -Images 'data:image/png;base64,AA==' -Questions $script:Predicate | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                -not $Stream -and $Body.input[0].content.Count -eq 1 -and
                $Body.input[0].content[0].type -eq 'input_image' -and $Body.input[0].content[0].detail -eq 'auto'
            }
        }

        It 'Rejects missing input, missing images, directories, and external image URLs before HTTP' {
            { Request-Decision -Questions $script:Predicate -ErrorAction Stop } | Should -Throw
            { Request-Decision -Images (Join-Path $TestDrive 'missing.png') -Questions $script:Predicate } | Should -Throw
            { Request-Decision -Images $TestDrive -Questions $script:Predicate } | Should -Throw
            { Request-Decision -Images 'https://example.test/image.png' -Questions $script:Predicate } | Should -Throw
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 0 -Exactly -ParameterFilter { -not $Stream }
        }

        It 'Accepts 128 images and rejects 129 images' {
            Request-Decision -Images (@('data:image/png;base64,AA==') * 128) -Questions $script:Predicate | Out-Null
            { Request-Decision -Images (@('data:image/png;base64,AA==') * 129) -Questions $script:Predicate } | Should -Throw
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                -not $Stream -and $Body.input[0].content.Count -eq 128
            }
        }

        It 'Preserves explicitly empty safety identifiers and enforces the length boundary' {
            Request-Decision -Message 'Evidence' -Questions $script:Predicate -SafetyIdentifier '' | Out-Null
            Request-Decision -Message 'Evidence' -Questions $script:Predicate -SafetyIdentifier ('x' * 128) | Out-Null
            { Request-Decision -Message 'Evidence' -Questions $script:Predicate -SafetyIdentifier ('x' * 129) } | Should -Throw
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                -not $Stream -and $Body.Contains('safety_identifier') -and $Body.safety_identifier -eq ''
            }
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                -not $Stream -and $Body.safety_identifier.Length -eq 128
            }
        }

        It 'Uses context, explicit connection options, custom models, and additional request fields' {
            Set-OpenAIContext -ApiBase 'https://example.test/custom/v1/' -TimeoutSec 15 -MaxRetryCount 2
            Request-Decision -Message 'Evidence' -Questions $script:Predicate -Model 'custom-deployment' -TimeoutSec 30 -Organization 'org-test' -AdditionalQuery @{ key = 'value' } -AdditionalHeaders @{ 'X-Test' = 'test' } -AdditionalBody @{ extra = $false } | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { if ($Stream) { return $false };
                $Uri -eq 'https://example.test/custom/v1/decisions' -and
                $Body.model -eq 'custom-deployment' -and $TimeoutSec -eq 30 -and $MaxRetryCount -eq 2 -and
                $Organization -eq 'org-test' -and $AdditionalQuery.key -eq 'value' -and
                $AdditionalHeaders['X-Test'] -eq 'test' -and $AdditionalBody.extra -eq $false
            }
        }

        It 'Does not emit a result when the HTTP request fails' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } { $null }
            Request-Decision -Message 'Evidence' -Questions $script:Predicate | Should -BeNullOrEmpty
        }

        It 'Reports malformed JSON without emitting a result' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { -not $Stream } { 'invalid json' }
            $Result = Request-Decision -Message 'Evidence' -Questions $script:Predicate -ErrorAction SilentlyContinue -ErrorVariable ParseError
            $Result | Should -BeNullOrEmpty
            $ParseError | Should -Not -BeNullOrEmpty
        }

        AfterAll {
            Clear-OpenAIContext
        }
    }

    Context 'Integration tests (online)' -Tag 'Online' {
        BeforeAll {
            Clear-OpenAIContext
            $script:DecisionTestData = Join-Path $script:TestData 'Decisions'
        }

        It 'Evaluates text with predicate, boolean/string choice, and score questions' {
            $Request = Get-Content -LiteralPath (Join-Path $script:DecisionTestData 'text-request.json') -Raw | ConvertFrom-Json
            $Result = Request-Decision -Message $Request.input -Questions $Request.questions -Model $Request.model -SafetyIdentifier $Request.safety_identifier -TimeoutSec 90 -MaxRetryCount 0 -ErrorAction Stop
            Write-Host ('Decisions text response: ' + ($Result | ConvertTo-Json -Depth 100 -Compress))

            $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.Decision'
            $Result.model | Should -BeLike 'gpt-6-luna*'
            $Result.answers | Should -HaveCount 4
            ($Result.answers.name -join ',') | Should -BeExactly 'damaged,usable,resolution,severity'
            ($Result.answers.type -join ',') | Should -BeExactly 'predicate,choice,choice,score'
            $Result.answers[0].probability | Should -BeGreaterThan 0.5
            $Result.answers[0].probability | Should -BeLessOrEqual 1
            $Result.answers[1].choice | Should -BeOfType [bool]
            $Result.answers[1].choice | Should -BeFalse
            $Result.answers[2].choice | Should -BeExactly 'refund'
            $Result.answers[3].score | Should -BeGreaterOrEqual 1.5
            $Result.answers[3].score | Should -BeLessOrEqual 2
            $Result.answers[3].probabilities | Should -HaveCount 3
            $Result.usage.input_tokens | Should -BeGreaterThan 0
            $Result.usage.total_tokens | Should -BeGreaterOrEqual $Result.usage.input_tokens
        }

        It 'Evaluates an existing local image with original detail' {
            $Request = Get-Content -LiteralPath (Join-Path $script:DecisionTestData 'image-request.json') -Raw | ConvertFrom-Json
            $ImagePath = Join-Path $script:TestData $Request.image_file
            $Result = Request-Decision -Message $Request.message -Images $ImagePath -ImageDetail $Request.image_detail -Questions $Request.questions -Model $Request.model -TimeoutSec 90 -MaxRetryCount 0 -ErrorAction Stop
            Write-Host ('Decisions image response: ' + ($Result | ConvertTo-Json -Depth 100 -Compress))

            $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.Decision'
            $Result.model | Should -BeLike 'gpt-6-luna*'
            $Result.answers | Should -HaveCount 3
            ($Result.answers.name -join ',') | Should -BeExactly 'orange_shape,image_kind,colored_shape_count'
            ($Result.answers.type -join ',') | Should -BeExactly 'predicate,choice,score'
            $Result.answers[0].probability | Should -BeGreaterThan 0.5
            $Result.answers[0].probability | Should -BeLessOrEqual 1
            $Result.answers[1].choice | Should -BeExactly 'geometric_drawing'
            # The model can disagree with the visual shape count. Verify the API
            # contract and weighted-score arithmetic, rather than an exact count.
            $Result.answers[2].score | Should -BeGreaterOrEqual 0
            $Result.answers[2].score | Should -BeLessOrEqual 2
            $Result.answers[2].probabilities | Should -HaveCount 3
            $WeightedScore = ($Result.answers[2].probabilities | ForEach-Object { $_.value * $_.probability } | Measure-Object -Sum).Sum
            [Math]::Abs($Result.answers[2].score - $WeightedScore) | Should -BeLessThan 0.000001
            $ProbabilitySum = ($Result.answers[2].probabilities | Measure-Object -Property probability -Sum).Sum
            [Math]::Abs($ProbabilitySum - 1) | Should -BeLessThan 0.000001
            $Result.usage.input_tokens | Should -BeGreaterThan 0
            $Result.usage.total_tokens | Should -BeGreaterOrEqual $Result.usage.input_tokens
        }

        AfterAll {
            Clear-OpenAIContext
        }
    }
}
