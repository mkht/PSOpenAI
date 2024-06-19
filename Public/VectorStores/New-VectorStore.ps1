function New-VectorStore {
    [CmdletBinding(DefaultParameterSetName = 'VectorStoreId')]
    [OutputType([pscustomobject])]
    param (
        # Hidden param, for Set-Thread cmdlet
        [Parameter(DontShow, ParameterSetName = 'VectorStore', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.VectorStore')]$VectorStore,

        [Parameter(DontShow, ParameterSetName = 'VectorStoreId', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$VectorStoreId,

        [Parameter()]
        [Alias('file_ids')]
        [ValidateCount(0, 500)]
        [object[]]$FileId,

        [Parameter()]
        [string]$Name,

        [Parameter()]
        [ValidateRange(1, 365)]
        [uint16]$ExpiresAfterDays,

        [Parameter()]
        [Completions('last_active_at')]
        [string][LowerCaseTransformation()]$ExpiresAfterAnchor = 'last_active_at',

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
        [System.Collections.IDictionary]$MetaData,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'VectorStores' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        #region Construct parameters for API request
        if ($VectorStore) {
            $VectorStoreId = $VectorStore.id
        }
        if (-not [string]::IsNullOrEmpty($VectorStoreId)) {
            $QueryUri = $OpenAIParameter.Uri.ToString() + "/$VectorStoreId"
        }
        else {
            $QueryUri = $OpenAIParameter.Uri
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($FileId.Count -gt 0) {
            $list = [System.Collections.Generic.List[string]]::new($FileId.Count)
            foreach ($item in $FileId) {
                if ($item -is [string]) {
                    $list.Add($item)
                }
                elseif ($item.psobject.TypeNames -contains 'PSOpenAI.File') {
                    $list.Add($item.id)
                }
            }
            if ($list.Count -gt 0) {
                $PostBody.file_ids = $list.ToArray()
            }

            # chunking_strategy parameter is only applicable if file_ids is non-empty.
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
        }
        if ($PSBoundParameters.ContainsKey('Name')) {
            $PostBody.name = $Name
        }
        if ($PSBoundParameters.ContainsKey('ExpiresAfterDays')) {
            $PostBody.expires_after = @{
                'anchor' = $ExpiresAfterAnchor
                'days'   = $ExpiresAfterDays
            }
        }
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            $PostBody.metadata = $Metadata
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
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        #region Output
        ParseVectorStoreObject -InputObject $Response
        #endregion
    }

    end {

    }
}
