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
        [object[]]$ChoiceQuestionChoices,

        # Score
        [Parameter()]
        [string[]]$ScoreQuestionName,

        [Parameter()]
        [string[]]$ScoreQuestionInstructions,

        [Parameter()]
        [object[]]$ScoreQuestionLevels,
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
        $Questions = @()
        #Predicate
        $PredicationQuestions = @()
        if ($PredicateQuestionInstructions.Count -gt 0) {
            for ($i = 0; $i -lt $PredicateQuestionInstructions.Count; $i++) {
                $p = @{
                    type         = 'predicate'
                    instructions = $PredicateQuestionInstructions[$i]
                }
                if ($null -ne $PredicateQuestionName -and -not [string]::IsNullOrEmpty($PredicateQuestionName[$i])) {
                    $p.name = $PredicateQuestionName[$i]
                }
                $PredicationQuestions += $p
            }
            if ($PredicationQuestions.Count -gt 0) {
                $Questions += $PredicationQuestions
            }
        }

        #Choice
        $ChoiceQuestions = @()
        if ($ChoiceQuestionInstructions.Count -gt 0) {
            if ($ChoiceQuestionChoices.Count -ne $ChoiceQuestionInstructions.Count) {
                Write-Error -Exception ([System.ArgumentException]::new('The ChoiceQuestionChoices parameter must have one hashtable for each ChoiceQuestionInstructions entry.'))
            }
            else {
                for ($i = 0; $i -lt $ChoiceQuestionInstructions.Count; $i++) {
                    if ($ChoiceQuestionChoices[$i].Count -eq 0) {
                        Write-Error -Exception ([System.ArgumentException]::new('Each choice question requires at least one choice.'))
                        continue
                    }
                    $q = @{
                        type         = 'choice'
                        instructions = $ChoiceQuestionInstructions[$i]
                        choices      = @()
                    }
                    if ($null -ne $ChoiceQuestionName -and -not [string]::IsNullOrEmpty($ChoiceQuestionName[$i])) {
                        $q.name = $ChoiceQuestionName[$i]
                    }

                    if ($ChoiceQuestionChoices[$i] -is [System.Collections.IDictionary]) {
                        foreach ($key in $ChoiceQuestionChoices[$i].Keys) {
                            $c = @{
                                value = $key
                            }
                            if (-not [string]::IsNullOrEmpty($ChoiceQuestionChoices[$i][$key])) {
                                $c.description = [string]$ChoiceQuestionChoices[$i][$key]
                            }
                            $q.choices += $c
                        }
                    }
                    elseif ( $ChoiceQuestionChoices[$i] -is [System.Collections.IEnumerable]) {
                        foreach ($value in $ChoiceQuestionChoices[$i]) {
                            if ($value -is [System.Collections.IDictionary] -and $value.Contains('value')) {
                                $c = @{ value = $value['value'] }
                                if (-not [string]::IsNullOrEmpty($value['description'])) {
                                    $c.description = [string]$value['description']
                                }
                            }
                            elseif ($null -ne $value -and $null -ne $value.PSObject.Properties['value']) {
                                $c = @{ value = $value.value }
                                if (-not [string]::IsNullOrEmpty($value.description)) {
                                    $c.description = [string]$value.description
                                }
                            }
                            else {
                                $c = @{ value = $value }
                            }
                            $q.choices += $c
                        }
                    }
                    elseif ( $ChoiceQuestionChoices[$i].value -is [string] -or $ChoiceQuestionChoices[$i].value -is [bool]) {
                        $c = @{ value = $ChoiceQuestionChoices[$i].value }
                        if (-not [string]::IsNullOrEmpty($ChoiceQuestionChoices[$i].description)) {
                            $c.description = [string]$ChoiceQuestionChoices[$i].description
                        }
                        $q.choices += $c
                    }
                    else {
                        Write-Error -Exception ([System.ArgumentException]::new('Each ChoiceQuestionChoices entry must be a hashtable or an array.'))
                    }

                    if ($q.choices.Count -lt 2) {
                        Write-Error -Exception ([System.ArgumentException]::new('Each choice question requires at least two choices.'))
                        continue
                    }
                    $ChoiceQuestions += $q
                }
                if ($ChoiceQuestions.Count -gt 0) {
                    $Questions += $ChoiceQuestions
                }
            }
        }

        #Score
        $ScoreQuestions = @()
        if ($ScoreQuestionInstructions.Count -gt 0) {
            if ($ScoreQuestionLevels.Count -ne $ScoreQuestionInstructions.Count) {
                Write-Error -Exception ([System.ArgumentException]::new('The ScoreQuestionLevels parameter must have one hashtable for each ScoreQuestionInstructions entry.'))
            }
            else {
                for ($i = 0; $i -lt $ScoreQuestionInstructions.Count; $i++) {
                    if ($ScoreQuestionLevels[$i].Count -eq 0) {
                        Write-Error -Exception ([System.ArgumentException]::new('Each score question requires at least one level.'))
                        continue
                    }
                    $q = @{
                        type         = 'score'
                        instructions = $ScoreQuestionInstructions[$i]
                        levels       = @()
                    }
                    if ($null -ne $ScoreQuestionName -and -not [string]::IsNullOrEmpty($ScoreQuestionName[$i])) {
                        $q.name = $ScoreQuestionName[$i]
                    }

                    if ($ScoreQuestionLevels[$i] -is [System.Collections.IDictionary]) {
                        foreach ($key in $ScoreQuestionLevels[$i].Keys) {
                            $l = @{
                                label = [string]$key
                            }
                            if (-not [string]::IsNullOrEmpty($ScoreQuestionLevels[$i][$key])) {
                                $l.description = [string]$ScoreQuestionLevels[$i][$key]
                            }
                            $q.levels += $l
                        }
                    }
                    elseif ( $ScoreQuestionLevels[$i] -is [System.Collections.IEnumerable]) {
                        foreach ($value in $ScoreQuestionLevels[$i]) {
                            if ($value -is [System.Collections.IDictionary] -and $value.Contains('label')) {
                                $l = @{ label = [string]$value['label'] }
                                if (-not [string]::IsNullOrEmpty($value['description'])) {
                                    $l.description = [string]$value['description']
                                }
                            }
                            elseif ($null -ne $value -and $null -ne $value.PSObject.Properties['label']) {
                                $l = @{ label = [string]$value.label }
                                if (-not [string]::IsNullOrEmpty($value.description)) {
                                    $l.description = [string]$value.description
                                }
                            }
                            else {
                                $l = @{ label = [string]$value }
                            }
                            $q.levels += $l
                        }
                    }
                    elseif ( $ScoreQuestionLevels[$i].label -as [string]) {
                        $l = @{ label = [string]$ScoreQuestionLevels[$i].label }
                        if (-not [string]::IsNullOrEmpty($ScoreQuestionLevels[$i].description)) {
                            $l.description = [string]$ScoreQuestionLevels[$i].description
                        }
                        $q.levels += $l
                    }
                    else {
                        Write-Error -Exception ([System.ArgumentException]::new('Each ScoreQuestionLevels entry must be a hashtable or an array.'))
                    }

                    $ScoreQuestions += $q
                }
                if ($ScoreQuestions.Count -gt 0) {
                    $Questions += $ScoreQuestions
                }
            }
        }

        if ($Questions.Count -eq 0) {
            $er = [System.Management.Automation.ErrorRecord]::new(
                [System.ArgumentException]::new('At least one question is required.'),
                'NoQuestions',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($er)
        }

        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Decisions' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        $PostBody.questions = $Questions

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
