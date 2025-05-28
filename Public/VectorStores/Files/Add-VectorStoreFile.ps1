function Add-VectorStoreFile {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('InputObject')]  # for backword compatibility
        [Alias('VectorStore')]
        [Alias('vector_store_id')]
        [string][UrlEncodeTransformation()]$VectorStoreId,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('File')]
        [Alias('file_id')]
        [string][UrlEncodeTransformation()]$FileId,

        [Parameter()]
        [ValidateSet('auto', 'static')]
        [Alias('chunking_strategy')]
        [string]$ChunkingStrategy,

        [Parameter()]
        [ValidateRange(100, 4096)]
        [Alias('max_chunk_size_tokens')]
        [int]$MaxChunkSizeTokens = 800,

        [Parameter()]
        [ValidateRange(0, 4096)]
        [Alias('chunk_overlap_tokens')]
        [int]$ChunkOverlapTokens = 400,

        [Parameter()]
        [System.Collections.IDictionary]$Attributes,

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
        #region Construct parameters for API request
        $QueryUri = $OpenAIParameter.Uri.ToString() -f $VectorStoreId

        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.file_id = $FileId

        if ($PSBoundParameters.ContainsKey('ChunkingStrategy')) {
            $PostBody.chunking_strategy = @{type = $ChunkingStrategy }
            if ($ChunkingStrategy -eq 'static') {
                # validation (the overlap must not exceed half of max)
                if (2 * $ChunkOverlapTokens -gt $MaxChunkSizeTokens) {
                    Write-Error -Exception ([System.ArgumentException]::new('ChunkOverlapTokens must not exceed half of MaxChunkSizeTokens.'))
                    return
                }
                $PostBody.chunking_strategy.static = @{
                    max_chunk_size_tokens = $MaxChunkSizeTokens
                    chunk_overlap_tokens  = $ChunkOverlapTokens
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('Attributes')) {
            $PostBody.attributes = $Attributes
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
