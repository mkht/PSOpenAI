function Request-ChatCompletion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('Request-ChatGPT')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline)]
        [Alias('Text')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('user', 'system', 'developer', 'function')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter()]
        [ValidatePattern('^[a-zA-Z0-9_-]{1,64}$')]   # May contain a-z, A-Z, 0-9, hyphens, and underscores, with a maximum length of 64 characters.
        [string]$Name,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-4o',
            'gpt-4o-mini',
            'gpt-4o-audio-preview',
            'gpt-4o-mini-audio-preview',
            'gpt-4o-search-preview',
            'gpt-4o-mini-search-preview',
            'gpt-3.5-turbo-16k',
            'gpt-3.5-turbo-1106',
            'gpt-3.5-turbo-0125',
            'gpt-4-0613',
            'gpt-4-32k',
            'gpt-4-32k-0613',
            'gpt-4-turbo',
            'gpt-4-turbo-2024-04-09',
            'gpt-4.1',
            'gpt-4.1-mini',
            'gpt-4.1-nano',
            'gpt-5',
            'gpt-5-mini',
            'gpt-5-nano',
            'gpt-5-chat-latest',
            'gpt-5.1',
            'gpt-5.1-chat-latest',
            'gpt-audio',
            'gpt-audio-mini',
            'o1',
            'o3',
            'o3-mini',
            'o4-mini'
        )]
        [string]$Model = 'gpt-3.5-turbo',

        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [Alias('RolePrompt')]
        [string[]]$SystemMessage,

        [Parameter()]
        [AllowEmptyString()]
        [string[]]$DeveloperMessage,

        # For Audio
        [Parameter()]
        [ValidateSet('text', 'audio')]
        [string[]]$Modalities,

        [Parameter()]
        [Completions('alloy', 'ash', 'ballad', 'coral', 'echo', 'fable', 'nova', 'onyx', 'sage', 'shimmer')]
        [string][LowerCaseTransformation()]$Voice = 'alloy',

        [Parameter()]
        [Alias('input_audio')]
        [string]$InputAudio,

        [Parameter()]
        [Completions('wav', 'mp3')]
        [string][LowerCaseTransformation()]$InputAudioFormat,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$AudioOutFile,

        [Parameter()]
        [Completions('wav', 'aac', 'mp3', 'flac', 'opus', 'pcm16')]
        [string][LowerCaseTransformation()]$OutputAudioFormat = 'mp3',

        # For Vison
        [Parameter()]
        [string[]]$Images,

        [Parameter()]
        [ValidateSet('auto', 'low', 'high')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',

        #region Function call params
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [Alias('tool_choice')]
        [Completions('none', 'auto', 'required')]
        [object]$ToolChoice,

        [Parameter()]
        [Alias('parallel_tool_calls')]
        [switch]$ParallelToolCalls,

        [Parameter()]
        [Alias('InvokeFunctionOnCallMode')] # For backward compatibilty
        [ValidateSet('None', 'Auto', 'Confirm')]
        [string]$InvokeTools = 'None',
        #endregion Function call params

        #region Web Search
        [Parameter()]
        [ValidateSet('low', 'medium', 'high')]
        [string][LowerCaseTransformation()]$WebSearchContextSize,

        [Parameter(DontShow)]
        [string]$WebSearchUserLocationType = 'approximate', # Currently, only 'approximate' is acceptable.

        [Parameter()]
        [string]$WebSearchUserLocationCity,

        [Parameter()]
        [string]$WebSearchUserLocationCountry,

        [Parameter()]
        [string]$WebSearchUserLocationRegion,

        [Parameter()]
        [string]$WebSearchUserLocationTimeZone,
        #endregion Web Search

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Prediction,

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
        [switch]$Store = $false,

        [Parameter()]
        [Completions('low', 'medium', 'high')]
        [string]$Verbosity = 'medium',

        [Parameter()]
        [Alias('reasoning_effort')]
        [Completions('none', 'minimal', 'low', 'medium', 'high', 'xhigh')]
        [string]$ReasoningEffort,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [ValidateCount(1, 4)]
        [Alias('stop')]
        [string[]]$StopSequence,

        [Parameter()]
        [System.Obsolete('The MaxTokens is now deprecated in favor of MaxCompletionTokens')]
        [Alias('max_tokens')]
        [int]$MaxTokens,

        [Parameter()]
        [Alias('max_completion_tokens')]
        [int]$MaxCompletionTokens,

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
        [Alias('Format')]  # for backward compatibility
        [Completions('text', 'json_object', 'json_schema', 'raw_response')]
        [object]$ResponseFormat = 'text',

        [Parameter()]
        [string]$JsonSchema,

        [Parameter()]
        [int64]$Seed,

        [Parameter()]
        [Alias('service_tier')]
        [Completions('auto', 'default', 'flex', 'scale')]
        [string]$ServiceTier,

        [Parameter()]
        [Alias('prompt_cache_key')]
        [string]$PromptCacheKey,

        [Parameter()]
        [Alias('prompt_cache_retention')]
        [Completions('in_memory', '24h')]
        [string]$PromptCacheRetention,

        [Parameter()]
        [Alias('safety_identifier')]
        [string]$SafetyIdentifier,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [switch]$AsBatch,

        [Parameter()]
        [string]$CustomBatchId,

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
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Chat.Completion' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop

        if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::Azure) {
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
        #endregion

        #region Tools parameter validation
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
        if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::OpenAI -or $AsBatch) {
            $PostBody.model = $Model
        }
        if ($PSBoundParameters.ContainsKey('Modalities')) {
            $PostBody.modalities = $Modalities
            if ($Modalities -contains 'audio') {
                $PostBody.audio = @{
                    'voice'  = $Voice
                    'format' = $OutputAudioFormat
                }
            }
        }
        if ($PSBoundParameters.ContainsKey('Tools')) {
            $PostBody.tools = @($Tools)
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            $PostBody.tool_choice = $ToolChoice
        }
        if ($PSBoundParameters.ContainsKey('ParallelToolCalls')) {
            $PostBody.parallel_tool_calls = [bool]$ParallelToolCalls
        }
        if ($PSBoundParameters.ContainsKey('Prediction')) {
            $PostBody.prediction = @{
                'type'    = 'content'
                'content' = $Prediction
            }
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
        if ($Store.IsPresent) {
            $PostBody.store = $Store.ToBool()
        }
        if ($PSBoundParameters.ContainsKey('ReasoningEffort')) {
            $PostBody.reasoning_effort = $ReasoningEffort
        }
        if ($PSBoundParameters.ContainsKey('Verbosity')) {
            # OpenAI API docs say that the vetbosity is inside the text object.
            # But it seems incorrect. API returns an error "400 (Bad Request) Error: Unknown parameter: 'text'."
            # $PostBody.text = @{verbosity = $Verbosity }
            $PostBody.verbosity = $Verbosity
        }
        if ($PSBoundParameters.ContainsKey('MetaData')) {
            $PostBody.metadata = $MetaData
        }
        if ($PSBoundParameters.ContainsKey('StopSequence')) {
            $PostBody.stop = $StopSequence
        }
        if ($PSBoundParameters.ContainsKey('MaxTokens')) {
            $PostBody.max_tokens = $MaxTokens
        }
        if ($PSBoundParameters.ContainsKey('MaxCompletionTokens')) {
            $PostBody.max_completion_tokens = $MaxCompletionTokens
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
        if ($PSBoundParameters.ContainsKey('ResponseFormat')) {
            if ($ResponseFormat -is [type]) {
                # Structured Outputs
                $typeSchema = ConvertTo-JsonSchema $ResponseFormat
                $PostBody.response_format = @{
                    'type'        = 'json_schema'
                    'json_schema' = @{
                        'name'   = $ResponseFormat.Name
                        'strict' = $true
                        'schema' = $typeSchema
                    }
                }
            }
            elseif ($ResponseFormat -eq 'raw_response') {
                # Nothing to do
            }
            else {
                $PostBody.response_format = @{'type' = $ResponseFormat }
                if ($ResponseFormat -eq 'json_schema') {
                    if (-not $JsonSchema) {
                        Write-Error -Exception ([System.ArgumentException]::new('JsonSchema must be specified.'))
                    }
                    else {
                        $PostBody.response_format.json_schema = ConvertFrom-Json $JsonSchema
                    }
                }
            }
        }
        if ($PSBoundParameters.ContainsKey('Seed')) {
            $PostBody.seed = $Seed
        }
        if ($PSBoundParameters.ContainsKey('ServiceTier')) {
            $PostBody.service_tier = $ServiceTier
        }
        if ($PSBoundParameters.ContainsKey('PromptCacheKey')) {
            $PostBody.prompt_cache_key = $PromptCacheKey
        }
        if ($PSBoundParameters.ContainsKey('PromptCacheRetention')) {
            $PostBody.prompt_cache_retention = $PromptCacheRetention
        }
        if ($PSBoundParameters.ContainsKey('SafetyIdentifier')) {
            $PostBody.safety_identifier = $SafetyIdentifier
        }
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        if ($Stream) {
            $PostBody.stream = [bool]$Stream
            $PostBody.Remove('n')
        }

        # Web Search
        $webSearchOptions = @{}

        if ($PSBoundParameters.ContainsKey('WebSearchContextSize')) {
            $webSearchOptions.search_context_size = $WebSearchContextSize
        }

        $approximateLocation = @{}

        if ($PSBoundParameters.ContainsKey('WebSearchUserLocationCity')) {
            $approximateLocation.city = $WebSearchUserLocationCity
        }
        if ($PSBoundParameters.ContainsKey('WebSearchUserLocationCountry')) {
            $approximateLocation.country = $WebSearchUserLocationCountry
        }
        if ($PSBoundParameters.ContainsKey('WebSearchUserLocationRegion')) {
            $approximateLocation.region = $WebSearchUserLocationRegion
        }
        if ($PSBoundParameters.ContainsKey('WebSearchUserLocationTimeZone')) {
            $approximateLocation.timezone = $WebSearchUserLocationTimeZone
        }

        if ($approximateLocation.Keys.Count -gt 0) {
            $webSearchOptions.user_location = @{
                type        = $WebSearchUserLocationType
                approximate = $approximateLocation
            }
        }

        if ($webSearchOptions.Keys.Count -gt 0) {
            $PostBody.web_search_options = $webSearchOptions
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

                # refusal (only on assistant messages)
                if ($msg.refusal -and $msg.role -eq 'assistant') {
                    $tm.content = @(
                        @{
                            type    = 'refusal'
                            refusal = $msg.refusal
                        }
                    )
                }
                # text content
                elseif ($msg.content) {
                    $tm.content = $msg.content
                }

                # audio
                if ($msg.audio.id) {
                    $tm.audio = @{id = $msg.audio.id }
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
        # Specifies developer messages (only if specified)
        foreach ($dp in $DeveloperMessage) {
            if (-not [string]::IsNullOrWhiteSpace($dp)) {
                $Messages.Add([ordered]@{
                        role    = 'developer'
                        content = $dp.Trim()
                    })
            }
        }
        #region Add user messages
        $um = [ordered]@{
            role    = 'user'
            content = @()
        }

        # Text message
        if (-not [string]::IsNullOrWhiteSpace($Message)) {
            $um.content += @{type = 'text'; text = $Message.Trim() }
        }

        # Audio input
        if ($PSBoundParameters.ContainsKey('InputAudio')) {
            $auc = $null
            if (-not (Test-Path -LiteralPath $InputAudio -PathType Leaf)) {
                Write-Error -Exception ([System.IO.FileNotFoundException]::new("Could not find file '$InputAudio'", $InputAudio))
            }
            else {
                $audioItem = Get-Item -LiteralPath $InputAudio
                if ($InputAudioFormat) {
                    $audioformat = $InputAudioFormat
                }
                else {
                    $audioformat = $audioItem.Extension.ToLower().TrimStart([char]'.')
                }
                $auc = @{
                    type        = 'input_audio'
                    input_audio = @{
                        data   = ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($audioItem.FullName)))
                        format = $audioformat
                    }
                }
            }
            if ($null -ne $auc) {
                $um.content += $auc
            }
        }

        # Vision input
        if ($PSBoundParameters.ContainsKey('Images')) {
            foreach ($image in $Images) {
                if ([string]::IsNullOrWhiteSpace($image)) { continue }
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

        # By historical reasons,
        # when the user message has only one text message,
        # modify the message object to be a classical string format.
        if ($um.content.Count -eq 1 -and $um.content[0].type -eq 'text') {
            $um.content = $um.content[0].text
        }

        if ($um.content.Count -ge 1) {
            $Messages.Add($um)
        }
        #endregion

        # Error if message is empty.
        if ($Messages.Count -eq 0) {
            Write-Error 'No message is specified. You must specify one or more messages.'
            return
        }

        $PostBody.messages = $Messages.ToArray()
        #endregion

        # As Batch
        if ($AsBatch) {
            if ([string]::IsNullOrEmpty($CustomBatchId)) {
                $CustomBatchId = 'request-{0:x4}' -f (Get-Random -Maximum 65535)
            }
            $batchInputObject = [pscustomobject]@{
                'custom_id' = $CustomBatchId
                'method'    = 'POST'
                'url'       = $OpenAIParameter.BatchEndpoint
                'body'      = [pscustomobject]$PostBody
            }
            $batchInputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Batch.Input')
            return $batchInputObject
        }

        $splat = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }

        #region Send API Request (Stream)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequestSSE @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object {
                    if ($ResponseFormat -eq 'raw_response') {
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
                    $ResponseFormat -eq 'raw_response' -or ($null -ne $_.choices -and ($_.choices[0].delta.content -is [string]))
                } | ForEach-Object -Process {
                    if ($ResponseFormat -eq 'raw_response') {
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
            $Response = Invoke-OpenAIAPIRequest @splat

            # error check
            if ($null -eq $Response) {
                return
            }
            # Parse response object
            if ($ResponseFormat -eq 'raw_response') {
                Write-Output $Response
                return
            }
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
            $msg = @($Response.choices.message)[0]
            $rcm = [ordered]@{
                role    = $msg.role
                content = $msg.content
            }
            if ($msg.refusal) {
                $rcm.Add('refusal', $msg.refusal)
            }
            if ($msg.audio) {
                $rcm.Add('audio', (@{id = $msg.audio.id }))
            }
            if ($msg.tool_calls) {
                $rcm.Add('tool_calls', $msg.tool_calls)
            }
            $Messages.Add($rcm)
        }
        #endregion

        #region Function call
        if ($null -ne $Response.choices -and $Response.choices[0].finish_reason -eq 'tool_calls') {
            $ToolCallResults = @()
            $fCalls = @($Response.choices[0].message.tool_calls)

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
                $ToolCallResults += @{
                    role         = 'tool'
                    content      = $(if ($fCommandResult -is [string]) { $fCommandResult }else { (ConvertTo-Json $fCommandResult) })
                    tool_call_id = $fCall.id
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
                $null = $SecondRequestParam.Remove('DeveloperMessage')
                $Messages.AddRange($ToolCallResults)
                $SecondRequestParam.History = $Messages.ToArray()
                Request-ChatCompletion @SecondRequestParam
                return
            }
        }
        #endregion

        #region Output

        # Save audio to file
        if ($PSBoundParameters.ContainsKey('AudioOutFile')) {
            foreach ($choice in $Response.choices) {
                if ($null -eq $choice.message.audio.data) {
                    continue
                }

                try {
                    $audioData = [System.Convert]::FromBase64String($choice.message.audio.data)
                }
                catch {
                    Write-Error -Exception $_.Exception
                }

                Write-ByteContent -OutFile $AudioOutFile -Bytes $audioData

                break
            }
        }

        ParseChatCompletionObject $Response -Messages $Messages -OutputType $ResponseFormat
        #endregion
    }

    end {

    }
}
