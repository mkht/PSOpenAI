function Get-VectorStoreFileInBatch {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('vector_store_id')]
        [Alias('VectorStore')]
        [ValidateScript({ [bool](Get-VectorStoreIdFromInputObject $_) })]
        [Object]$InputObject,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('batch_id')]
        [Alias('Id')]
        [string][UrlEncodeTransformation()]$BatchId,

        [Parameter(ParameterSetName = 'List')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'ListAll')]
        [switch]$All,

        [Parameter(ParameterSetName = 'ListAll', DontShow)]
        [string]$After,

        [Parameter(ParameterSetName = 'ListAll', DontShow)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List')]
        [Parameter(ParameterSetName = 'ListAll')]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

        [Parameter(ParameterSetName = 'List')]
        [Parameter(ParameterSetName = 'ListAll')]
        [ValidateSet('in_progress', 'completed', 'failed', 'cancelled')]
        [string][LowerCaseTransformation()]$Filter,

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
        $OpenAIParameter = Get-OpenAIContext -EndpointName 'VectorStore.FileBatches' -ApiType $ApiType -AuthType $AuthType -ApiBase $ApiBase -ApiVersion $ApiVersion -ErrorAction Stop
    }

    process {
        # Get vector store id
        [string][UrlEncodeTransformation()]$VsId = Get-VectorStoreIdFromInputObject $InputObject
        if (-not $VsId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vectore store id.'))
            return
        }

        $QueryUri = $OpenAIParameter.Uri.ToString() -f $VsId
        $UriBuilder = [System.UriBuilder]::new($QueryUri)
        $UriBuilder.Path += "/$BatchId/files"
        if ($PSCmdlet.ParameterSetName -eq 'List') {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $QueryParam.Add('limit', $Limit);
            $QueryParam.Add('order', $Order);
            if ($Filter) {
                $QueryParam.Add('filter', $Filter);
            }
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }
        else {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $QueryParam.Add('limit', '100');
            $QueryParam.Add('order', $Order);
            if ($After) {
                $QueryParam.Add('after', $After);
            }
            if ($Before) {
                $QueryParam.Add('before', $Before);
            }
            if ($Filter) {
                $QueryParam.Add('filter', $Filter);
            }
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }

        #region Send API Request
        $params = @{
            Method            = 'Get'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $TimeoutSec
            MaxRetryCount     = $MaxRetryCount
            ApiKey            = $SecureToken
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $Organization
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
            ParseVectorStoreFileObject $res
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($PSCmdlet.ParameterSetName -eq 'ListAll') {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                PSOpenAI\Get-VectorStoreFile @PagenationParam
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
