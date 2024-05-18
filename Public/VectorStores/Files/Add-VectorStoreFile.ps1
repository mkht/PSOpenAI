function Add-VectorStoreFile {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'VectorStore_FileId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'VectorStore_File', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.VectorStore')]$VectorStore,

        [Parameter(ParameterSetName = 'VectorStoreId_FileId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'VectorStoreId_File', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('vector_store_id')]
        [string][UrlEncodeTransformation()]$VectorStoreId,

        [Parameter(ParameterSetName = 'VectorStore_FileId', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'VectorStoreId_FileId', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('file_id')]
        [string][UrlEncodeTransformation()]$FileId,

        [Parameter(ParameterSetName = 'VectorStore_File', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'VectorStoreId_File', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.File')]$File,

        [Parameter()]
        [switch]$PassThru,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'VectorStore.Files' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -like 'VectorStore_*') {
            $VectorStoreId = $VectorStore.id
        }
        if ($PSCmdlet.ParameterSetName -like '*_File') {
            $FileId = $File.id
        }

        if (-not $VectorStoreId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vector store id.'))
            return
        }
        if (-not $FileId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve file id.'))
            return
        }

        #region Construct parameters for API request
        $QueryUri = $OpenAIParameter.Uri.ToString() -f $VectorStoreId

        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.file_id = $FileId
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

        #region Output
        # Output vector store object only when the PassThru switch is specified.
        if ($PassThru) {
            PSOpenAI\Get-VectorStore -VectorStoreId $VectorStoreId @CommonParams
        }
        #endregion
    }

    end {

    }
}
