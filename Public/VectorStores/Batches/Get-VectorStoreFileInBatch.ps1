function Get-VectorStoreFileInBatch {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'List_VectorStore', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backward compatibility
        [PSTypeName('PSOpenAI.VectorStore')]$VectorStore,

        [Parameter(ParameterSetName = 'List_Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('vector_store_id')]
        [string][UrlEncodeTransformation()]$VectorStoreId,

        [Parameter(ParameterSetName = 'List_VectorStore', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('batch_id')]
        [string][UrlEncodeTransformation()]$BatchId,

        [Parameter(ParameterSetName = 'List_VectorStoreFileBatch', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.VectorStore.FileBatch')]$Batch,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter()]
        [switch]$All,

        [Parameter(DontShow)]
        [string]$After,

        [Parameter(DontShow)]
        [string]$Before,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

        [Parameter()]
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
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'VectorStore.FileBatches' -Parameters $PSBoundParameters -ErrorAction Stop

        # Iterator flag
        [bool]$HasMore = $true
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -like '*_VectorStore') {
            $VectorStoreId = $VectorStore.id
        }
        elseif ($PSCmdlet.ParameterSetName -like '*_VectorStoreFileBatch') {
            $VectorStoreId = $Batch.vector_store_id
            $BatchId = $Batch.id
        }

        if (-not $VectorStoreId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vector store id.'))
            return
        }
        if (-not $BatchId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve batch id.'))
            return
        }

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            #region Pagenation Loop
            while ($HasMore) {
                #region Construct Query URI
                $QueryUri = $OpenAIParameter.Uri.ToString() -f $VectorStoreId
                $UriBuilder = [System.UriBuilder]::new($QueryUri)
                $UriBuilder.Path += "/$BatchId/files"
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
                if ($Filter) {
                    $QueryParam.Add('filter', $Filter)
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
                    return
                }
                #endregion

                # Check cancellation
                $Cancellation.Token.ThrowIfCancellationRequested()

                # Update iterator flag
                if ($HasMore = [bool]$Response.has_more) {
                    if ($All -and $Response.last_id) {
                        $After = $Response.last_id
                    }
                    else {
                        $HasMore = $false
                        if (-not $PSBoundParameters.ContainsKey('Limit')) {
                            Write-Warning 'There is more data that has not been retrieved.'
                        }
                    }
                }

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
            }
            #endregion
        }
        catch [OperationCanceledException] {
            Write-TimeoutError
            return
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        finally {
            if ($null -ne $Cancellation) {
                $Cancellation.Dispose()
            }
        }
    }

    end {

    }
}
