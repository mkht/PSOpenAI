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
            $script:PredicateParameters = @{ PredicateQuestionName = 'damaged'; PredicateQuestionInstructions = 'Is the item damaged?' }
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest { '{"model":"gpt-6-luna","answers":[]}' }
            $script:DecisionTestData = Join-Path $script:TestData 'Decisions'
        }

        BeforeEach {
            Clear-OpenAIContext
        }

        It 'Sends one question as an array with the default model and endpoint' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
                # Representative response for checking conversion without network access.
                @'
{
  "model": "gpt-6-luna",
  "answers": [
    {"type": "predicate", "name": "damaged", "probability": 0.95}
  ],
  "usage": {
    "input_tokens": 42,
    "input_tokens_details": {"cached_tokens": 0, "cache_write_tokens": 0},
    "output_tokens": 0,
    "output_tokens_details": {"reasoning_tokens": 0},
    "total_tokens": 42
  }
}
'@
            } -ParameterFilter { -not $Stream }
            $Response = Request-Decision -Message 'A cracked display.' @script:PredicateParameters -ErrorAction Stop
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { if ($Stream) { return $false }
                $Method -eq 'Post' -and $Uri -eq 'https://api.openai.com/v1/decisions' -and
                $ContentType -eq 'application/json' -and $Body.model -eq 'gpt-6-luna' -and
                $Body.input -is [string] -and $Body.input -eq 'A cracked display.' -and
                $Body.questions -is [array] -and $Body.questions.Count -eq 1 -and
                $Body.questions[0].name -eq 'damaged' -and -not $Body.Contains('safety_identifier')
            }
            $Response.PSObject.TypeNames | Should -Contain 'PSOpenAI.Decision'
            $Response.model | Should -BeExactly 'gpt-6-luna'
            $Response.answers | Should -HaveCount 1
            $Response.answers[0].type | Should -BeExactly 'predicate'
            $Response.answers[0].name | Should -BeExactly 'damaged'
            $Response.answers[0].probability | Should -Be 0.95
        }

        It 'Sends multiple questions at once' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
                # Representative response for checking conversion without network access.
                '{"model":"gpt-6-luna","answers":[{"type":"predicate","name":"damaged","probability":1.0},{"type":"predicate","name":"usable","probability":0.0},{"type":"choice","name":"condition","choice":"broken","probabilities":[{"value":"new","probability":0.0},{"value":"used","probability":0.0},{"value":"broken","probability":1.0}],"confidence":1.0},{"type":"choice","name":"value","choice":"low","probabilities":[{"value":"low","probability":1.0},{"value":"high","probability":0.0},{"value":"medium","probability":0.0}],"confidence":1.0},{"type":"score","name":"severity","score":0.0,"probabilities":[{"value":0,"label":"critical","probability":1.0},{"value":1,"label":"working","probability":0.0},{"value":2,"label":"cosmetic","probability":0.0}],"confidence":1.0}],"usage":{"input_tokens":870,"input_tokens_details":{"cached_tokens":0,"cache_write_tokens":0},"output_tokens":0,"output_tokens_details":{"reasoning_tokens":0},"total_tokens":870}}'
            } -ParameterFilter { -not $Stream }

            $param = @{
                Model                         = 'gpt-6-luna'
                Message                       = 'Inspect the item in the photo.'
                Images                        = Join-Path $script:DecisionTestData 'car_broken.jpg'
                ImageDetail                   = 'auto'
                PredicateQuestionName         = @('damaged', 'usable')
                PredicateQuestionInstructions = @('Is the item damaged?', 'Is the item usable?')
                ChoiceQuestionName            = @('condition', 'value')
                ChoiceQuestionInstructions    = @("Which description best matches the item's condition?", "Which description best matches the item's value?")
                ChoiceQuestionChoices         = @(
                    @{ 'new' = ''; 'used' = 'It seems to have been used but is still functional.'; 'broken' = 'It is not functional and cannot be used.' }
                    @{ 'low' = 'It is worth very little or nothing.'; 'medium' = 'It has some value but is not worth much.'; 'high' = 'It is worth a significant amount of money.' }
                )
                ScoreQuestionName             = 'severity'
                ScoreQuestionInstructions     = 'How severe is the damage?'
                ScoreQuestionLevels           = [ordered]@{
                    'critical' = 'The damage renders the item unusable or unsafe.'
                    'working'  = 'The damage affects functionality but the item can still be used.'
                    'cosmetic' = 'The damage is cosmetic or superficial and does not affect functionality.'
                }
            }

            $Response = Request-Decision @param -ErrorAction Stop
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Body.questions.Count -eq 5 -and
                ($Body.questions.type -join ',') -eq 'predicate,predicate,choice,choice,score' -and
                $Body.questions[2].choices.Count -eq 3 -and
                $Body.questions[3].choices.Count -eq 3 -and
                $Body.questions[4].levels.Count -eq 3 -and
                ($Body.questions[4].levels.label -join ',') -eq 'critical,working,cosmetic' -and
                @($Body.questions[2].choices | Where-Object { $_.value -eq 'broken' -and $_.description -eq 'It is not functional and cannot be used.' }).Count -eq 1 -and
                @($Body.questions[4].levels | Where-Object { $_.label -eq 'critical' -and $_.description -eq 'The damage renders the item unusable or unsafe.' }).Count -eq 1
            }
            $Response.PSObject.TypeNames | Should -Contain 'PSOpenAI.Decision'
            $Response.answers | Should -HaveCount 5
            ($Response.answers.type -join ',') | Should -BeExactly 'predicate,predicate,choice,choice,score'
            ($Response.answers.name -join ',') | Should -BeExactly 'damaged,usable,condition,value,severity'
        }

        It 'Converts dictionary, enumerable, and property-based choice inputs to typed API choices' {
            $Dictionary = [ordered]@{ $true = 'Accepted'; $false = '' }
            $Values = @('repair', $false)
            $ChoiceRecords = @(
                [ordered]@{ value = 'manual'; description = 'Handle manually.' }
                [pscustomobject]@{ value = $false; description = '' }
            )
            $Params = @{
                Message                    = 'Evidence'
                ChoiceQuestionInstructions = @('Dictionary choices?', 'Enumerable choices?', 'Object choices?')
                ChoiceQuestionChoices      = @($Dictionary, $Values, $ChoiceRecords)
            }

            Request-Decision @Params -ErrorAction Stop | Out-Null

            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Wire = $Body | ConvertTo-Json -Depth 20 | ConvertFrom-Json
                $Wire.questions.Count -eq 3 -and
                ($Wire.questions.type -join ',') -eq 'choice,choice,choice' -and
                $Wire.questions[0].choices.Count -eq 2 -and
                $Wire.questions[0].choices[0].value -is [bool] -and
                $Wire.questions[0].choices[0].value -eq $true -and
                $Wire.questions[0].choices[0].description -eq 'Accepted' -and
                $Wire.questions[0].choices[1].value -is [bool] -and
                $Wire.questions[0].choices[1].value -eq $false -and
                -not $Wire.questions[0].choices[1].PSObject.Properties['description'] -and
                $Wire.questions[1].choices.Count -eq 2 -and
                $Wire.questions[1].choices[0].value -eq 'repair' -and
                $Wire.questions[1].choices[1].value -is [bool] -and
                $Wire.questions[1].choices[1].value -eq $false -and
                -not $Wire.questions[1].choices[0].PSObject.Properties['description'] -and
                $Wire.questions[2].choices.Count -eq 2 -and
                $Wire.questions[2].choices[0].value -eq 'manual' -and
                $Wire.questions[2].choices[0].description -eq 'Handle manually.' -and
                $Wire.questions[2].choices[1].value -is [bool] -and
                $Wire.questions[2].choices[1].value -eq $false -and
                -not $Wire.questions[2].choices[1].PSObject.Properties['description']
            }
        }

        It 'Converts dictionary, enumerable, and property-based score inputs to API levels' {
            $Dictionary = [ordered]@{ Low = 'Minor damage.'; High = '' }
            $Labels = @('None', 'Moderate')
            $LevelObject = [pscustomobject]@{ label = 'Critical'; description = 'Cannot be used.' }
            $LevelObjectNoDescription = [pscustomobject]@{ label = 'Unknown'; description = '' }
            $LevelRecords = @(
                [ordered]@{ label = 'First'; description = 'First level.' }
                [pscustomobject]@{ label = 'Second'; description = '' }
            )
            $Params = @{
                Message                   = 'Evidence'
                ScoreQuestionInstructions = @('Dictionary levels?', 'Enumerable levels?', 'Object level?', 'Object level without description?', 'Object levels?')
                ScoreQuestionLevels       = @($Dictionary, $Labels, $LevelObject, $LevelObjectNoDescription, $LevelRecords)
            }

            Request-Decision @Params -ErrorAction Stop | Out-Null

            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Wire = $Body | ConvertTo-Json -Depth 20 | ConvertFrom-Json
                $Wire.questions.Count -eq 5 -and
                ($Wire.questions.type -join ',') -eq 'score,score,score,score,score' -and
                $Wire.questions[0].levels.Count -eq 2 -and
                $Wire.questions[0].levels[0].label -eq 'Low' -and
                $Wire.questions[0].levels[0].description -eq 'Minor damage.' -and
                $Wire.questions[0].levels[1].label -eq 'High' -and
                -not $Wire.questions[0].levels[1].PSObject.Properties['description'] -and
                $Wire.questions[1].levels.Count -eq 2 -and
                $Wire.questions[1].levels[0].label -eq 'None' -and
                $Wire.questions[1].levels[1].label -eq 'Moderate' -and
                -not $Wire.questions[1].levels[0].PSObject.Properties['description'] -and
                $Wire.questions[2].levels.Count -eq 1 -and
                $Wire.questions[2].levels[0].label -eq 'Critical' -and
                $Wire.questions[2].levels[0].description -eq 'Cannot be used.' -and
                $Wire.questions[3].levels.Count -eq 1 -and
                $Wire.questions[3].levels[0].label -eq 'Unknown' -and
                -not $Wire.questions[3].levels[0].PSObject.Properties['description'] -and
                $Wire.questions[4].levels.Count -eq 2 -and
                $Wire.questions[4].levels[0].label -eq 'First' -and
                $Wire.questions[4].levels[0].description -eq 'First level.' -and
                $Wire.questions[4].levels[1].label -eq 'Second' -and
                -not $Wire.questions[4].levels[1].PSObject.Properties['description']
            }
        }

        It 'Skips a choice question with fewer than two options and continues with later questions' {
            $ChoiceGroups = [object[]]::new(2)
            $ChoiceGroups[0] = [pscustomobject]@{ value = 'only'; description = 'Only option.' }
            $ChoiceGroups[1] = @('first', 'second')

            Request-Decision -Message 'Evidence' -ChoiceQuestionInstructions @('Invalid', 'Valid') -ChoiceQuestionChoices $ChoiceGroups -ErrorAction SilentlyContinue -ErrorVariable ChoiceErrors | Out-Null

            $ChoiceErrors | Should -HaveCount 1
            $ChoiceErrors[0].Exception.Message | Should -BeLike '*at least two choices*'
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Body.questions.Count -eq 1 -and
                $Body.questions[0].instructions -eq 'Valid' -and
                ($Body.questions[0].choices.value -join ',') -eq 'first,second'
            }
        }

        It 'Omits empty names while retaining predicate and score names without choice questions' {
            $Params = @{
                Message                       = 'Evidence'
                PredicateQuestionName         = @('present', '')
                PredicateQuestionInstructions = @('Named predicate?', 'Unnamed predicate?')
                ScoreQuestionName             = 'severity'
                ScoreQuestionInstructions     = 'How severe?'
                ScoreQuestionLevels           = , @('Low', 'High')
            }

            Request-Decision @Params -ErrorAction Stop | Out-Null

            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Body.questions.Count -eq 3 -and
                $Body.questions[0].name -eq 'present' -and
                -not $Body.questions[1].ContainsKey('name') -and
                $Body.questions[2].name -eq 'severity'
            }
        }

        It 'Rejects incomplete or mismatched question arrays before HTTP: <Name>' -TestCases @(
            @{ Name = 'no questions'; Params = @{} }
            @{ Name = 'predicate name only'; Params = @{ PredicateQuestionName = 'orphan' } }
            @{ Name = 'missing choice options'; Params = @{ ChoiceQuestionInstructions = 'Question' } }
            @{ Name = 'choice options only'; Params = @{ ChoiceQuestionChoices = , @(@{ value = $true }, @{ value = $false }) } }
            @{ Name = 'choice option group count'; Params = @{ ChoiceQuestionInstructions = @('First', 'Second'); ChoiceQuestionChoices = , @(@{ value = $true }, @{ value = $false }) } }
            @{ Name = 'flattened choice options'; Params = @{ ChoiceQuestionInstructions = 'Question'; ChoiceQuestionChoices = @(@{ value = $true }, @{ value = $false }) } }
            @{ Name = 'empty choice options'; Params = @{ ChoiceQuestionInstructions = 'Question'; ChoiceQuestionChoices = , @() } }
            @{ Name = 'missing score levels'; Params = @{ ScoreQuestionInstructions = 'Question' } }
            @{ Name = 'score levels only'; Params = @{ ScoreQuestionLevels = , @(@{ 'Low' = $null }, @{ 'High' = $null }) } }
            @{ Name = 'score level group count'; Params = @{ ScoreQuestionInstructions = @('First', 'Second'); ScoreQuestionLevels = , @(@{ 'Low' = $null }, @{ 'High' = $null }) } }
            @{ Name = 'empty score levels'; Params = @{ ScoreQuestionInstructions = 'Question'; ScoreQuestionLevels = , @() } }
        ) {
            param($Name, $Params)
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {} -Verifiable
            { Request-Decision -Message 'Evidence' @Params -ErrorAction Stop } | Should -Throw
            Should -Not -InvokeVerifiable
        }

        It 'Processes each pipeline text as a separate request' {
            $Results = 'First report', 'Second report' | Request-Decision @script:PredicateParameters -ErrorAction Stop
            $Results | Should -HaveCount 2
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { $Body.input -eq 'First report' }
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter { $Body.input -eq 'Second report' }
        }

        It 'Keeps multiple text parts and question types in their supplied order' {
            $Choices = @($false, 'false')
            $Levels = @('Low', 'Medium', 'High')
            $Params = @{
                Message                       = @('The display is cracked.', 'The device will not turn on.')
                PredicateQuestionInstructions = 'Is the display damaged?'
                ChoiceQuestionInstructions    = 'Can the device be used?'
                ChoiceQuestionChoices         = , $Choices
                ScoreQuestionInstructions     = 'Rate the damage.'
                ScoreQuestionLevels           = , $Levels
            }
            Request-Decision @Params -ErrorAction Stop | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Wire = $Body | ConvertTo-Json -Depth 100 | ConvertFrom-Json
                $Wire.input.Count -eq 1 -and $Wire.input[0].content.Count -eq 2 -and
                $Wire.input[0].content[0].text -eq 'The display is cracked.' -and
                $Wire.input[0].content[1].text -eq 'The device will not turn on.' -and
                ($Wire.questions.type -join ',') -eq 'predicate,choice,score' -and
                -not $Wire.questions[0].PSObject.Properties['name'] -and
                -not $Wire.questions[1].PSObject.Properties['name'] -and
                -not $Wire.questions[2].PSObject.Properties['name'] -and
                $Wire.questions[1].choices[0].value -is [bool] -and
                $Wire.questions[1].choices[0].value -eq $false -and
                $Wire.questions[1].choices[1].value -is [string] -and
                ($Wire.questions[2].levels.label -join ',') -eq 'Low,Medium,High'
            }
        }

        It 'Preserves boolean choices, fractional scores, refusal, and usage in a response' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
                '{"model":"gpt-6-luna","answers":[{"type":"choice","name":"accepted","choice":false,"confidence":0.8,"probabilities":[{"value":false,"probability":0.8},{"value":"false","probability":0.2}]},{"type":"score","name":"severity","score":1.1,"confidence":0.7,"probabilities":[{"label":"Low","value":0,"probability":0.1},{"label":"Medium","value":1,"probability":0.7},{"label":"High","value":2,"probability":0.2}]},{"type":"refusal","name":null}],"usage":{"input_tokens":42,"output_tokens":0,"total_tokens":42,"compute_units":null}}'
            }
            $Result = Request-Decision -Message 'Evidence' @script:PredicateParameters -ErrorAction Stop
            $Result.answers | Should -HaveCount 3
            $Result.answers[0].choice | Should -BeOfType [bool]
            $Result.answers[0].choice | Should -BeFalse
            $Result.answers[0].probabilities[1].value | Should -BeOfType [string]
            $Result.answers[1].score | Should -Be 1.1
            $Result.answers[2].type | Should -BeExactly 'refusal'
            $Result.answers[2].name | Should -BeNullOrEmpty
            $Result.usage.total_tokens | Should -Be 42
            $Result.usage.compute_units | Should -BeNullOrEmpty
        }

        It 'Converts local images to inline data URLs and retains inline image input' {
            $ImagePath = Join-Path $script:DecisionTestData 'car_broken.jpg'
            Request-Decision -Message 'Inspect these images.' -Images $ImagePath, 'data:image/png;base64,AA==' -ImageDetail ORIGINAL @script:PredicateParameters -ErrorAction Stop | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Body.input -is [array] -and $Body.input.Count -eq 1 -and
                $Body.input[0].role -eq 'user' -and $Body.input[0].content.Count -eq 3 -and
                $Body.input[0].content[0].text -eq 'Inspect these images.' -and
                $Body.input[0].content[1].image_url -match '^data:image/jpeg;base64,' -and
                $Body.input[0].content[1].detail -eq 'original' -and
                $Body.input[0].content[2].image_url -eq 'data:image/png;base64,AA=='
            }
        }

        It 'Supports image-only requests without inserting an empty text part' {
            Request-Decision -Images 'data:image/png;base64,AA==' @script:PredicateParameters -ErrorAction Stop | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Body.input[0].content.Count -eq 1 -and
                $Body.input[0].content[0].type -eq 'input_image' -and
                $Body.input[0].content[0].detail -eq 'auto'
            }
        }

        It 'Rejects missing input, missing images, directories, and external image URLs before HTTP' {
            { Request-Decision @script:PredicateParameters -ErrorAction Stop } | Should -Throw
            { Request-Decision -Images (Join-Path $TestDrive 'missing.png') @script:PredicateParameters -ErrorAction Stop } | Should -Throw
            { Request-Decision -Images $TestDrive @script:PredicateParameters -ErrorAction Stop } | Should -Throw
            { Request-Decision -Images 'https://example.test/image.png' @script:PredicateParameters -ErrorAction Stop } | Should -Throw
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 0 -Exactly
        }

        It 'Uses context, explicit connection options, custom models, and additional request fields' {
            Set-OpenAIContext -ApiBase 'https://example.test/custom/v1/' -TimeoutSec 15 -MaxRetryCount 2
            Request-Decision -Message 'Evidence' -Model 'custom-deployment' -TimeoutSec 30 -Organization 'org-test' -AdditionalQuery @{ key = 'value' } -AdditionalHeaders @{ 'X-Test' = 'test' } -AdditionalBody @{ extra = $false } @script:PredicateParameters -ErrorAction Stop | Out-Null
            Should -Invoke -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -Times 1 -Exactly -ParameterFilter {
                $Uri -eq 'https://example.test/custom/v1/decisions' -and
                $Body.model -eq 'custom-deployment' -and $TimeoutSec -eq 30 -and $MaxRetryCount -eq 2 -and
                $Organization -eq 'org-test' -and $AdditionalQuery.key -eq 'value' -and
                $AdditionalHeaders['X-Test'] -eq 'test' -and $AdditionalBody.extra -eq $false
            }
        }

        It 'Does not emit a result when HTTP returns no response' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest { $null }
            Request-Decision -Message 'Evidence' @script:PredicateParameters -ErrorAction Stop | Should -BeNullOrEmpty
        }

        It 'Reports malformed JSON without emitting a result' {
            Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest { 'invalid json' }
            $Result = Request-Decision -Message 'Evidence' @script:PredicateParameters -ErrorAction SilentlyContinue -ErrorVariable ParseError
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
            $ChoiceGroups = [object[]]::new(2)
            $ChoiceGroups[0] = @($true, $false)
            $ChoiceGroups[1] = @(
                [pscustomobject]@{ value = 'refund'; description = 'The owner wants a refund.' }
                [pscustomobject]@{ value = 'repair'; description = 'The owner wants a repair.' }
            )
            $Params = @{
                Message                       = "The car's front is smashed and the engine will not start. I want a refund, not a repair."
                Model                         = 'gpt-6-luna'
                PredicateQuestionName         = 'damaged'
                PredicateQuestionInstructions = 'Is the car damaged?'
                ChoiceQuestionName            = @('usable', 'resolution')
                ChoiceQuestionInstructions    = @('Can the car be driven as-is?', 'Which resolution does the owner request?')
                ChoiceQuestionChoices         = $ChoiceGroups
                ScoreQuestionName             = 'severity'
                ScoreQuestionInstructions     = 'How severe is the damage?'
                ScoreQuestionLevels           = , @(
                    [pscustomobject]@{ label = 'Low'; description = 'The car can be driven.' }
                    [pscustomobject]@{ label = 'Medium'; description = 'The car needs repair.' }
                    [pscustomobject]@{ label = 'High'; description = 'The car cannot be driven.' }
                )
                TimeoutSec                    = 90
                MaxRetryCount                 = 0
                ErrorAction                   = 'Stop'
            }
            $Result = Request-Decision @Params

            $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.Decision'
            $Result.model | Should -BeLike 'gpt-6-luna*'
            $Result.answers | Should -HaveCount 4
            ($Result.answers.type -join ',') | Should -BeExactly 'predicate,choice,choice,score'
            ($Result.answers.name -join ',') | Should -BeExactly 'damaged,usable,resolution,severity'
            $Result.answers[0].probability | Should -BeGreaterThan 0.5
            $Result.answers[1].choice | Should -BeOfType [bool]
            $Result.answers[1].choice | Should -BeFalse
            $Result.answers[2].choice | Should -BeExactly 'refund'
            $Result.answers[3].score | Should -BeGreaterOrEqual 0
            $Result.answers[3].score | Should -BeLessOrEqual 2
            $Result.answers[3].probabilities | Should -HaveCount 3
            $WeightedScore = ($Result.answers[3].probabilities | ForEach-Object { $_.value * $_.probability } | Measure-Object -Sum).Sum
            [Math]::Abs($Result.answers[3].score - $WeightedScore) | Should -BeLessThan 0.000001
            $Result.usage.input_tokens | Should -BeGreaterThan 0
            $Result.usage.total_tokens | Should -BeGreaterOrEqual $Result.usage.input_tokens
        }

        It 'Evaluates an existing local image' {
            $Params = @{
                Message                       = 'Compare the first and second car images in that order.'
                Images                        = @((Join-Path $script:DecisionTestData 'car_broken.jpg'), (Join-Path $script:DecisionTestData 'car_damaged.jpg'))
                ImageDetail                   = 'original'
                Model                         = 'gpt-6-luna'
                PredicateQuestionName         = 'first_more_damaged'
                PredicateQuestionInstructions = 'Is the car in the first image more severely damaged than the car in the second image?'
                ChoiceQuestionName            = 'missing_front_bodywork'
                ChoiceQuestionInstructions    = 'Which image shows a car with missing front bumper and exposed front components?'
                ChoiceQuestionChoices         = , @('first', 'second')
                TimeoutSec                    = 90
                MaxRetryCount                 = 0
                ErrorAction                   = 'Stop'
            }
            $Result = Request-Decision @Params

            $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.Decision'
            $Result.model | Should -BeLike 'gpt-6-luna*'
            $Result.answers | Should -HaveCount 2
            ($Result.answers.type -join ',') | Should -BeExactly 'predicate,choice'
            ($Result.answers.name -join ',') | Should -BeExactly 'first_more_damaged,missing_front_bodywork'
            $Result.answers[0].probability | Should -BeGreaterThan 0.5
            $Result.answers[0].probability | Should -BeLessOrEqual 1
            $Result.answers[1].choice | Should -BeExactly 'first'
            $Result.usage.input_tokens | Should -BeGreaterThan 0
            $Result.usage.total_tokens | Should -BeGreaterOrEqual $Result.usage.input_tokens
        }

        AfterAll {
            Clear-OpenAIContext
        }
    }
}
