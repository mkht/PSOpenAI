function Get-ThreadRunStep {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get_Run', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_Run', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'Get_RunId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_RunId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('run_id')]
        [string][UrlEncodeTransformation()]$RunId,

        [Parameter(ParameterSetName = 'Get_RunId', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_RunId', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(ParameterSetName = 'Get_Run', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get_RunId', Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [Alias('step_id')]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$StepId,

        [Parameter(ParameterSetName = 'Get_RunStep', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.Thread.Run.Step')]$Step,

        [Parameter(ParameterSetName = 'List_Run')]
        [Parameter(ParameterSetName = 'List_RunId')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'List_Run')]
        [Parameter(ParameterSetName = 'List_RunId')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List_Run', DontShow)]
        [Parameter(ParameterSetName = 'List_RunId', DontShow)]
        [string]$After,

        [Parameter(ParameterSetName = 'List_Run', DontShow)]
        [Parameter(ParameterSetName = 'List_RunId', DontShow)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List_Run')]
        [Parameter(ParameterSetName = 'List_RunId')]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

        [Parameter()]
        [Completions('step_details.tool_calls[*].file_search.results[*].content')]
        [string[]]$Include,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Runs' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -like '*_Run') {
            $RunId = $Run.id
            $ThreadId = $Run.thread_id
        }
        elseif ($PSCmdlet.ParameterSetName -like '*_RunStep') {
            $RunId = $Step.run_id
            $ThreadId = $Step.thread_id
            $StepId = $Step.id
        }

        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve thread id.'))
            return
        }

        if (-not $RunId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve run id.'))
            return
        }

        #region Construct query url
        $QueryUri = ($OpenAIParameter.Uri.ToString() -f $ThreadId)
        $UriBuilder = [System.UriBuilder]::new($QueryUri)
        $UriBuilder.Path += "/$RunId/steps"
        $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)

        if ($PSCmdlet.ParameterSetName -like 'Get_*') {
            $UriBuilder.Path += "/$StepId"
        }
        else {
            if ($All) {
                $Limit = 100
            }
            $QueryParam.Add('limit', $Limit)
            $QueryParam.Add('order', $Order)
            if ($After) {
                $QueryParam.Add('after', $After)
            }
            if ($Before) {
                $QueryParam.Add('before', $Before)
            }
        }

        if ($PSBoundParameters.ContainsKey('Include')) {
            $QueryParam.Add('include[]', $Include)
        }

        $UriBuilder.Query = $QueryParam.ToString()
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Get'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
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
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        #region Output
        if ($Response.object -eq 'list' -and ($null -ne $Response.data)) {
            # List of object
            $Responses = @($Response.data)
        }
        else {
            # Single object
            $Responses = @($Response)
        }
        # parse objects
        foreach ($res in $Responses) {
            ParseThreadRunStepObject $res -CommonParams $CommonParams
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($All) {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                PSOpenAI\Get-ThreadRunStep @PagenationParam
            }
            else {
                Write-Warning 'There is more data that has not been retrieved.'
            }
        }
        #endregion
    }

    end {

    }
}
