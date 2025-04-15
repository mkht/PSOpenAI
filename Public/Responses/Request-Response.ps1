function Request-Response {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('input')]
        [Alias('UserMessage')]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('user', 'system', 'developer', 'assistant')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter(ValueFromPipelineByPropertyName)]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-4o',
            'gpt-4o-mini',
            'gpt-3.5-turbo-16k',
            'gpt-4-turbo',
            'gpt-4.1',
            'gpt-4.1-mini',
            'gpt-4.1-nano',
            'o1',
            'o1-pro',
            'o3-mini',
            'computer-use-preview'
        )]
        [string]$Model = 'gpt-4o-mini',

        #region System messages
        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [string[]]$SystemMessage,

        [Parameter()]
        [AllowEmptyString()]
        [string[]]$DeveloperMessage,

        [Parameter()]
        [string]$Instructions,
        #endregion System messages

        #region Image input
        [Parameter()]
        [string[]]$Images,

        [Parameter()]
        [ValidateSet('auto', 'low', 'high')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',
        #endregion Image input

        #region File input
        [Parameter()]
        [string[]]$Files,
        #endregion Image input

        #region Tools
        [Parameter()]
        [Alias('tool_choice')]
        [Completions('none', 'auto', 'required')]
        [string]$ToolChoice,

        [Parameter()]
        [Alias('parallel_tool_calls')]
        [bool]$ParallelToolCalls,

        #region Function calling
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Functions,

        #### Not yet implemented ####
        # [Parameter()]
        # [ValidateSet('None', 'Auto', 'Confirm')]
        # [string]$InvokeFunction = 'None',
        #endregion Function calling

        # Built-in tools
        #region File Search
        [Parameter()]
        [switch]$UseFileSearch,

        [Parameter(DontShow)]
        [string]$FileSearchType = 'file_search', # Currently, only 'file_search' is acceptable.

        [Parameter()]
        [string[]]$FileSearchVectorStoreIds,

        [Parameter()]
        [ValidateRange(1, 50)]
        [int]$FileSearchMaxNumberOfResults,

        #### Not yet implemented ####
        # [Parameter()]
        # [string]$FileSearchFilters,

        [Parameter()]
        [Completions('auto')]
        [string]$FileSearchRanker = 'auto',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$FileSearchScoreThreshold = 0.0,
        #endregion File Search

        #region Web Search
        [Parameter()]
        [switch]$UseWebSearch,

        [Parameter()]
        [Completions('web_search_preview')]
        [string]$WebSearchType = 'web_search_preview',

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

        #region Computer use
        [Parameter()]
        [switch]$UseComputerUse,

        [Parameter(DontShow)]
        [string]$ComputerUseType = 'computer_use_preview', # Currently, only 'computer_use_preview' is acceptable.

        [Parameter()]
        [Completions('browser', 'windows', 'mac', 'ubuntu')]
        [string]$ComputerUseEnvironment,

        [Parameter()]
        [int]$ComputerUseDisplayHeight,

        [Parameter()]
        [int]$ComputerUseDisplayWidth,
        #endregion Computer use
        #endregion Tools

        [Parameter()]
        [Alias('previous_response_id')]
        [string]$PreviousResponseId,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$Include,

        [Parameter()]
        [Completions('auto', 'disabled')]
        [string]$Truncation,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [bool]$Store,

        #region Stream
        [Parameter()]
        [switch]$Stream = $false,

        [Parameter()]
        [ValidateSet('text', 'object')]
        [string]$StreamOutputType = 'text',
        #endregion Stream

        #region Reasoning
        [Parameter()]
        [Completions('low', 'medium', 'high')]
        [string]$ReasoningEffort = 'medium',

        [Parameter()]
        [Completions('concise', 'detailed')]
        [string]$ReasoningGenerateSummary,
        #endregion Reasoning

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [Alias('max_output_tokens')]
        [int]$MaxOutputTokens,

        [Parameter()]
        [Completions('text', 'json_schema', 'json_object')]
        [object]$OutputType = 'text',

        #region Structured Outputs
        [Parameter()]
        [string]$JsonSchema,

        [Parameter()]
        [string]$JsonSchemaName,

        [Parameter()]
        [string]$JsonSchemaDescription,

        [Parameter()]
        [bool]$JsonSchemaStrict,
        #endregion Structured Outputs

        [Parameter()]
        [string]$User,

        [Parameter()]
        [switch]$AsBatch,

        [Parameter()]
        [string]$CustomBatchId,

        [Parameter()]
        [switch]$OutputRawResponse,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Responses' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop
    }

    process {
        #region Construct parameters for API request
        $Response = $null
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model

        if ($PreviousResponseId) {
            $PostBody.previous_response_id = $PreviousResponseId
        }

        if ($PSBoundParameters.ContainsKey('Include')) {
            $PostBody.include = @($Include)
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $PostBody.instructions = $Instructions
        }
        if ($PSBoundParameters.ContainsKey('MaxOutputTokens')) {
            $PostBody.max_output_tokens = $MaxOutputTokens
        }
        if ($PSBoundParameters.ContainsKey('Truncation')) {
            $PostBody.truncation = $Truncation
        }
        if ($PSBoundParameters.ContainsKey('MetaData')) {
            $PostBody.metadata = $MetaData
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            if ($ToolChoice -in ('none', 'auto', 'required')) {
                # Do nothing
            }
            elseif ($ToolChoice -in ('file_search', 'web_search_preview', 'computer_use_preview')) {
                # built-in tools
                $ToolChoice = @{type = $ToolChoice }
            }
            else {
                # custom functions
                $ToolChoice = @{type = 'function'; name = $ToolChoice }
            }
            $PostBody.tool_choice = $ToolChoice
        }
        if ($PSBoundParameters.ContainsKey('ParallelToolCalls')) {
            $PostBody.parallel_tool_calls = $ParallelToolCalls
        }
        if ($PSBoundParameters.ContainsKey('TopP')) {
            $PostBody.top_p = $TopP
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $PostBody.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('Store')) {
            $PostBody.store = $Store
        }
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        if ($Stream) {
            $PostBody.stream = [bool]$Stream
        }

        # Reasoning
        $ReasoningOptions = @{}
        if ($PSBoundParameters.ContainsKey('ReasoningEffort')) {
            $ReasoningOptions.effort = $ReasoningEffort
        }
        if ($PSBoundParameters.ContainsKey('ReasoningGenerateSummary')) {
            $ReasoningOptions.generate_summary = $ReasoningGenerateSummary
        }
        if ($ReasoningOptions.Keys.Count -gt 0) {
            $PostBody.reasoning = $ReasoningOptions
        }

        # Text Output options
        $TextOutputOptions = @{}
        if ($PSBoundParameters.ContainsKey('OutputType')) {
            if ($OutputType -is [type]) {
                # Structured Outputs
                $typeSchema = ConvertTo-JsonSchema $OutputType
                $TextOutputOptions.format = @{
                    'type'   = 'json_schema'
                    'name'   = $OutputType.Name
                    'strict' = $true
                    'schema' = $typeSchema
                }
            }
            elseif ($OutputType -eq 'text') {
                $TextOutputOptions.format = @{'type' = 'text' }
            }
            elseif ($OutputType -eq 'json_object') {
                $TextOutputOptions.format = @{'type' = 'json_object' }
            }
            elseif ($OutputType -eq 'json_schema') {
                # Structured Outputs
                $PostBody.response_format = @{'type' = $Format }
                if ($Format -eq 'json_schema') {
                    if (-not $JsonSchema) {
                        Write-Error -Exception ([System.ArgumentException]::new('JsonSchema must be specified.'))
                    }
                    else {
                        $TextOutputOptions.format = @{
                            'type'   = 'json_schema'
                            'schema' = (ConvertFrom-Json $JsonSchema)
                        }
                        if ($PSBoundParameters.ContainsKey('JsonSchemaName')) {
                            $TextOutputOptions.format.name = $JsonSchemaName
                        }
                        if ($PSBoundParameters.ContainsKey('JsonSchemaDescription')) {
                            $TextOutputOptions.format.description = $JsonSchemaDescription
                        }
                        if ($PSBoundParameters.ContainsKey('JsonSchemaStrict')) {
                            $TextOutputOptions.format.strict = $JsonSchemaStrict
                        }
                    }
                }
            }
        }
        if ($TextOutputOptions.Keys.Count -gt 0) {
            $PostBody.text = $TextOutputOptions
        }

        #region Tools
        $Tools = @()
        if ($PSBoundParameters.ContainsKey('Functions')) {
            $Tools += $Functions
        }

        # File Search
        if ($UseFileSearch) {
            if ($FileSearchVectorStoreIds.Count -eq 0) {
                Write-Error 'VectorStore Ids must be specified.'
            }
            else {
                $RankingOptions = @{}
                $FileSearchTool = @{
                    type             = $FileSearchType
                    vector_store_ids = $FileSearchVectorStoreIds
                }

                if ($PSBoundParameters.ContainsKey('FileSearchMaxNumberOfResults')) {
                    $FileSearchTool.max_num_results = $FileSearchMaxNumberOfResults
                }
                if ($PSBoundParameters.ContainsKey('FileSearchFilters')) {
                    $FileSearchTool.filters = $FileSearchFilters
                }
                if ($PSBoundParameters.ContainsKey('FileSearchRanker')) {
                    $RankingOptions.ranker = $FileSearchRanker
                }
                if ($PSBoundParameters.ContainsKey('FileSearchScoreThreshold')) {
                    $RankingOptions.score_threshold = $FileSearchScoreThreshold
                }

                if ($RankingOptions.Keys.Count -gt 0) {
                    $FileSearchTool.ranking_options = $RankingOptions
                }
                $Tools += $FileSearchTool
            }
        }

        # Web Search
        if ($UseWebSearch) {
            $UserLocation = @{}
            $WebSearchTool = @{
                type = $WebSearchType
            }

            if ($PSBoundParameters.ContainsKey('WebSearchContextSize')) {
                $WebSearchTool.search_context_size = $WebSearchContextSize
            }
            if ($PSBoundParameters.ContainsKey('WebSearchUserLocationCity')) {
                $UserLocation.city = $WebSearchUserLocationCity
            }
            if ($PSBoundParameters.ContainsKey('WebSearchUserLocationCountry')) {
                $UserLocation.country = $WebSearchUserLocationCountry
            }
            if ($PSBoundParameters.ContainsKey('WebSearchUserLocationRegion')) {
                $UserLocation.region = $WebSearchUserLocationRegion
            }
            if ($PSBoundParameters.ContainsKey('WebSearchUserLocationTimeZone')) {
                $UserLocation.timezone = $WebSearchUserLocationTimeZone
            }

            if ($UserLocation.Keys.Count -gt 0) {
                $UserLocation.type = $WebSearchUserLocationType
                $WebSearchTool.user_location = $UserLocation
            }

            $Tools += $WebSearchTool
        }

        # Computer Use
        if ($UseComputerUse) {
            # Computer Use should be used with 'truncation=auto'
            $PostBody.truncation = 'auto'

            $ComputerUseTool = @{
                type = $ComputerUseType
            }
            if ($PSBoundParameters.ContainsKey('ComputerUseEnvironment')) {
                $ComputerUseTool.environment = $ComputerUseEnvironment
            }
            else {
                Write-Error 'ComputerUseEnvironment must be specified.'
            }
            if ($PSBoundParameters.ContainsKey('ComputerUseDisplayHeight')) {
                $ComputerUseTool.display_height = $ComputerUseDisplayHeight
            }
            else {
                Write-Error 'ComputerUseDisplayHeight must be specified.'
            }
            if ($PSBoundParameters.ContainsKey('ComputerUseDisplayWidth')) {
                $ComputerUseTool.display_width = $ComputerUseDisplayWidth
            }
            else {
                Write-Error 'ComputerUseDisplayWidth must be specified.'
            }
            $Tools += $ComputerUseTool
        }

        if ($Tools.Count -gt 0) {
            $PostBody.tools = $Tools
        }
        #endregion Tools

        #region Construct messages
        $Messages = [System.Collections.Generic.List[object]]::new()
        # Append past conversations
        foreach ($pastmsg in $History) {
            $Messages.Add($pastmsg)
        }

        # Specifies system messages (only if specified)
        $sysmsg = [pscustomobject]@{
            role    = 'system'
            content = @()
        }
        foreach ($_msg in $SystemMessage) {
            if (-not [string]::IsNullOrWhiteSpace($_msg)) {
                $sysmsg.content += [pscustomobject]@{type = 'input_text'; text = $_msg }
            }
        }
        if ($sysmsg.content.Count -ge 1) {
            $Messages.Add($sysmsg)
        }

        # Specifies developer messages (only if specified)
        $devmsg = [pscustomobject]@{
            role    = 'developer'
            content = @()
        }
        foreach ($_msg in $DeveloperMessage) {
            if (-not [string]::IsNullOrWhiteSpace($_msg)) {
                $devmsg.content += [pscustomobject]@{type = 'input_text'; text = $_msg }
            }
        }
        if ($devmsg.content.Count -ge 1) {
            $Messages.Add($devmsg)
        }

        #region Add user messages
        $usermsg = [pscustomobject]@{
            role    = 'user'
            content = @()
        }

        # Text message
        if (-not [string]::IsNullOrWhiteSpace($Message)) {
            $usermsg.content += [pscustomobject]@{type = 'input_text'; text = $Message }
        }

        # File input
        if ($PSBoundParameters.ContainsKey('Files')) {
            foreach ($file in $Files) {
                if ([string]::IsNullOrWhiteSpace($file)) { continue }
                $fileContent = $null

                if (Test-Path -LiteralPath $file -PathType Leaf) {
                    # local file
                    $fileItem = Get-Item -LiteralPath $file
                    $fileContent = [pscustomobject]@{
                        type      = 'input_file'
                        filename  = $fileItem.Name
                        file_data = (Convert-FileToDataURL $file)
                    }
                }
                elseif ($file -match '[\\/]') {
                    continue
                }
                else {
                    # file id
                    $fileContent = [pscustomobject]@{
                        type    = 'input_file'
                        file_id = $file
                    }
                }
                $usermsg.content += $fileContent
            }
        }

        # Image input
        if ($PSBoundParameters.ContainsKey('Images')) {
            foreach ($image in $Images) {
                if ([string]::IsNullOrWhiteSpace($image)) { continue }
                $imageContent = $null

                if (Test-Path -LiteralPath $image -PathType Leaf) {
                    # local file
                    $imageContent = [pscustomobject]@{
                        type      = 'input_image'
                        image_url = (Convert-ImageToDataURL $image)
                        detail    = $ImageDetail
                    }
                }
                elseif ($image -match 'http[s]?://') {
                    # URL
                    $imageContent = [pscustomobject]@{
                        type      = 'input_image'
                        image_url = $image
                        detail    = $ImageDetail
                    }
                }
                else {
                    # file id
                    $imageContent = [pscustomobject]@{
                        type    = 'input_image'
                        file_id = $file
                        detail  = $ImageDetail
                    }
                }

                $usermsg.content += $imageContent
            }
        }

        if ($usermsg.content.Count -ge 1) {
            $Messages.Add($usermsg)
        }
        #endregion

        # Error if message is empty.
        if ($Messages.Count -eq 0) {
            Write-Error 'No message is specified. You must specify one or more messages.'
            return
        }

        $PostBody.input = $Messages.ToArray()
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
            $splat.Stream = $true
            Invoke-OpenAIAPIRequest @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object {
                    if ($OutputRawResponse) {
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
                } | ForEach-Object -Process {
                    if ($OutputRawResponse) {
                        Write-Output $_
                    }
                    elseif ($StreamOutputType -eq 'text') {
                        if ($_.type -cne 'response.output_text.delta') {
                            continue
                        }
                        Write-Output $_.delta
                    }
                    else {
                        Write-Output $_
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
            if ($OutputRawResponse) {
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

        #region For history, add model responses to messages list.
        if (@($Response.output).Count -ge 1) {
            $Messages.AddRange(@($Response.output))
        }
        #endregion

        #region Function call
        # TODO: Implement function call
        #endregion

        #region Output
        ParseResponseObject $Response -Messages $Messages -OutputType $OutputType
        #endregion
    }

    end {

    }
}