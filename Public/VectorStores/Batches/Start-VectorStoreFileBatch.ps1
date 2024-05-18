function Start-VectorStoreFileBatch {
    [CmdletBinding(DefaultParameterSetName = 'VectorStoreId')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'VectorStore', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.VectorStore')]$VectorStore,

        [Parameter(ParameterSetName = 'VectorStoreId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('vector_store_id')]
        [string][UrlEncodeTransformation()]$VectorStoreId,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('file_ids')]
        [ValidateCount(0, 500)]
        [object[]]$FileId,

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

        $BatchBag = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($item in $FileId) {
            # Add an object to queue
            if ($null -eq $item) {
                continue
            }
            elseif ($item.psobject.TypeNames -contains 'PSOpenAI.File') {
                $BatchBag.Add($item.id)
            }
            else {
                $BatchBag.Add($item)
            }
        }
    }

    end {
        # Get vector store id
        if ($PSCmdlet.ParameterSetName -ceq 'VectorStore') {
            $VectorStoreId = $VectorStore.id
        }
        if (-not $VectorStoreId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vector store id.'))
            return
        }

        #region Construct parameters for API request
        $QueryUri = ($OpenAIParameter.Uri.ToString() -f $VectorStoreId)
        #endregion

        if ($BatchBag.Count -eq 0) {
            return
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.file_ids = $BatchBag.ToArray()
        #endregion

        #region Send API Request
        $splat = @{
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
        $Response = Invoke-OpenAIAPIRequest @splat

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
        Write-Verbose ('Start batch with id "{0}". The current status is "{1}"' -f $Response.id, $Response.status)
        ParseVectorStoreFileBatchObject $Response
        #endregion
    }
}
