function Start-ThreadRun {
    [CmdletBinding(DefaultParameterSetName = 'ThreadAndRun')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Run')]
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Run_Stream')]
        [Alias('thread_id')]
        [Alias('Thread')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('thread_', [StringComparison]::Ordinal)) -or `
                ($_.id -is [string] -and $_.id.StartsWith('thread_', [StringComparison]::Ordinal)) -or `
                ($_.thread_id -is [string] -and $_.thread_id.StartsWith('thread_', [StringComparison]::Ordinal))
            })]
        [Object]$InputObject,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('assistant_id')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('asst_', [StringComparison]::Ordinal)) -or `
                ($_.id -is [string] -and $_.id.StartsWith('asst_', [StringComparison]::Ordinal)) -or `
                ($_.assistant_id -is [string] -and $_.assistant_id.StartsWith('asst_', [StringComparison]::Ordinal))
            })]
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
        [ValidateLength(0, 32768)]
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
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ThreadAndRun')]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'ThreadAndRun_Stream')]
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
        [Alias('file_ids')]
        [ValidateRange(0, 10)]
        [string[]]$FileId,
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
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [Alias('tool_choice')]
        [Completions('none', 'auto', 'code_interpreter', 'retrieval', 'function')]
        [string][LowerCaseTransformation()]$ToolChoice,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ToolChoiceFunctionName,

        [Parameter()]
        [switch]$UseCodeInterpreter,

        [Parameter()]
        [switch]$UseRetrieval,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter(Mandatory = $true, ParameterSetName = 'Run_Stream')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ThreadAndRun_Stream')]
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

        [Parameter(DontShow = $true)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow = $true)]
        [string]$ApiVersion,

        [Parameter(DontShow = $true)]
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
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        if ($PSCmdlet.ParameterSetName.StartsWith('ThreadAndRun', [System.StringComparison]::Ordinal)) {
            $EndpointName = 'ThreadAndRun'
        }
        else {
            $EndpointName = 'Runs'
        }

        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName $EndpointName -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName $EndpointName -ApiBase $ApiBase
        }

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
        $AssistantId = ''
        if ($Assistant -is [string]) {
            $AssistantId = $Assistant
        }
        elseif ($Assistant.id -is [string] -and $Assistant.id.StartsWith('asst_', [StringComparison]::Ordinal)) {
            $AssistantId = $Assistant.id
        }
        elseif ($Assistant.assistant_id -is [string] -and $Assistant.assistant_id.StartsWith('asst_', [StringComparison]::Ordinal)) {
            $AssistantId = $Assistant.assistant_id
        }

        if (-not $AssistantId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Assistant ID.'))
            return
        }

        if ($UseCodeInterpreter) {
            $Tools += @{'type' = 'code_interpreter' }
        }
        if ($UseRetrieval) {
            $Tools += @{'type' = 'retrieval' }
        }

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
        if (($Tools.Count -gt 0) -or $PSBoundParameters.ContainsKey('Tools')) {
            $PostBody.tools = $Tools
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            if ($ToolChoice -in ('none', 'auto')) {
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
            if ($PSBoundParameters.ContainsKey('FileId')) {
                $PostBody.thread.messages[0].file_ids = $FileId
            }
        }
        if ($Stream) {
            $PostBody.stream = $true
        }
        #endregion

        #region Send API Request (Streaming)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequest `
                -Method $OpenAIParameter.Method `
                -Uri $QueryUri `
                -ContentType $OpenAIParameter.ContentType `
                -TimeoutSec $TimeoutSec `
                -MaxRetryCount $MaxRetryCount `
                -ApiKey $SecureToken `
                -AuthType $AuthType `
                -Organization $Organization `
                -Headers (@{'OpenAI-Beta' = 'assistants=v1' }) `
                -Body $PostBody `
                -Stream $Stream `
                -AdditionalQuery $AdditionalQuery -AdditionalHeaders $AdditionalHeaders -AdditionalBody $AdditionalBody |`
                Where-Object {
                -not [string]::IsNullOrEmpty($_)
            } | ForEach-Object {
                if ($Format -eq 'raw_response') {
                    $_
                }
                elseif ($_.Contains('"object":"thread.message.delta"', [StringComparison]::OrdinalIgnoreCase)) {
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
        $Response = Invoke-OpenAIAPIRequest `
            -Method $OpenAIParameter.Method `
            -Uri $QueryUri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -AuthType $AuthType `
            -Organization $Organization `
            -Headers (@{'OpenAI-Beta' = 'assistants=v1' }) `
            -Body $PostBody `
            -AdditionalQuery $AdditionalQuery -AdditionalHeaders $AdditionalHeaders -AdditionalBody $AdditionalBody

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
