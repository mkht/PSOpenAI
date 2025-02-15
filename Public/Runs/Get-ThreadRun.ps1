function Get-ThreadRun {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get_Thread', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_Thread', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.Thread')]$Thread,

        [Parameter(ParameterSetName = 'Get_Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(ParameterSetName = 'Get_Thread', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get_Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('run_id')]
        [string][UrlEncodeTransformation()]$RunId,

        [Parameter(ParameterSetName = 'Get_ThreadRun', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_Id')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_Id')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List_Thread', DontShow)]
        [Parameter(ParameterSetName = 'List_Id', DontShow)]
        [string]$After,

        [Parameter(ParameterSetName = 'List_Thread', DontShow)]
        [Parameter(ParameterSetName = 'List_Id', DontShow)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_Id')]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

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

        [Parameter(DontShow)]
        [switch]$Primitive,

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
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -like '*_Thread') {
            $ThreadId = $Thread.id
        }
        elseif ($PSCmdlet.ParameterSetName -like '*_ThreadRun') {
            $ThreadId = $Run.thread_id
            $RunId = $Run.id
        }

        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve thread id.'))
            return
        }

        #region Construct Query URI
        $QueryUri = ($OpenAIParameter.Uri.ToString() -f $ThreadID)
        $UriBuilder = [System.UriBuilder]::new($QueryUri)
        if ($PSCmdlet.ParameterSetName -like 'Get_*') {
            $UriBuilder.Path += "/$RunId"
            $QueryUri = $UriBuilder.Uri
        }
        else {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
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
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }
        #enregion

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
            ParseThreadRunObject $res
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($All) {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                PSOpenAI\Get-ThreadRun @PagenationParam
            }
            else {
                # Display warning message if there is more data. (Except when the user specifies -Limit parameter explicitly.)
                if (-not $PSBoundParameters.ContainsKey('Limit')) {
                    Write-Warning 'There is more data that has not been retrieved.'
                }
            }
        }
        #endregion
    }

    end {

    }
}
