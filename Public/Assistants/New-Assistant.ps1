function New-Assistant {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        # Hidden param, for Set-Assistants cmdlet
        [Parameter(DontShow, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Object]$InputObject,

        [Parameter()]
        [ValidateLength(0, 256)]
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
        [ValidateLength(0, 512)]
        [string]$Description,

        [Parameter()]
        [ValidateLength(0, 256000)]
        [string]$Instructions,

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
        [ValidateScript({ [bool](Get-VectorStoreIdFromInputObject $_) })]
        [ValidateCount(1, 1)]   # Currently, allow only 1 vector store
        [object[]]$VectorStoresForFileSearch,

        [Parameter()]
        [ValidateCount(0, 10000)]
        [string[]]$FileIdsForFileSearch,

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

        # Get API context
        $OpenAIParameter = Get-OpenAIContext -EndpointName 'Assistants' -ApiType $ApiType -AuthType $AuthType -ApiBase $ApiBase -ApiVersion $ApiVersion -ErrorAction Stop
    }

    process {
        #region Get assistant_id
        if ($null -ne $InputObject) {
            $AssistantId = Get-AssistantIdFromInputObject $InputObject
        }
        #endregion

        #region Construct Query URI
        if (-not [string]::IsNullOrEmpty($AssistantId)) {
            $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
            $UriBuilder.Path += "/$AssistantId"
            $QueryUri = $UriBuilder.Uri
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
        if ($PSBoundParameters.ContainsKey('Format') -and $Format -notin ('default', 'raw_response')) {
            if ($Format -eq 'auto') {
                $PostBody.response_format = 'auto'
            }
            else {
                $PostBody.response_format = @{'type' = $Format }
            }
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
        Write-Verbose ('The assistant with id "{0}" has been created.' -f $Response.id)
        ParseAssistantsObject $Response
        #endregion
    }

    end {

    }
}
