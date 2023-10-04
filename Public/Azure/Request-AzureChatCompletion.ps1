function Request-AzureChatCompletion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('Request-AzureChatGPT')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Text')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('user', 'system', 'function')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter()]
        [ValidatePattern('^[a-zA-Z0-9_-]{1,64}$')]   # May contain a-z, A-Z, 0-9, hyphens, and underscores, with a maximum length of 64 characters.
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [Alias('Engine')]
        [string]$Deployment,

        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [Alias('RolePrompt')]
        [string[]]$SystemMessage,

        #region Function call params
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Functions,

        [Parameter()]
        [Alias('function_call')]
        [Completions('none', 'auto')]
        [object]$FunctionCall,

        [Parameter()]
        [ValidateSet('None', 'Auto', 'Confirm')]
        [string]$InvokeFunctionOnCallMode = 'None',

        [Parameter()]
        [ValidateRange(0, 65535)]
        [uint16]$MaxFunctionCallCount = 4,
        #endregion Function call params

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
        $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Chat.Completion' -Engine $Deployment -ApiBase $ApiBase -ApiVersion $ApiVersion

        # Temporal model name
        $Model = 'gpt-3.5-turbo'
    }

    process {
        #region Parameter Validation
        # Error
        if ([string]::IsNullOrEmpty($Name) -and $Role -eq 'function') {
            Write-Error 'Messages with role "function" must have a name.'
            return
        }
        # Warning
        if ($PSBoundParameters.ContainsKey('Name') -and (-not $PSBoundParameters.ContainsKey('Message'))) {
            Write-Warning 'Name parameter is ignored because the Message parameter is not specified.'
        }
        #endregion

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        # No need for Azure
        # $PostBody.model = $Model
        if ($PSBoundParameters.ContainsKey('Functions')) {
            $PostBody.functions = @($Functions)
        }
        if ($PSBoundParameters.ContainsKey('FunctionCall')) {
            $PostBody.function_call = $FunctionCall
        }
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
        if ($PSBoundParameters.ContainsKey('LogitBias')) {
            $PostBody.logit_bias = Convert-LogitBiasDictionary -InputObject $LogitBias -Model $Model
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
            if ($msg.role) {
                $tm = [ordered]@{
                    role = [string]$msg.role
                }
                # content is mandatory
                if ($null -eq $msg.content) {
                    $tm.content = $null
                }
                else {
                    $tm.content = ([string]$msg.content).Trim()
                }
                # name is optional
                if ($msg.name) {
                    $tm.name = [string]$msg.name
                }
                # function_call is optional
                if ($msg.function_call) {
                    $tm.function_call = $msg.function_call
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

        # Do not accept function call when the number of function calls has reached to limit.
        if ($Messages.Where({ $_.function_call }).Count -ge $MaxFunctionCallCount) {
            Write-Warning 'The number of function calls in this chat session has reached the value specified in the MaxFunctionCallCount. No more function calls will be accepted.'
            $FunctionCall = 'none'
            $PostBody.function_call = $FunctionCall
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
                $null -ne $_.choices -and ($_.choices[0].delta.content -is [string] -or $_.choices[0].delta.function_call)
            } | ForEach-Object -Begin { $FuncCallObject = @() } -Process {
                if ($_.choices[0].delta.content) {
                    $InfoMsg = $_.choices[0].delta.function_call
                    # Writes content to both the Information stream(6>) and the Standard output stream(1>).
                    $InfoMsg = [System.Management.Automation.HostInformationMessage]::new()
                    $InfoMsg.Message = $_.choices[0].delta.content
                    $InfoMsg.NoNewLine = $true
                    Write-Information $InfoMsg
                    Write-Output $InfoMsg.Message
                }
                elseif ($_.choices[0].delta.function_call) {
                    $FuncCallObject += $_.choices[0].delta.function_call
                }
            } -End {
                if ($FuncCallObject.Count -gt 0) {
                    $Response = ConvertFrom-Json '{"choices":[{"message":{"role":"assistant","content":"","function_call":{"name":"","arguments":""}},"finish_reason":"function_call"}]}'
                    $Response.choices[0].message.function_call.name = (-join $FuncCallObject.name)
                    $Response.choices[0].message.function_call.arguments = (-join $FuncCallObject.arguments)
                    $IsContinue = $true
                }
            }

            if (-not $IsContinue) { return }
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
                -Body $PostBody

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
        if (@($Response.choices.message).Count -ge 1) {
            $tr = @($Response.choices.message)[0]
            $rcm = [ordered]@{
                role    = $tr.role
                content = $tr.content
            }
            if ($tr.function_call) {
                $rcm.Add('function_call', $tr.function_call)
            }
            $Messages.Add($rcm)
        }
        #endregion

        #region Function call
        if ($null -ne $Response.choices -and $Response.choices[0].finish_reason -eq 'function_call') {
            $fCommandResult = $null
            $fCall = $Response.choices[0].message.function_call
            Write-Verbose ('AI assistant preferes to call a function. (function:{0}, arguments:{1})' -f $fCall.name, ($fCall.arguments -replace '[\r\n]', ''))

            # Check the command name matches the list supplied
            if ($fCall.name -notin $Functions.name) {
                Write-Error ('"{0}" does not matches the list of functions. This command should not be executed.' -f $fCall.name)
            }
            elseif ($FunctionCall -eq 'none') {
                Write-Error 'The number of function calls in this chat session has exceeded the value specified in the MaxFunctionCallCount. This command should not be executed.'
            }
            else {
                try {
                    # Execute command
                    $fCommandResult = Invoke-ChatCompletionFunction -Name $fCall.name -Arguments $fCall.arguments -InvokeFunctionOnCallMode $InvokeFunctionOnCallMode -ErrorAction Stop
                }
                catch {
                    Write-Error -ErrorRecord $_
                    $fCommandResult = '[ERROR] ' + $_.Exception.Message
                }
            }

            # Second request
            if ($null -ne $fCommandResult) {
                Write-Verbose 'The function has been executed. The result of the execution is sent to the API.'
                $SecondRequestParam = $PSBoundParameters
                if ($fCommandResult -is [string]) {
                    $SecondRequestParam.Message = $fCommandResult
                }
                else {
                    $SecondRequestParam.Message = (ConvertTo-Json $fCommandResult)
                }
                $SecondRequestParam.Role = 'function'
                $SecondRequestParam.Name = $fCall.name
                # $SecondRequestParam.Remove('Functions')
                $SecondRequestParam.History = $Messages.ToArray()
                Request-ChatCompletion @SecondRequestParam
                return
            }
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
        $Response | Add-Member -MemberType NoteProperty -Name 'Answer' -Value ([string[]]$Response.choices.message.content)
        $Response | Add-Member -MemberType NoteProperty -Name 'History' -Value $Messages.ToArray()
        Write-Output $Response
        #endregion
    }

    end {

    }
}
