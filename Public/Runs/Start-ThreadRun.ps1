function Start-ThreadRun {
    [CmdletBinding(DefaultParameterSetName = 'ThreadAndRun')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Run')]
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'Run_Stream')]
        [Alias('thread_id')]
        [Alias('Thread')]
        [ValidateScript({ [bool](Get-ThreadIdFromInputObject $_) })]
        [Object]$InputObject,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('assistant_id')]
        [ValidateScript({ [bool](Get-AssistantIdFromInputObject $_) })]
        [Object]$Assistant,

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
        [ValidateLength(0, 256000)]
        [string]$Instructions,

        [Parameter(ParameterSetName = 'Run')]
        [Parameter(ParameterSetName = 'Run_Stream')]
        [Alias('additional_instructions')]
        [string]$AdditionalInstructions,

        [Parameter(ParameterSetName = 'Run')]
        [Parameter(ParameterSetName = 'Run_Stream')]
        [Alias('additional_messages')]
        [object[]]$AdditionalMessages,

        #region Parameters for Thread and Run
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ThreadAndRun')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ThreadAndRun_Stream')]
        [Alias('Text')]
        [Alias('Content')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [Parameter(ParameterSetName = 'ThreadAndRun_Stream')]
        [Completions('user', 'assistant')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [Parameter(ParameterSetName = 'ThreadAndRun_Stream')]
        [ValidateCount(0, 20)]
        [string[]]$FileIdsForCodeInterpreter,

        [Parameter(ParameterSetName = 'ThreadAndRun')]
        [Parameter(ParameterSetName = 'ThreadAndRun_Stream')]
        [ValidateScript({ [bool](Get-VectorStoreIdFromInputObject $_) })]
        [ValidateCount(1, 1)]
        [object[]]$VectorStoresForFileSearch,
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
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter(Mandatory, ParameterSetName = 'Run_Stream')]
        [Parameter(Mandatory, ParameterSetName = 'ThreadAndRun_Stream')]
        [switch]$Stream,

        [Parameter()]
        [Alias('response_format')]
        [ValidateSet('default', 'auto', 'text', 'json_object', 'raw_response')]
        [string][LowerCaseTransformation()]$Format = 'default',

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
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey -ErrorAction Stop

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType -ErrorAction Stop

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        if ($PSCmdlet.ParameterSetName.StartsWith('ThreadAndRun', [System.StringComparison]::Ordinal)) {
            $EndpointName = 'ThreadAndRun'
        }
        else {
            $EndpointName = 'Runs'
        }

        # Get API context
        $OpenAIParameter = Get-OpenAIContext -EndpointName $EndpointName -ApiType $ApiType -AuthType $AuthType -ApiBase $ApiBase -ApiVersion $ApiVersion -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get thread_id
        if ($PSCmdlet.ParameterSetName.StartsWith('Run', [System.StringComparison]::Ordinal)) {
            [string][UrlEncodeTransformation()]$ThreadID = Get-ThreadIdFromInputObject $InputObject
            if (-not $ThreadID) {
                Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
                return
            }
            $QueryUri = ($OpenAIParameter.Uri.ToString() -f $ThreadID)
        }
        else {
            $QueryUri = $OpenAIParameter.Uri
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()

        # Get assistant_id
        $AssistantId = Get-AssistantIdFromInputObject $Assistant
        if (-not $AssistantId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Assistant ID.'))
            return
        }

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
        if ($PSBoundParameters.ContainsKey('VectorStoresForFileSearch')) {
            $vsids = @()
            foreach ($vs in $VectorStoresForFileSearch) {
                $vsids += Get-VectorStoreIdFromInputObject $vs
            }
            if ($vsids.Count -gt 0) {
                $ToolResources.file_search = @{'vector_store_ids' = $vsids }
            }
        }
        #endregion

        $PostBody.assistant_id = $AssistantId
        if ($PSBoundParameters.ContainsKey('Model')) {
            $PostBody.model = $Model
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $PostBody.instructions = $Instructions
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
        if ($PSBoundParameters.ContainsKey('Format') -and $Format -notin ('default', 'raw_response')) {
            if ($Format -eq 'auto') {
                $PostBody.response_format = 'auto'
            }
            else {
                $PostBody.response_format = @{'type' = $Format }
            }
        }

        # Additional messages
        $Messages = [System.Collections.Generic.List[object]]::new()
        foreach ($msg in $AdditionalMessages) {
            if ($msg.role) {
                $tm = [ordered]@{
                    role    = [string]$msg.role
                    content = $msg.content
                }
                # file_ids is optional
                if ($msg.file_ids.Count -gt 0) {
                    $tm.file_ids = @($msg.file_ids)
                }
                # metadata is optional
                if ($msg.metadata -is [System.Collections.IDictionary]) {
                    $tm.metadata = $msg.metadata
                }
            }
            else {
                $tm = [ordered]@{
                    role    = 'user'
                    content = [string]$msg
                }
            }
            $Messages.Add($tm)
        }
        if ($Messages.Count -gt 0) {
            $PostBody.additional_messages = $Messages
        }

        if ($PSCmdlet.ParameterSetName.StartsWith('ThreadAndRun', [System.StringComparison]::Ordinal)) {
            $PostBody.thread = @{}
            $PostBody.thread.messages = @(@{
                    role    = $Role
                    content = $Message
                })
        }
        if ($Stream) {
            $PostBody.stream = $true
        }
        #endregion

        #region Send API Request (Streaming)
        if ($Stream) {
            # Stream output
            $params = @{
                Method            = $OpenAIParameter.Method
                Uri               = $QueryUri
                ContentType       = $OpenAIParameter.ContentType
                TimeoutSec        = $TimeoutSec
                MaxRetryCount     = $MaxRetryCount
                ApiKey            = $SecureToken
                AuthType          = $OpenAIParameter.AuthType
                Organization      = $Organization
                Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
                Body              = $PostBody
                Stream            = $Stream
                AdditionalQuery   = $AdditionalQuery
                AdditionalHeaders = $AdditionalHeaders
                AdditionalBody    = $AdditionalBody
            }
            Invoke-OpenAIAPIRequest @params |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object {
                    if ($Format -eq 'raw_response') {
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
                    $Format -eq 'raw_response' -or ($null -ne $_.text)
                } | ForEach-Object -Process {
                    if ($Format -eq 'raw_response') {
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

        #region Send API Request
        $params = @{
            Method            = $OpenAIParameter.Method
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $TimeoutSec
            MaxRetryCount     = $MaxRetryCount
            ApiKey            = $SecureToken
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIAPIRequest @params

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        if ($Format -eq 'raw_response') {
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
        ParseThreadRunObject $Response -CommonParams $CommonParams -Primitive
        #endregion
    }

    end {

    }
}
