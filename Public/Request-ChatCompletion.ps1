function Request-ChatCompletion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('Request-ChatGPT')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
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

        [Parameter()]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-3.5-turbo-16k',
            'gpt-3.5-turbo-0613',
            'gpt-3.5-turbo-16k-0613',
            'gpt-3.5-turbo-1106',
            'gpt-3.5-turbo-0125',
            'gpt-4-0613',
            'gpt-4-32k',
            'gpt-4-32k-0613',
            'gpt-4-turbo',
            'gpt-4-turbo-2024-04-09'
        )]
        [string][LowerCaseTransformation()]$Model = 'gpt-3.5-turbo',

        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [Alias('RolePrompt')]
        [string[]]$SystemMessage,

        # For GPT-4 Turbo with Vision
        [Parameter()]
        [string[]]$Images,

        [Parameter()]
        [ValidateSet('auto', 'low', 'high')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',

        #region Function call params
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Tools,

        # deprecated
        [Parameter(DontShow)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Functions,

        [Parameter()]
        [Alias('tool_choice')]
        [Completions('none', 'auto')]
        [object]$ToolChoice,

        # deprecated
        [Parameter(DontShow)]
        [Alias('function_call')]
        [Completions('none', 'auto')]
        [object]$FunctionCall,

        [Parameter()]
        [Alias('InvokeFunctionOnCallMode')] # For backward compatibilty
        [ValidateSet('None', 'Auto', 'Confirm')]
        [string]$InvokeTools = 'None',

        # deprecated
        [Parameter(DontShow)]
        [uint16]$MaxFunctionCallCount,
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
        [ValidateRange(0, 2147483647)]
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
        [bool]$LogProbs,

        [Parameter()]
        [ValidateRange(0, 20)]
        [Alias('top_logprobs')]
        [uint16]$TopLogProbs,

        [Parameter()]
        [Alias('response_format')]
        [ValidateSet('text', 'json_object', 'raw_response')]
        [string][LowerCaseTransformation()]$Format = 'text',

        [Parameter()]
        [int64]$Seed,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization,

        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$History,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API context
        $OpenAIParameter = Get-OpenAIContext -EndpointName 'Chat.Completion' -ApiType $ApiType -AuthType $AuthType -Engine $Model -ApiBase $ApiBase -ApiVersion $ApiVersion

        if ($ApiType -eq [OpenAIApiType]::Azure) {
            # Temporal engine name for Azure
            $Engine = 'gpt-3.5-turbo'
        }
        else {
            $Engine = $Model
        }
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
        if ($PSBoundParameters.ContainsKey('MaxFunctionCallCount')) {
            Write-Warning 'MaxFunctionCallCount parameter is deprecated.'
        }
        #endregion

        #region Tools paramter validation
        if ($PSBoundParameters.ContainsKey('Tools')) {
            $tmpTools = [System.Collections.IDictionary[]]::new($Tools.Count)
            for ($i = 0; $i -lt $Tools.Count; $i++) {
                if ($Tools[$i].Contains('type')) {
                    $tmpTools[$i] = $Tools[$i]
                }
                else {
                    $tmpTools[$i] = @{
                        'type'     = 'function'
                        'function' = $Tools[$i]
                    }
                }
            }
            $Tools = $tmpTools
        }
        elseif ($PSBoundParameters.ContainsKey('Functions')) {
            $tmpTools = [System.Collections.IDictionary[]]::new($Functions.Count)
            for ($i = 0; $i -lt $Functions.Count; $i++) {
                $tmpTools[$i] = @{
                    'type'     = 'function'
                    'function' = $Functions[$i]
                }
            }
            $Tools = $tmpTools
        }
        #endregion

        #region Construct parameters for API request
        $Response = $null
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($ApiType -eq [OpenAIApiType]::OpenAI) {
            $PostBody.model = $Model
        }
        if ($PSBoundParameters.ContainsKey('Tools')) {
            $PostBody.tools = @($Tools)
        }
        # deprecated
        if ($PSBoundParameters.ContainsKey('Functions')) {
            $PostBody.functions = @($Functions)
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            $PostBody.tool_choice = $ToolChoice
        }
        # deprecated
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
            $PostBody.logit_bias = Convert-LogitBiasDictionary -InputObject $LogitBias -Model $Engine
        }
        if ($PSBoundParameters.ContainsKey('LogProbs')) {
            $PostBody.logprobs = $LogProbs
            if ($LogProbs -and $PSBoundParameters.ContainsKey('TopLogProbs')) {
                $PostBody.top_logprobs = $TopLogProbs
            }
        }
        if ($PSBoundParameters.ContainsKey('Format') -and $Format -ne 'raw_response') {
            $PostBody.response_format = @{'type' = $Format }
        }
        if ($PSBoundParameters.ContainsKey('Seed')) {
            $PostBody.seed = $Seed
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
                    role    = [string]$msg.role
                    content = $msg.content
                }
                # name is optional
                if ($msg.name) {
                    $tm.name = [string]$msg.name
                }
                # tool_calls is optional
                if ($msg.tool_calls) {
                    $tm.tool_calls = $msg.tool_calls
                }
                # tool_call_id is optional
                if ($msg.tool_call_id) {
                    $tm.tool_call_id = $msg.tool_call_id
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
            # For GPT-4 with Vison
            if ($PSBoundParameters.ContainsKey('Images')) {
                $um.content = @(
                    @{type = 'text'; text = $Message.Trim() }
                )
                foreach ($image in $Images) {
                    $imc = $null
                    if (Test-Path -LiteralPath $image -PathType Leaf) {
                        $imc = @{type = 'image_url'; image_url = @{url = (Convert-ImageToDataURL $image) } }
                    }
                    else {
                        $imc = @{type = 'image_url'; image_url = @{url = $image } }
                    }
                    if ($null -eq $imc) { continue }
                    if ($PSBoundParameters.ContainsKey('ImageDetail')) {
                        $imc.image_url.detail = $ImageDetail
                    }
                    $um.content += $imc
                }
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
            $splat = @{
                Method            = $OpenAIParameter.Method
                Uri               = $OpenAIParameter.Uri
                ContentType       = $OpenAIParameter.ContentType
                TimeoutSec        = $TimeoutSec
                MaxRetryCount     = $MaxRetryCount
                ApiKey            = $SecureToken
                AuthType          = $OpenAIParameter.AuthType
                Organization      = $Organization
                Body              = $PostBody
                Stream            = $Stream
                AdditionalQuery   = $AdditionalQuery
                AdditionalHeaders = $AdditionalHeaders
                AdditionalBody    = $AdditionalBody
            }
            Invoke-OpenAIAPIRequest @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object {
                    if ($Format -eq 'raw_response') {
                        $_
                    }
                    else {
                        try {
                            $_ | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            Write-Error -Exception $_.Exception
                        }
                    }
                } | Where-Object {
                    $Format -eq 'raw_response' -or ($null -ne $_.choices -and ($_.choices[0].delta.content -is [string]))
                } | ForEach-Object -Process {
                    if ($Format -eq 'raw_response') {
                        Write-Output $_
                    }
                    else {
                        # Writes content to both the Information stream(6>) and the Standard output stream(1>).
                        $InfoMsg = [System.Management.Automation.HostInformationMessage]::new()
                        $InfoMsg.Message = $_.choices[0].delta.content
                        $InfoMsg.NoNewLine = $true
                        Write-Information $InfoMsg
                        Write-Output $InfoMsg.Message
                    }
                }

            return
        }
        #endregion

        #region Send API Request (No Stream)
        else {
            $splat = @{
                Method            = $OpenAIParameter.Method
                Uri               = $OpenAIParameter.Uri
                ContentType       = $OpenAIParameter.ContentType
                TimeoutSec        = $TimeoutSec
                MaxRetryCount     = $MaxRetryCount
                ApiKey            = $SecureToken
                AuthType          = $OpenAIParameter.AuthType
                Organization      = $Organization
                Body              = $PostBody
                AdditionalQuery   = $AdditionalQuery
                AdditionalHeaders = $AdditionalHeaders
                AdditionalBody    = $AdditionalBody
            }
            $Response = Invoke-OpenAIAPIRequest @splat

            # error check
            if ($null -eq $Response) {
                return
            }
            if ($Format -eq 'raw_response') {
                Write-Output $Response
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
            if ($tr.tool_calls) {
                $rcm.Add('tool_calls', $tr.tool_calls)
            }
            #deprecated
            if ($tr.function_call) {
                $rcm.Add('function_call', $tr.function_call)
            }
            $Messages.Add($rcm)
        }
        #endregion

        #region Function call
        if ($null -ne $Response.choices -and $Response.choices[0].finish_reason -in ('tool_calls', 'function_call')) {
            $ToolCallResults = @()
            $fCalls = @()
            if ($Response.choices[0].finish_reason -eq 'tool_calls') {
                $fCalls = @($Response.choices[0].message.tool_calls)
            }
            else {
                # function_call (deprecared)
                $IsLegacyFunctionCall = $true
                $fCalls = @(@{
                        type     = 'function'
                        function = $Response.choices[0].message.function_call
                    })
            }

            foreach ($fCall in $fCalls) {
                if ($fCall.type -ne 'function') {
                    continue
                }
                if ($fCall.function.name -notin $Tools.Where({ $_.type -eq 'function' }).function.name) {
                    Write-Error ('"{0}" does not matches the list of functions. This command should not be executed.' -f $fCall.function.name)
                    continue
                }
                Write-Verbose ('AI assistant preferes to call a function. (function:{0}, arguments:{1})' -f $fCall.function.name, ($fCall.function.arguments -replace '[\r\n]', ''))

                $fCommandResult = $null
                try {
                    # Execute command
                    $fCommandResult = Invoke-ChatCompletionFunction -Name $fCall.function.name -Arguments $fCall.function.arguments -InvokeFunctionOnCallMode $InvokeTools -ErrorAction Stop
                }
                catch {
                    Write-Error -ErrorRecord $_
                    $fCommandResult = '[ERROR] ' + $_.Exception.Message
                }
                if ($null -eq $fCommandResult) {
                    continue
                }
                if (-not $IsLegacyFunctionCall) {
                    $ToolCallResults += @{
                        role         = 'tool'
                        content      = $(if ($fCommandResult -is [string]) { $fCommandResult }else { (ConvertTo-Json $fCommandResult) })
                        tool_call_id = $fCall.id
                    }
                }
                else {
                    $ToolCallResults += @{
                        role    = 'function'
                        content = $(if ($fCommandResult -is [string]) { $fCommandResult }else { (ConvertTo-Json $fCommandResult) })
                        name    = $fCall.function.name
                    }
                }
            }

            # Second request
            if ($ToolCallResults.Count -gt 0) {
                Write-Verbose 'The function has been executed. The result of the execution is sent to the API.'
                $SecondRequestParam = $PSBoundParameters
                $null = $SecondRequestParam.Remove('Message')
                $null = $SecondRequestParam.Remove('Role')
                $null = $SecondRequestParam.Remove('Name')
                $null = $SecondRequestParam.Remove('SystemMessage')
                $Messages.AddRange($ToolCallResults)
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
        $LastUserMessage = ($Messages.Where({ $_.role -eq 'user' })[-1].content)
        if ($LastUserMessage -isnot [string]) {
            $LastUserMessage = [string]($LastUserMessage | Where-Object { $_.type -eq 'text' } | Select-Object -Last 1).text
        }
        $Response | Add-Member -MemberType NoteProperty -Name 'Message' -Value $LastUserMessage
        $Response | Add-Member -MemberType NoteProperty -Name 'Answer' -Value ([string[]]$Response.choices.message.content)
        $Response | Add-Member -MemberType NoteProperty -Name 'History' -Value $Messages.ToArray()
        Write-Output $Response
        #endregion
    }

    end {

    }
}
