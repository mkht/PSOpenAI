function Remove-VectorStoreFile {
    [CmdletBinding(DefaultParameterSetName = 'VectorStore')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'VectorStore', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('InputObject')]  # for backword compatibility
        [Alias('VectorStore')]
        [Alias('vector_store_id')]
        [string][UrlEncodeTransformation()]$VectorStoreId,

        [Parameter(ParameterSetName = 'VectorStore', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('file_id')]
        [string][UrlEncodeTransformation()]$FileId,

        [Parameter(ParameterSetName = 'VectorStoreFile', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.VectorStore.File')]$VectorStoreFile,

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
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -ceq 'VectorStoreFile') {
            $VectorStoreId = $VectorStoreFile.vector_store_id
            $FileId = $VectorStoreFile.id
        }

        if (-not $VectorStoreId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vector store id.'))
            return
        }
        if (-not $FileId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vector store file id.'))
            return
        }

        #region Construct parameters for API request
        $QueryUri = ($OpenAIParameter.Uri.ToString() -f $VectorStoreId) + "/$FileId"
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Delete'
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

        #region Verbose Output
        if ($Response.deleted) {
            Write-Verbose ('The vector store file with id "{0}" has been deleted.' -f $Response.id)
        }
        #endregion
    }

    end {

    }
}
