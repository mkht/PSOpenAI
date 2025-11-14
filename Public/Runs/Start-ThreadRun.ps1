function Start-ThreadRun {
    [CmdletBinding(DefaultParameterSetName = 'ThreadAndRun')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Run_ThreadId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('InputObject')]  # for backward compatibility
        [Alias('Thread')]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Assistant')]
        [Alias('assistant_id')]
        [string]$AssistantId,

        [Parameter()]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-4o',
            'gpt-4o-mini',
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
            'o1',
            'o3-mini'
        )]
        [string]$Model = 'gpt-3.5-turbo',

        [Parameter()]
        [ValidateLength(0, 256000)]
        [string]$Instructions,

        [Parameter()]
        [Alias('reasoning_effort')]
        [Completions('none', 'minimal', 'low', 'medium', 'high')]
        [string]$ReasoningEffort,

        [Parameter(ParameterSetName = 'Run_ThreadId')]
        [Alias('additional_instructions')]
        [string]$AdditionalInstructions,

        [Parameter(ParameterSetName = 'Run_ThreadId')]
        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [Alias('additional_messages')]
        [object[]]$AdditionalMessages,

        [Parameter(ParameterSetName = 'Run_ThreadId')]
        [Completions('step_details.tool_calls[*].file_search.results[*].content')]
        [string[]]$Include,

        #region Parameters for Thread and Run
        [Parameter(Mandatory, ParameterSetName = 'ThreadAndRun')]
        [Alias('Text')]
        [Alias('Content')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [ValidateNotNullOrEmpty()]
        [object[]]$Images,

        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [ValidateSet('auto', 'low', 'high')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',

        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [Completions('user', 'assistant')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [ValidateCount(0, 20)]
        [string[]]$FileIdsForCodeInterpreter,

        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [ValidateCount(1, 1)]
        [string[]]$VectorStoresForFileSearch,
        #endregion

        [Parameter()]
        [ValidateRange(256, 2147483647)]
        [Alias('max_prompt_tokens')]
        [int]$MaxPromptTokens,

        [Parameter()]
        [ValidateRange(256, 2147483647)]
        [Alias('max_completion_tokens')]
        [int]$MaxCompletionTokens,

        [Parameter()]
        [Alias('truncation_strategy')]
        [ValidateSet('auto', 'last_messages')]
        [string][LowerCaseTransformation()]$TruncationStrategyType = 'auto',

        [Parameter()]
        [Alias('last_messages')]
        [ValidateRange(1, 2147483647)]
        [int]$TruncationStrategyLastMessages = 1,

        [Parameter()]
        [Alias('tool_choice')]
        [Completions('none', 'auto', 'required', 'code_interpreter', 'file_search', 'function')]
        [string][LowerCaseTransformation()]$ToolChoice,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ToolChoiceFunctionName,

        [Parameter()]
        [switch]$UseCodeInterpreter,

        [Parameter()]
        [switch]$UseFileSearch,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Functions,

        [Parameter()]
        [Alias('parallel_tool_calls')]
        [switch]$ParallelToolCalls,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [switch]$Stream,

        [Parameter()]
        [Alias('response_format')]
        [Alias('Format')]  # for backward compatibility
        [ValidateSet('default', 'auto', 'text', 'json_object', 'json_schema', 'raw_response')]
        [object]$ResponseFormat = 'default',

        [Parameter()]
        [string]$JsonSchema,

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

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
    }

    process {
        # Get API endpoint
        if ($PSCmdlet.ParameterSetName -ceq 'ThreadAndRun') {
            $EndpointName = 'ThreadAndRun'
        }
        else {
            $EndpointName = 'Runs'
        }
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName $EndpointName -Parameters $PSBoundParameters -ErrorAction Stop

        #region Construct query url
        if ($PSCmdlet.ParameterSetName -like 'Run_*') {
            $QueryUri = ($OpenAIParameter.Uri.ToString() -f $ThreadID)
            $UriBuilder = [System.UriBuilder]::new($QueryUri)
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            if ($PSBoundParameters.ContainsKey('Include')) {
                foreach ($IncludeItem in $Include) {
                    $QueryParam.Add('include[]', $IncludeItem)
                }
            }
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }
        else {
            $QueryUri = $OpenAIParameter.Uri
        }
        #endregion

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()

        #region Construct tools object
        $Tools = @()
        if ($UseCodeInterpreter) {
            $Tools += @{'type' = 'code_interpreter' }
        }
        if ($UseFileSearch) {
            $Tools += @{'type' = 'file_search' }
        }
        if ($Functions.Count -gt 0) {
            foreach ($f in $Functions) {
                if (-not $Functions.name) {
                    Write-Error -Exception ([System.ArgumentException]::new('You should specify function name.'))
                    continue
                }
                $Tools += @{
                    'type'     = 'function'
                    'function' = @{
                        'name'        = $f.Name
                        'description' = $f.description
                        'parameters'  = $f.parameters
                    }
                }
            }
        }
        #endregion

        #region Construct tools resources
        $ToolResources = @{}
        if ($FileIdsForCodeInterpreter.Count -gt 0) {
            $ToolResources.code_interpreter = @{'file_ids' = $FileIdsForCodeInterpreter }
        }
        if ($FileIdsForFileSearch.Count -gt 0) {
            $ToolResources.file_search = @{'vector_stores' = @(@{'file_ids' = $FileIdsForFileSearch }) }
        }
        if ($VectorStoresForFileSearch.Count -gt 0) {
            $ToolResources.file_search = @{'vector_store_ids' = $VectorStoresForFileSearch }
        }
        #endregion

        $PostBody.assistant_id = $AssistantId
        if ($PSBoundParameters.ContainsKey('Model')) {
            $PostBody.model = $Model
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $PostBody.instructions = $Instructions
        }
        if ($PSBoundParameters.ContainsKey('ReasoningEffort')) {
            $PostBody.reasoning_effort = $ReasoningEffort
        }
        if ($PSBoundParameters.ContainsKey('AdditionalInstructions')) {
            $PostBody.additional_instructions = $AdditionalInstructions
        }
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            $PostBody.metadata = $Metadata
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $PostBody.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('TopP')) {
            $PostBody.top_p = $TopP
        }
        if ($PSBoundParameters.ContainsKey('MaxPromptTokens')) {
            $PostBody.max_prompt_tokens = $MaxPromptTokens
        }
        if ($PSBoundParameters.ContainsKey('MaxCompletionTokens')) {
            $PostBody.max_completion_tokens = $MaxCompletionTokens
        }
        if ($PSBoundParameters.ContainsKey('TruncationStrategyType')) {
            $PostBody.truncation_strategy = @{ type = $TruncationStrategyType; last_messages = $null }
        }
        if ($PSBoundParameters.ContainsKey('TruncationStrategyLastMessages')) {
            $PostBody.truncation_strategy = @{ type = $TruncationStrategyType; last_messages = $TruncationStrategyLastMessages }
        }
        if ($Tools.Count -gt 0) {
            $PostBody.tools = $Tools
        }
        if ($ToolResources.Count -gt 0) {
            $PostBody.tool_resources = $ToolResources
        }
        if ($PSBoundParameters.ContainsKey('ParallelToolCalls')) {
            $PostBody.parallel_tool_calls = [bool]$ParallelToolCalls
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            if ($ToolChoice -in ('none', 'auto', 'required')) {
                $PostBody.tool_choice = $ToolChoice
            }
            elseif ($ToolChoice -eq 'function') {
                if ([string]::IsNullOrWhiteSpace($ToolChoiceFunctionName)) {
                    Write-Error -Exception ([System.ArgumentException]::new('When you set to TooChoice as "function", the ToolChoiceFunctionName must be specified.'))
                    return
                }
                else {
                    $PostBody.tool_choice = @{type = $ToolChoice; function = @{name = $ToolChoiceFunctionName } }
                }
            }
            else {
                $PostBody.tool_choice = @{type = $ToolChoice }
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
            elseif ($ResponseFormat -in ('default', 'raw_response')) {
                # Nothing to do
            }
            elseif ($ResponseFormat -eq 'auto') {
                $PostBody.response_format = 'auto'
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

        # Additional messages
        $Messages = [System.Collections.Generic.List[hashtable]]::new()
        foreach ($msg in $AdditionalMessages) {
            if ($msg.role) {
                $tm = @{
                    role    = [string]$msg.role
                    content = $msg.content
                }
                # attachments is optional
                if ($msg.attachments.Count -gt 0) {
                    $tm.attachments = @($msg.attachments)
                }
                # metadata is optional
                if ($msg.metadata -is [System.Collections.IDictionary]) {
                    $tm.metadata = $msg.metadata
                }
            }
            else {
                $tm = @{
                    role    = 'user'
                    content = [string]$msg
                }
            }
            $Messages.Add($tm)
        }

        if ($PSCmdlet.ParameterSetName -ceq 'ThreadAndRun') {
            if ($Images.Count -gt 0) {
                $ContentsList = [System.Collections.Generic.List[hashtable]]::new($Images.Count + 1)
                # Text Message
                $ContentsList.Add(
                    @{
                        type = 'text'
                        text = $Message
                    }
                )
                # Images
                foreach ($image in $Images) {
                    # File object
                    if ($image.psobject.TypeNames -contains 'PSOpenAI.File') {
                        $ContentsList.Add(
                            @{
                                type       = 'image_file'
                                image_file = @{
                                    file_id = $image.id
                                    detail  = $ImageDetail
                                }
                            }
                        )
                    }
                    elseif ($image -is [string]) {
                        $imageUri = [uri]$image
                        if ($imageUri.Scheme -in ('https', 'http')) {
                            # Image URL
                            $ContentsList.Add(
                                @{
                                    type      = 'image_url'
                                    image_url = @{
                                        url    = $imageUri.AbsoluteUri
                                        detail = $ImageDetail
                                    }
                                }
                            )
                        }
                        else {
                            # File-ID or something else
                            $ContentsList.Add(
                                @{
                                    type       = 'image_file'
                                    image_file = @{
                                        file_id = $image
                                        detail  = $ImageDetail
                                    }
                                }
                            )
                        }
                    }
                    else {
                        # Invalid
                        Write-Error -Message 'Invalid input. Please specify a valid URL or File ID.'
                        continue
                    }
                }

                $Messages.Add(@{
                        role    = $Role
                        content = $ContentsList.ToArray()
                    })
            }
            else {
                # Only a text message
                $Messages.Add(@{
                        role    = $Role
                        content = $Message
                    })
            }
            $PostBody.thread = @{}
            $PostBody.thread.messages = $Messages
        }
        elseif ($Messages.Count -gt 0) {
            $PostBody.additional_messages = $Messages
        }

        if ($Stream) {
            $PostBody.stream = $true
        }
        #endregion

        $splat = @{
            Method            = $OpenAIParameter.Method
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }

        #region Send API Request (Streaming)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequestSSE @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object {
                    if ($ResponseFormat -eq 'raw_response') {
                        $_
                    }
                    elseif ($_.Contains('"object":"thread.message.delta"')) {
                        try {
                            $deltaObj = $_ | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            Write-Error -Exception $_.Exception
                        }
                        @($deltaObj.delta.content.Where({ $_.type -eq 'text' }))[0]
                    }
                } | Where-Object {
                    $ResponseFormat -eq 'raw_response' -or ($null -ne $_.text)
                } | ForEach-Object -Process {
                    if ($ResponseFormat -eq 'raw_response') {
                        Write-Output $_
                    }
                    else {
                        # Writes content to both the Information stream(6>) and the Standard output stream(1>).
                        $InfoMsg = [System.Management.Automation.HostInformationMessage]::new()
                        $InfoMsg.Message = $_.text.value
                        $InfoMsg.NoNewLine = $true
                        Write-Information $InfoMsg
                        Write-Output $InfoMsg.Message
                    }
                }

            return
        }
        #endregion

        else {
            #region Send API Request
            $Response = Invoke-OpenAIAPIRequest @splat

            # error check
            if ($null -eq $Response) {
                return
            }
            #endregion

            if ($ResponseFormat -eq 'raw_response') {
                Write-Output $Response
                return
            }

            #region Parse response object
            try {
                $Response = $Response | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                Write-Error -Exception $_.Exception
            }
            #endregion

            #region Output
            Write-Verbose ('Start thread run with id "{0}". The current status is "{1}"' -f $Response.id, $Response.status)
            ParseThreadRunObject $Response
            #endregion
        }
    }

    end {

    }
}
