function Request-AzureExtensionsChatCompletion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Text')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('user', 'system', 'tool')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter(Mandatory = $true)]
        [Alias('Engine')]
        [string]$Deployment,

        [Parameter()]
        [System.Collections.IDictionary[]]$DataSources,

        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [Alias('RolePrompt')]
        [string[]]$SystemMessage,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        # Extesions Chat Completions API does not have "n" parameter. (at least api-version:2023-06-01-preview)
        # [Parameter()]
        # [Alias('n')]
        # [uint16]$NumberOfAnswers,

        [Parameter()]
        [switch]$Stream = $false,

        [Parameter()]
        [ValidateCount(1, 4)]
        [Alias('stop')]
        [string[]]$StopSequence,

        [Parameter()]
        [ValidateRange(0, 4096)]
        [Alias('max_tokens')]
        [int]$MaxTokens,

        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [Alias('presence_penalty')]
        [double]$PresencePenalty,

        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [Alias('frequency_penalty')]
        [double]$FrequencyPenalty,

        [Parameter()]
        [Alias('logit_bias')]
        [System.Collections.IDictionary]$LogitBias,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [string]$ApiVersion,

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [ValidateSet('azure', 'azure_ad')]
        [string]$AuthType = 'azure',

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [object[]]$History
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-AzureAPIBase -ApiBase $ApiBase

        # Get API endpoint
        $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Chat.Completion.Extensions' -Engine $Deployment -ApiBase $ApiBase -ApiVersion $ApiVersion

        # Temporal model name
        $Model = 'gpt-3.5-turbo'

        # Set Mandatory headers
        $Headers = @{
            'Chatgpt_url' = (Get-AzureOpenAIAPIEndpoint -EndpointName 'Text.Completion' -Engine $Deployment -ApiBase $ApiBase -ApiVersion $ApiVersion).Uri.AbsoluteUri
            'Chatgpt_key' = (DecryptSecureString $SecureToken)
        }
    }

    process {
        #region Parameter Validation
        # Warning
        if ($PSBoundParameters.ContainsKey('Name') -and (-not $PSBoundParameters.ContainsKey('Message'))) {
            Write-Warning 'Name parameter is ignored because the Message parameter is not specified.'
        }
        #endregion

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($PSBoundParameters.ContainsKey('DataSources')) {
            $PostBody.dataSources = $DataSources
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $PostBody.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('TopP')) {
            $PostBody.top_p = $TopP
        }
        # if ($PSBoundParameters.ContainsKey('NumberOfAnswers')) {
        #     $PostBody.n = $NumberOfAnswers
        # }
        if ($PSBoundParameters.ContainsKey('StopSequence')) {
            $PostBody.stop = $StopSequence
        }
        if ($PSBoundParameters.ContainsKey('MaxTokens')) {
            $PostBody.max_tokens = $MaxTokens
        }
        if ($PSBoundParameters.ContainsKey('PresencePenalty')) {
            $PostBody.presence_penalty = $PresencePenalty
        }
        if ($PSBoundParameters.ContainsKey('FrequencyPenalty')) {
            $PostBody.frequency_penalty = $FrequencyPenalty
        }
        if ($PSBoundParameters.ContainsKey('LogitBias')) {
            $PostBody.logit_bias = Convert-LogitBiasDictionary -InputObject $LogitBias -Model $Model
        }
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        if ($Stream) {
            $PostBody.stream = [bool]$Stream
            # When using the Stream option, limit NumberOfAnswers to 1 to optimize output. (this limit may be relaxed in the future)
            # $PostBody.n = 1
        }
        #endregion

        #region Construct messages
        $Messages = [System.Collections.Generic.List[object]]::new()
        # Append past conversations
        foreach ($msg in $History) {
            if ($msg.role -and $msg.content) {
                $tm = [ordered]@{
                    role    = [string]$msg.role
                    content = ([string]$msg.content).Trim()
                }
                # name is optional
                if ($msg.name) {
                    $tm.name = [string]$msg.name
                }
                $Messages.Add($tm)
            }
        }
        # Specifies system messages (only if specified)
        foreach ($rp in $SystemMessage) {
            if (-not [string]::IsNullOrWhiteSpace($rp)) {
                $Messages.Add([ordered]@{
                        role    = 'system'
                        content = $rp.Trim()
                    })
            }
        }
        # Add user message (question)
        if (-not [string]::IsNullOrWhiteSpace($Message)) {
            $um = [ordered]@{
                role    = $Role
                content = $Message.Trim()
            }
            # name poperty is optional
            if (-not [string]::IsNullOrWhiteSpace($Name)) {
                $um.name = $Name.Trim()
            }
            $Messages.Add($um)
        }

        # Error if messages is empty.
        if ($Messages.Count -eq 0) {
            Write-Error 'No message is specified. You must specify one or more messages.'
            return
        }

        $PostBody.messages = $Messages.ToArray()
        #endregion

        #region Send API Request (Stream)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequest `
                -Method $OpenAIParameter.Method `
                -Uri $OpenAIParameter.Uri `
                -ContentType $OpenAIParameter.ContentType `
                -TimeoutSec $TimeoutSec `
                -MaxRetryCount $MaxRetryCount `
                -ApiKey $SecureToken `
                -AuthType $AuthType `
                -Body $PostBody `
                -Headers $Headers `
                -Stream $Stream |`
                Where-Object {
                -not [string]::IsNullOrEmpty($_)
            } | ForEach-Object {
                try {
                    $_ | ConvertFrom-Json -ErrorAction Stop
                }
                catch {
                    Write-Error -Exception $_.Exception
                }
            } | Where-Object {
                $null -ne $_.choices -and $_.choices[0].delta.content -is [string]
            } | ForEach-Object {
                # Writes content to both the Information stream(6>) and the Standard output stream(1>).
                $InfoMsg = [System.Management.Automation.HostInformationMessage]::new()
                $InfoMsg.Message = $_.choices[0].delta.content
                $InfoMsg.NoNewLine = $true
                Write-Information $InfoMsg
                Write-Output $InfoMsg.Message
            }
            return
        }
        #endregion

        #region Send API Request (No Stream)
        else {
            $Response = Invoke-OpenAIAPIRequest `
                -Method $OpenAIParameter.Method `
                -Uri $OpenAIParameter.Uri `
                -ContentType $OpenAIParameter.ContentType `
                -TimeoutSec $TimeoutSec `
                -MaxRetryCount $MaxRetryCount `
                -ApiKey $SecureToken `
                -AuthType $AuthType `
                -Body $PostBody `
                -Headers $Headers

            # error check
            if ($null -eq $Response) {
                return
            }
            # Parse response object
            try {
                $Response = $Response | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                Write-Error -Exception $_.Exception
                return
            }
        }
        #endregion

        #region For history, add AI response to messages list.
        foreach ($tr in @($Response.choices[0].messages)) {
            $rcm = [ordered]@{
                role    = $tr.role
                content = $tr.content
            }
            if ($tr.recipient) {
                $rcm.recipient = $tr.recipient
            }
            if ($tr.end_turn -is [bool]) {
                $rcm.end_turn = $tr.end_turn
            }
            $Messages.Add($rcm)
        }
        #endregion

        #region Output
        # Add custom type name and properties to output object.
        $Response.PSObject.TypeNames.Insert(0, 'PSOpenAI.Chat.Completion')
        if ($null -ne $Response.created -and ($unixtime = $Response.created -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $Response | Add-Member -MemberType NoteProperty -Name 'created' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
        $Response | Add-Member -MemberType NoteProperty -Name 'Message' -Value ($Messages.Where({ $_.role -eq 'user' })[-1].content)
        $Response | Add-Member -MemberType NoteProperty -Name 'Answer' -Value ([string[]]$Messages.Where({ $_.role -eq 'assistant' })[-1].content)
        $Response | Add-Member -MemberType NoteProperty -Name 'History' -Value $Messages.ToArray()
        Write-Output $Response
        #endregion
    }

    end {
        $Headers = $null
    }
}
