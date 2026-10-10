function Request-Decision {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Input')]
        [string[]]$Message,

        [Parameter()]
        [ValidateCount(1, 128)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Images,

        [Parameter()]
        [Completions('auto', 'low', 'high', 'original')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('gpt-6-luna')]
        [string]$Model = 'gpt-6-luna',

        #region Questions
        # Predicate
        [Parameter()]
        [string[]]$PredicateQuestionName,

        [Parameter()]
        [string[]]$PredicateQuestionInstructions,

        # Choice
        [Parameter()]
        [string[]]$ChoiceQuestionName,

        [Parameter()]
        [string[]]$ChoiceQuestionInstructions,

        [Parameter()]
        [System.Collections.IDictionary[][]]$ChoiceQuestionChoices,

        # Score
        [Parameter()]
        [string[]]$ScoreQuestionName,

        [Parameter()]
        [string[]]$ScoreQuestionInstructions,

        [Parameter()]
        [System.Collections.IDictionary[][]]$ScoreQuestionLevels,
        #endregion

        [Parameter()]
        [AllowEmptyString()]
        [ValidateLength(0, 128)]
        [Alias('safety_identifier')]
        [string]$SafetyIdentifier,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        $QuestionDefinitions = @()
        $QuestionGroups = @(
            @{
                Type         = 'predicate'
                Prefix       = 'PredicateQuestion'
                Instructions = $PredicateQuestionInstructions
                Names        = $PredicateQuestionName
                Options      = $null
                OptionsField = $null
            }
            @{
                Type         = 'choice'
                Prefix       = 'ChoiceQuestion'
                Instructions = $ChoiceQuestionInstructions
                Names        = $ChoiceQuestionName
                Options      = $ChoiceQuestionChoices
                OptionsField = 'choices'
            }
            @{
                Type         = 'score'
                Prefix       = 'ScoreQuestion'
                Instructions = $ScoreQuestionInstructions
                Names        = $ScoreQuestionName
                Options      = $ScoreQuestionLevels
                OptionsField = 'levels'
            }
        )

        foreach ($Group in $QuestionGroups) {
            if ($null -ne $Group.OptionsField -and $Group.Options.Count -ne $Group.Instructions.Count) {
                throw [System.ArgumentException]::new("The $($Group.Type) options must have one array for each $($Group.Prefix)Instructions entry.")
            }
            for ($i = 0; $i -lt $Group.Instructions.Count; $i++) {
                if ([string]::IsNullOrWhiteSpace($Group.Instructions[$i])) {
                    throw [System.ArgumentException]::new("$($Group.Prefix)Instructions entries must not be empty.")
                }
                $Definition = [System.Collections.Specialized.OrderedDictionary]::new()
                $Definition.type = $Group.Type
                $Definition.instructions = $Group.Instructions[$i]
                if ($Group.Names.Count -gt 0 -and -not [string]::IsNullOrEmpty($Group.Names[$i])) {
                    $Definition.name = $Group.Names[$i]
                }
                if ($null -ne $Group.OptionsField) {
                    if ($Group.Options[$i].Count -eq 0) {
                        throw [System.ArgumentException]::new("Each $($Group.Type) question must have a non-empty $($Group.OptionsField) array.")
                    }
                    $Definition[$Group.OptionsField] = @($Group.Options[$i])
                }
                $QuestionDefinitions += $Definition
            }
        }
        if ($QuestionDefinitions.Count -eq 0) {
            throw [System.ArgumentException]::new('At least one predicate, choice, or score question is required.')
        }

        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Decisions' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        $PostBody.questions = $QuestionDefinitions

        if ($Images.Count -gt 0 -or $Message.Count -gt 1) {
            $Parts = @()
            foreach ($Text in $Message) {
                $Parts += @{ type = 'input_text'; text = $Text }
            }
            foreach ($Image in $Images) {
                if ($Image -match '^data:image/[^;,]+;base64,') {
                    $ImageUrl = $Image
                }
                else {
                    # This parameter accepts local files and inline data URLs.
                    # Missing files and external URLs must fail before sending.
                    $ImageUrl = Convert-ImageToDataURL -File $Image -ErrorAction Stop
                }
                $Parts += @{ type = 'input_image'; image_url = $ImageUrl; detail = $ImageDetail }
            }
            $PostBody.input = @(@{ role = 'user'; content = $Parts })
        }
        elseif ($PSBoundParameters.ContainsKey('Message')) {
            $PostBody.input = $Message[0]
        }
        else {
            Write-Error -Exception ([System.ArgumentException]::new('Message or Images is required.'))
            return
        }

        if ($PSBoundParameters.ContainsKey('SafetyIdentifier')) {
            $PostBody.safety_identifier = $SafetyIdentifier
        }

        $params = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            Organization      = $OpenAIParameter.Organization
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIHttpRequest @params
        if ($null -eq $Response) {
            return
        }

        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }

        if ($null -ne $Response) {
            $Response.PSObject.TypeNames.Insert(0, 'PSOpenAI.Decision')
            Write-Output $Response
        }
    }
}
