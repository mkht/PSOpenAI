function Start-VectorStoreFileBatch {
    [CmdletBinding(DefaultParameterSetName = 'VectorStoreId')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'VectorStore', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backward compatibility
        [PSTypeName('PSOpenAI.VectorStore')]$VectorStore,

        [Parameter(ParameterSetName = 'VectorStoreId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('vector_store_id')]
        [string][UrlEncodeTransformation()]$VectorStoreId,

        [Parameter()]
        [System.Collections.IDictionary]$Attributes,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('file_ids')]
        [Alias('FileId')]
        [ValidateCount(0, 500)]
        [object[]]$Files,

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

        $listFiles = [System.Collections.Generic.List[hashtable]]::new()
        $useFileIdsParam = $true
    }

    process {
        foreach ($file in $Files) {
            if ($null -eq $file) {
                continue
            }

            $fileObject = @{}
            if ($file -is [string]) {
                $fileObject.file_id = [string]$file
            }
            elseif ($file.psobject.TypeNames -contains 'PSOpenAI.File') {
                $fileObject.file_id = [string]$file.id
            }
            elseif ($file -is [System.Collections.IDictionary]) {
                if ( $file.Contains('file_id')) {
                    $fileObject.file_id = $file['file_id']
                }
                elseif ( $file.Contains('id')) {
                    $fileObject.file_id = $file['id']
                }
                else {
                    Write-Error -Exception ([System.ArgumentException]::new('Hashtable item in Files parameter must contain file_id or id key.'))
                    continue
                }
                if ( $file.Contains('attributes')) {
                    $fileObject.attributes = $file['attributes']
                }
                if ($file.Contains('chunking_strategy')) {
                    $ChunkingStrategyObject = $file['chunking_strategy']
                    if ($ChunkingStrategyObject -is [System.Collections.IDictionary]) {
                        $fileObject.chunking_strategy = $ChunkingStrategyObject
                    }
                    else {
                        $fileObject.chunking_strategy = @{ type = 'auto' }
                    }
                }
                $useFileIdsParam = $false
            }
            else {
                Write-Error -Exception ([System.ArgumentException]::new('Each item in Files parameter must be a string (file ID), PSOpenAI.File object, or hashtable with file_id key.'))
                continue
            }

            $listFiles.Add($fileObject)
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
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()

        if ($listFiles.Count -gt 0) {
            if ($useFileIdsParam) {
                # If all items are simple file IDs, use file_ids parameter
                $PostBody.file_ids = [string[]]$listFiles.ToArray().ForEach( { $_.file_id } )
            }
            else {
                $PostBody.files = $listFiles.ToArray()
            }
        }

        if ($PSBoundParameters.ContainsKey('Attributes')) {
            $PostBody.attributes = $Attributes
        }
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
