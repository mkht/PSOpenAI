function New-Assistant {
    [CmdletBinding(DefaultParameterSetName = 'AssistantId')]
    [OutputType([pscustomobject])]
    param (
        # Hidden param, for Set-Assistant cmdlet
        [Parameter(DontShow, ParameterSetName = 'AssistantId', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Assistant')]
        [string][UrlEncodeTransformation()]$AssistantId,

        [Parameter()]
        [ValidateLength(0, 256)]
        [string]$Name,

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
        [ValidateLength(0, 512)]
        [string]$Description,

        [Parameter()]
        [ValidateLength(0, 256000)]
        [string]$Instructions,

        [Parameter()]
        [Alias('reasoning_effort')]
        [Completions('minimal', 'low', 'medium', 'high')]
        [string]$ReasoningEffort = 'medium',

        [Parameter()]
        [switch]$UseCodeInterpreter,

        [Parameter()]
        [switch]$UseFileSearch,

        # [Parameter()]
        # [switch]$UseFunction,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Functions,

        [Parameter()]
        [ValidateCount(0, 20)]
        [string[]]$FileIdsForCodeInterpreter,

        [Parameter()]
        [ValidateCount(1, 1)]   # Currently, allow only 1 vector store
        [string[]]$VectorStoresForFileSearch,

        [Parameter()]
        [ValidateCount(0, 10000)]
        [string[]]$FileIdsForFileSearch,

        [Parameter()]
        [ValidateRange(1, 50)]
        [uint16]$MaxNumberOfFileSearchResults,

        [Parameter()]
        [Completions('auto')]
        [string]$RankerForFileSearch = 'auto',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$ScoreThresholdForFileSearch = 0.0,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

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
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Assistants' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        #region Construct parameters for API request
        if ($Assistant) {
            $AssistantId = $Assistant.id
        }
        if (-not [string]::IsNullOrEmpty($AssistantId)) {
            $QueryUri = $OpenAIParameter.Uri.ToString() + "/$AssistantId"
        }
        else {
            $QueryUri = $OpenAIParameter.Uri
        }
        #endregion

        #region Construct tools object
        $Tools = @()
        if ($UseCodeInterpreter) {
            $Tools += @{'type' = 'code_interpreter' }
        }
        if ($UseFileSearch) {
            $fileseach = @{'type' = 'file_search' }

            # Construct file search options
            $fileseach_options = @{}
            if ($PSBoundParameters.ContainsKey('MaxNumberOfFileSearchResults')) {
                $fileseach_options.max_num_results = $MaxNumberOfFileSearchResults
            }
            if ($PSBoundParameters.ContainsKey('RankerForFileSearch') -or `
                    $PSBoundParameters.ContainsKey('ScoreThresholdForFileSearch')) {
                $fileseach_options.ranking_options = @{}
                $fileseach_options.ranking_options.ranker = $RankerForFileSearch
                $fileseach_options.ranking_options.score_threshold = $ScoreThresholdForFileSearch
            }

            if ($fileseach_options.Keys.Count -gt 0) {
                $fileseach.file_search = $fileseach_options
            }

            $Tools += $fileseach
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

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        if ($PSBoundParameters.ContainsKey('Name')) {
            $PostBody.name = $Name
        }
        if ($PSBoundParameters.ContainsKey('Description')) {
            $PostBody.description = $Description
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $PostBody.instructions = $Instructions
        }
        if ($PSBoundParameters.ContainsKey('ReasoningEffort')) {
            $PostBody.reasoning_effort = $ReasoningEffort
        }
        if ($Tools.Count -gt 0) {
            $PostBody.tools = $Tools
        }
        if ($ToolResources.Count -gt 0) {
            $PostBody.tool_resources = $ToolResources
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
        if ($PSBoundParameters.ContainsKey('Format')) {
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
        #endregion

        #region Send API Request
        $params = @{
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
        $Response = Invoke-OpenAIAPIRequest @params

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Parse response object
        if ($ResponseFormat -eq 'raw_response') {
            Write-Output $Response
            return
        }
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        #region Output
        Write-Verbose ('The assistant with id "{0}" has been created.' -f $Response.id)
        ParseAssistantsObject $Response
        #endregion
    }

    end {

    }
}
