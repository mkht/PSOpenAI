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
            'gpt-5',
            'gpt-5-mini',
            'gpt-5-nano',
            'gpt-5-pro',
            'gpt-5-chat-latest',
            'gpt-5-codex',
            'gpt-5.1',
            'gpt-5.1-chat-latest',
            'gpt-5.1-codex',
            'gpt-5.1-codex-mini',
            'gpt-5.1-codex-max',
            'gpt-5.2',
            'gpt-5.2-chat-latest',
            'gpt-5.2-codex',
            'gpt-5.2-pro',
            'o1',
            'o1-pro',
            'o3',
            'o3-pro',
            'o3-mini',
            'o4-mini',
            'o3-deep-research',
            'o4-mini-deep-research',
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
        #endregion File input

        #region Tools
        [Parameter()]
        [Alias('tool_choice')]
        [Completions('none', 'auto', 'required')]
        [string]$ToolChoice,

        [Parameter()]
        [Alias('parallel_tool_calls')]
        [bool]$ParallelToolCalls,

        [Parameter()]
        [Alias('max_tool_calls')]
        [int]$MaxToolCalls,

        #region Function calling
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Functions,

        #### Not yet implemented ####
        # [Parameter()]
        # [ValidateSet('None', 'Auto', 'Confirm')]
        # [string]$InvokeFunction = 'None',
        #endregion Function calling

        #region Custom tool
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$CustomTools,
        #endregion Custom tool

        # Built-in tools
        #region File Search
        [Parameter()]
        [switch]$UseFileSearchTool,

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
        [float]$FileSearchScoreThreshold = 0.0,

        [Parameter()]
        [float]$FileSearchHybridSearchEmbeddingWeight,

        [Parameter()]
        [float]$FileSearchHybridSearchTextWeight,
        #endregion File Search

        #region Web Search
        [Parameter()]
        [switch]$UseWebSearchTool,

        [Parameter()]
        [Completions('web_search')]
        [string]$WebSearchType = 'web_search',

        [Parameter()]
        [ValidateSet('low', 'medium', 'high')]
        [string][LowerCaseTransformation()]$WebSearchContextSize,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$WebSearchAllowedDomains,

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
        [switch]$UseComputerUseTool,

        [Parameter(DontShow)]
        [string]$ComputerUseType = 'computer_use_preview', # Currently, only 'computer_use_preview' is acceptable.

        [Parameter()]
        [Completions('browser', 'windows', 'mac', 'linux', 'ubuntu')]
        [string]$ComputerUseEnvironment,

        [Parameter()]
        [int]$ComputerUseDisplayHeight,

        [Parameter()]
        [int]$ComputerUseDisplayWidth,
        #endregion Computer use

        #region Remote MCP
        [Parameter()]
        [switch]$UseRemoteMCPTool,

        [Parameter(DontShow)]
        [string]$RemoteMCPType = 'mcp', # Always 'mcp'

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$RemoteMCPServerLabel,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$RemoteMCPServerUrl,

        [Parameter()]
        [string]$RemoteMCPServerDescription,

        [Parameter()]
        [object]$RemoteMCPAllowedTools,

        [Parameter()]
        [Completions('always', 'never')]
        [object]$RemoteMCPRequireApproval,

        [Parameter()]
        [System.Collections.IDictionary]$RemoteMCPHeaders,

        [Parameter()]
        [string]$RemoteMCPAuthorization,
        #endregion Remote MCP

        #region Connectors
        [Parameter()]
        [switch]$UseConnectorTool,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectorLabel,

        [Parameter()]
        [Completions(
            'connector_dropbox',
            'connector_gmail',
            'connector_googlecalendar',
            'connector_googledrive',
            'connector_microfotteams',
            'connector_outlookcalendar',
            'connector_outlookemail',
            'connector_sharepoint'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectorId,

        [Parameter()]
        [Completions('always', 'never')]
        [string]$ConnectorRequireApproval,

        [Parameter()]
        [string]$ConnectorAuthorization,
        #endregion Connectors

        #region Code Interpreter
        [Parameter()]
        [switch]$UseCodeInterpreterTool,

        [Parameter(DontShow)]
        [string]$CodeInterpreterType = 'code_interpreter', # Always 'code_interpreter'

        [Parameter()]
        [ValidateSet('1g', '4g', '16g', '64g')]
        [string]$CodeInterpreterMemoryLimit,

        [Parameter()]
        [string]$ContainerId = 'auto',

        [Parameter()]
        [string[]]$ContainerFileIds,
        #endregion Code Interpreter

        #region Image Generation
        [Parameter()]
        [switch]$UseImageGenerationTool,

        [Parameter(DontShow)]
        [string]$ImageGenerationType = 'image_generation', # Always 'image_generation'

        [Parameter()]
        [Completions('gpt-image-1', 'gpt-image-1-mini')]
        [string]$ImageGenerationModel,

        [Parameter()]
        [Completions('transparent', 'opaque', 'auto')]
        [string]$ImageGenerationBackGround = 'auto',

        [Parameter()]
        [string]$ImageGenerationInputImageMask,

        [Parameter()]
        [string]$ImageGenerationModeration = 'auto',

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$ImageGenerationOutputCompression,

        [Parameter()]
        [ValidateSet('png', 'jpeg', 'webp')]
        [string][LowerCaseTransformation()]$ImageGenerationOutputFormat = 'png',

        [Parameter()]
        [ValidateRange(0, 3)]
        [int]$ImageGenerationPartialImages,

        [Parameter()]
        [ValidateSet('low', 'medium', 'high', 'auto')]
        [string][LowerCaseTransformation()]$ImageGenerationQuality = 'auto',

        [Parameter()]
        [ValidateSet('auto', '1024x1024', '1536x1024', '1024x1536')]
        [string]$ImageGenerationSize = 'auto',
        #endregion Image Generation

        #region Local shell
        [Parameter()]
        [switch]$UseLocalShellTool,

        [Parameter(DontShow)]
        [string]$LocalShellType = 'local_shell', # Always 'local_shell'
        #endregion Local shell

        #region shell
        [Parameter()]
        [switch]$UseShellTool,
        #endregion shell

        #region Apply patch
        [Parameter()]
        [switch]$UseApplyPatchTool,
        #endregion Apply patch
        #endregion Tools

        [Parameter()]
        [Alias('conversation_id')]
        [string]$Conversation,

        [Parameter()]
        [Alias('previous_response_id')]
        [string]$PreviousResponseId,

        [Parameter()]
        [string]$PromptId,

        [Parameter()]
        [System.Collections.IDictionary]$PromptVariables,

        [Parameter()]
        [string]$PromptVersion,

        [Parameter()]
        [Completions(
            'code_interpreter_call.outputs',
            'computer_call_output.output.image_url',
            'file_search_call.results',
            'message.input_image.image_url',
            'message.output_text.logprobs',
            'reasoning.encrypted_content'
        )]
        [AllowEmptyCollection()]
        [string[]]$Include,

        [Parameter()]
        [Completions('auto', 'disabled')]
        [string]$Truncation,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [float]$Temperature,

        [Parameter()]
        [ValidateRange(0, 20)]
        [Alias('top_logprobs')]
        [int]$TopLogprobs,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [float]$TopP,

        [Parameter()]
        [bool]$Store,

        [Parameter()]
        [switch]$Background = $false,

        #region Stream
        [Parameter()]
        [switch]$Stream = $false,

        [Parameter()]
        [ValidateSet('text', 'object')]
        [string]$StreamOutputType = 'text',
        #endregion Stream

        [Parameter()]
        [ValidateSet('low', 'medium', 'high')]
        [string]$Verbosity = 'medium',

        #region Reasoning
        [Parameter()]
        [Completions('none', 'minimal', 'low', 'medium', 'high', 'xhigh')]
        [string]$ReasoningEffort,

        [Parameter()]
        [Completions('auto', 'concise', 'detailed')]
        [string]$ReasoningSummary,
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

        ## Set up masking patterns
        $MaskPatterns = [System.Collections.Generic.List[Tuple[regex, string]]]::new()
    }

    process {
        #region Construct parameters for API request
        $Response = $null
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()

        # Reusable prompts
        $IsReusablePromptSpecified = $false
        if ($PromptId) {
            $PromptOptions = @{id = $PromptId }
            if ($PSBoundParameters.ContainsKey('PromptVariables')) {
                $PromptOptions.variables = $PromptVariables
            }
            if ($PSBoundParameters.ContainsKey('PromptVersion')) {
                $PromptOptions.version = $PromptVersion
            }
            $PostBody.prompt = $PromptOptions

            ## When specifying a reusable prompt, normally required parameters such as model and input become optional.
            $IsReusablePromptSpecified = $true
        }

        # Specify model
        if (-not $IsReusablePromptSpecified -or $PSBoundParameters.ContainsKey('Model')) {
            $PostBody.model = $Model
        }

        if ($Conversation) {
            $IsConversationIdSpecified = $true
            $PostBody.conversation = $Conversation
        }

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
            elseif ($ToolChoice -in (
                    'file_search',
                    'web_search_preview',
                    'computer_use_preview',
                    'code_interpreter',
                    'mcp',
                    'image_generation'
                )) {
                # built-in tools
                $ToolChoice = @{type = $ToolChoice }
            }
            else {
                # custom functions
                $ToolChoice = @{type = 'function'; name = $ToolChoice }
            }
            $PostBody.tool_choice = $ToolChoice
        }
        if ($PSBoundParameters.ContainsKey('MaxToolCalls')) {
            $PostBody.max_tool_calls = $MaxToolCalls
        }
        if ($PSBoundParameters.ContainsKey('ParallelToolCalls')) {
            $PostBody.parallel_tool_calls = $ParallelToolCalls
        }
        if ($PSBoundParameters.ContainsKey('TopLogprobs')) {
            $PostBody.top_logprobs = $TopLogprobs
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
        if ($Background) {
            $PostBody.background = [bool]$Background
        }
        if ($Stream) {
            $PostBody.stream = [bool]$Stream
        }

        # Reasoning
        $ReasoningOptions = @{}
        if ($PSBoundParameters.ContainsKey('ReasoningEffort')) {
            $ReasoningOptions.effort = $ReasoningEffort
        }
        if ($PSBoundParameters.ContainsKey('ReasoningSummary')) {
            $ReasoningOptions.summary = $ReasoningSummary
        }
        if ($ReasoningOptions.Keys.Count -gt 0) {
            $PostBody.reasoning = $ReasoningOptions
        }

        # Text Output options
        $TextOutputOptions = @{}
        if ($PSBoundParameters.ContainsKey('Verbosity')) {
            $TextOutputOptions.verbosity = $Verbosity
        }
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
                if (-not $JsonSchema) {
                    Write-Error -Exception ([System.ArgumentException]::new('JsonSchema must be specified.'))
                }
                if (-not $JsonSchemaName) {
                    Write-Error -Exception ([System.ArgumentException]::new('JsonSchemaName must be specified.'))
                }
                $TextOutputOptions.format = @{
                    'type'   = 'json_schema'
                    'schema' = (ConvertFrom-Json $JsonSchema)
                    'name'   = $JsonSchemaName
                }
                if ($PSBoundParameters.ContainsKey('JsonSchemaDescription')) {
                    $TextOutputOptions.format.description = $JsonSchemaDescription
                }
                if ($PSBoundParameters.ContainsKey('JsonSchemaStrict')) {
                    $TextOutputOptions.format.strict = $JsonSchemaStrict
                }
            }
        }
        if ($TextOutputOptions.Keys.Count -gt 0) {
            $PostBody.text = $TextOutputOptions
        }

        #region Tools
        $Tools = @()
        # Function calling
        if ($PSBoundParameters.ContainsKey('Functions')) {
            $Tools += $Functions
        }

        # Custom tools
        if ($PSBoundParameters.ContainsKey('CustomTools')) {
            $Tools += $CustomTools
        }

        #region File Search
        if ($UseFileSearchTool) {
            if ($FileSearchVectorStoreIds.Count -eq 0) {
                Write-Error 'VectorStore Ids must be specified.'
            }
            else {
                $RankingOptions = @{}
                $HybridSearchOptions = @{}
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
                if ($PSBoundParameters.ContainsKey('FileSearchHybridSearchEmbeddingWeight')) {
                    $HybridSearchOptions.embedding_weight = $FileSearchHybridSearchEmbeddingWeight
                }
                if ($PSBoundParameters.ContainsKey('FileSearchHybridSearchTextWeight')) {
                    $HybridSearchOptions.text_weight = $FileSearchHybridSearchTextWeight
                }

                if ($HybridSearchOptions.Keys.Count -gt 0) {
                    $RankingOptions.hybrid_search_options = $HybridSearchOptions
                }

                if ($RankingOptions.Keys.Count -gt 0) {
                    $FileSearchTool.ranking_options = $RankingOptions
                }
                $Tools += $FileSearchTool
            }
        }

        #region Web Search
        if ($UseWebSearchTool) {
            $UserLocation = @{}
            $WebSearchTool = @{
                type = $WebSearchType
            }

            if ($PSBoundParameters.ContainsKey('WebSearchContextSize')) {
                $WebSearchTool.search_context_size = $WebSearchContextSize
            }
            if ($PSBoundParameters.ContainsKey('WebSearchAllowedDomains')) {
                $WebSearchTool.filters = @{allowed_domains = $WebSearchAllowedDomains }
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

        #region Computer Use
        if ($UseComputerUseTool) {
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

        #region Remote MCP
        if ($UseRemoteMCPTool) {
            # Server label and URL are required.
            if ([string]::IsNullOrWhiteSpace($RemoteMCPServerLabel)) {
                Write-Error 'RemoteMCPServerLabel must be specified.'
            }
            if ([string]::IsNullOrWhiteSpace($RemoteMCPServerUrl)) {
                Write-Error 'RemoteMCPServerUrl must be specified.'
            }

            $MCPTool = @{
                type         = $RemoteMCPType
                server_label = $RemoteMCPServerLabel
                server_url   = $RemoteMCPServerUrl
            }

            if ($PSBoundParameters.ContainsKey('RemoteMCPServerDescription')) {
                $MCPTool.server_description = $RemoteMCPServerDescription
            }
            if ($PSBoundParameters.ContainsKey('RemoteMCPAuthorization')) {
                $MCPTool.authorization = $RemoteMCPAuthorization
                $MaskPatterns.Add([Tuple[regex, string]]::new([regex]::Escape($RemoteMCPAuthorization), '<OAuth Access Token>'))
            }
            if ($PSBoundParameters.ContainsKey('RemoteMCPAllowedTools')) {
                if ($RemoteMCPAllowedTools.tool_names.Count -gt 0) {
                    $RemoteMCPAllowedTools = $RemoteMCPAllowedTools.tool_names
                }
                $MCPTool.allowed_tools = [string[]]$RemoteMCPAllowedTools
            }
            if ($PSBoundParameters.ContainsKey('RemoteMCPRequireApproval')) {
                if ($RemoteMCPRequireApproval -is [string]) {
                    $MCPTool.require_approval = $RemoteMCPRequireApproval.Trim()
                }
                else {
                    $MCPApprovalFilter = @{}
                    if ($RemoteMCPRequireApproval.always.tool_names.Count -gt 0) {
                        $MCPApprovalFilter.always = @{tool_names = [string[]]$RemoteMCPRequireApproval.always.tool_names }
                    }
                    if ($RemoteMCPRequireApproval.never.tool_names.Count -gt 0) {
                        $MCPApprovalFilter.never = @{tool_names = [string[]]$RemoteMCPRequireApproval.never.tool_names }
                    }
                    if ($MCPApprovalFilter.Keys.Count -gt 0) {
                        $MCPTool.require_approval = $MCPApprovalFilter
                    }
                }
            }
            if ($RemoteMCPHeaders.Keys.Count -gt 0) {
                $MCPTool.headers = $RemoteMCPHeaders
            }

            $Tools += $MCPTool
        }

        #region Connectors
        if ($UseConnectorTool) {
            # Server label and connector_id are required.
            if ([string]::IsNullOrWhiteSpace($ConnectorLabel)) {
                Write-Error 'ConnectorLabel must be specified.'
            }
            if ([string]::IsNullOrWhiteSpace($ConnectorId)) {
                Write-Error 'ConnectorId must be specified.'
            }

            $ConnectorTool = @{
                type         = 'mcp'
                server_label = $ConnectorLabel
                connector_id = $ConnectorId
            }

            if ($PSBoundParameters.ContainsKey('ConnectorAuthorization')) {
                $ConnectorTool.authorization = $ConnectorAuthorization
                $MaskPatterns.Add([Tuple[regex, string]]::new([regex]::Escape($ConnectorAuthorization), '<OAuth Access Token>'))
            }
            if ($PSBoundParameters.ContainsKey('ConnectorRequireApproval')) {
                $ConnectorTool.require_approval = $ConnectorRequireApproval.Trim()
            }

            $Tools += $ConnectorTool
        }

        #region Code Interpreter
        if ($UseCodeInterpreterTool) {
            $CodeInterpreterTool = @{
                type      = $CodeInterpreterType
                container = $ContainerId
            }
            if ($ContainerId -eq 'auto') {
                # Auto container
                $CodeInterpreterTool.container = @{type = 'auto' }
                if ($PSBoundParameters.ContainsKey('ContainerFileIds')) {
                    $CodeInterpreterTool.container.file_ids = $ContainerFileIds
                }
                if ($PSBoundParameters.ContainsKey('CodeInterpreterMemoryLimit')) {
                    $CodeInterpreterTool.container.memory_limit = $CodeInterpreterMemoryLimit
                }
            }
            $Tools += $CodeInterpreterTool
        }

        #region Image Generation
        if ($UseImageGenerationTool) {
            $ImageGenerationTool = @{
                type = $ImageGenerationType
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationModel')) {
                $ImageGenerationTool.model = $ImageGenerationModel
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationBackGround')) {
                $ImageGenerationTool.background = $ImageGenerationBackGround
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationInputImageMask')) {
                if (Test-Path -LiteralPath $ImageGenerationInputImageMask -PathType Leaf) {
                    # local file
                    $image_url = Convert-ImageToDataURL $ImageGenerationInputImageMask
                    $ImageGenerationTool.input_image_mask = @{image_url = $image_url }
                }
                else {
                    # File id
                    $ImageGenerationTool.input_image_mask = @{file_id = $ImageGenerationInputImageMask }
                }
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationModeration')) {
                $ImageGenerationTool.moderation = $ImageGenerationModeration
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationOutputCompression')) {
                $ImageGenerationTool.output_compression = $ImageGenerationOutputCompression
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationOutputFormat')) {
                $ImageGenerationTool.output_format = $ImageGenerationOutputFormat
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationPartialImages')) {
                $ImageGenerationTool.partial_images = $ImageGenerationPartialImages
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationQuality')) {
                $ImageGenerationTool.quality = $ImageGenerationQuality
            }
            if ($PSBoundParameters.ContainsKey('ImageGenerationSize')) {
                $ImageGenerationTool.size = $ImageGenerationSize
            }

            $Tools += $ImageGenerationTool
        }

        #region Local Shell
        if ($UseLocalShellTool) {
            $LocalShellTool = @{
                type = $LocalShellType
            }
            $Tools += $LocalShellTool
        }

        #region shell
        if ($UseShellTool) {
            $ShellTool = @{
                type = 'shell'
            }
            $Tools += $ShellTool
        }

        #region Apply Patch
        if ($UseApplyPatchTool) {
            $ApplyPatchTool = @{
                type = 'apply_patch'
            }
            $Tools += $ApplyPatchTool
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
            type    = 'message'
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
            type    = 'message'
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
            type    = 'message'
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
                elseif ($file -match '^http[s]?://') {
                    # URL
                    $fileContent = [pscustomobject]@{
                        type     = 'input_file'
                        file_url = $file
                    }
                }
                elseif ($file -match '[\\/]') {
                    # Invalid file path
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
        if (-not $IsConversationIdSpecified -and `
                -not $IsReusablePromptSpecified -and `
                $Messages.Count -eq 0) {
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
            MaskPatterns      = $MaskPatterns
        }

        #region Send API Request (Stream)
        if ($Stream) {
            if ($Background) {
                $splat.First = 1
            }
            # Stream output
            Invoke-OpenAIAPIRequestSSE @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object -Process {
                    if ($OutputRawResponse) {
                        Write-Output $_
                    }
                    else {
                        # Parse response object
                        try {
                            $Response = $_ | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            Write-Error -Exception $_.Exception
                        }

                        if ($Background) {
                            if ($null -ne $Response.response) {
                                ParseResponseObject $Response.response -Messages $Messages -OutputType $OutputType
                            }
                        }
                        if ($StreamOutputType -eq 'text') {
                            if ($Response.type -cne 'response.output_text.delta') {
                                continue
                            }
                            Write-Output $Response.delta
                        }
                        else {
                            Write-Output $Response
                        }
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
        if ($Response.output.Count -ge 1) {
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