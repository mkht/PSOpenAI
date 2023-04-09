function Request-ChatCompletion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('Request-ChatGPT')]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [string]$Model = 'gpt-3.5-turbo',

        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [string]$RolePrompt = '',

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [Alias('n')]
        [uint16]$NumberOfAnswers,

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
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [object]$Token,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [object[]]$History
    )

    begin {
        # Initialize API token
        [securestring]$SecureToken = Initialize-APIToken -Token $Token

        # Get API endpoint
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Chat.Completion'
    }

    process {
        # Message is required
        if ([string]::IsNullOrWhiteSpace($Message)) {
            Write-Error -Exception ([System.ArgumentException]::new('"Message" property is required.'))
            return
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $PostBody.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('TopP')) {
            $PostBody.top_p = $TopP
        }
        if ($PSBoundParameters.ContainsKey('NumberOfAnswers')) {
            $PostBody.n = $NumberOfAnswers
        }
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
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        if ($Stream) {
            $PostBody.stream = [bool]$Stream
            # When using the Stream option, limit NumberOfAnswers to 1 to optimize output. (this limit may be relaxed in the future)
            $PostBody.n = 1
        }
        #endregion

        #region Construct messages
        $Messages = [System.Collections.Generic.List[object]]::new()
        # Append past conversations
        foreach ($msg in $History) {
            if ($msg.role -and $msg.content) {
                $Messages.Add([ordered]@{
                        role    = $msg.role
                        content = $msg.content.Trim()
                    })
            }
        }
        # Specifies AI role (only if specified)
        if (-not [string]::IsNullOrWhiteSpace($RolePrompt)) {
            $Messages.Add([ordered]@{
                    role    = 'system'
                    content = $RolePrompt
                })
        }
        # Add user message (question)
        $Messages.Add([ordered]@{
                role    = 'user'
                content = $Message.Trim()
            })

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
                -Token $SecureToken `
                -Body $PostBody `
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
                -Token $SecureToken `
                -Body $PostBody

            # error check
            if ($null -eq $Response) {
                return
            }
        }
        #endregion

        #region Parse response object
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        if ($null -ne $Response.choices) {
            $ResponseContent = $Response.choices.message
        }
        # For history, add AI response to messages list.
        if (@($ResponseContent).Count -ge 1) {
            $Messages.Add([ordered]@{
                    role    = @($ResponseContent)[0].role
                    content = @($ResponseContent)[0].content
                })
        }
        #endregion

        #region Output
        # Add custom properties to output object.
        if ($unixtime = $Response.created -as [long]) {
            # convert unixtime to [DateTime] for read suitable
            $Response | Add-Member -MemberType NoteProperty -Name 'created' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
        $Response | Add-Member -MemberType NoteProperty -Name 'Message' -Value $Message.Trim()
        $Response | Add-Member -MemberType NoteProperty -Name 'Answer' -Value ([string[]]$ResponseContent.content)
        $Response | Add-Member -MemberType NoteProperty -Name 'History' -Value $Messages.ToArray()
        Write-Output $Response
        #endregion
    }

    end {

    }
}
