function Start-VectorStoreFileBatch {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('vector_store_id')]
        [Alias('VectorStore')]
        [ValidateScript({ [bool](Get-VectorStoreIdFromInputObject $_) })]
        [Object]$InputObject,

        [Parameter(Mandatory, Position = 1)]
        [ValidateCount(1, 500)]
        [Alias('file_ids')]
        [string[]]$FileId,

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

        $BatchBag = [System.Collections.Generic.List[string]]::new()
    }

    process {
        foreach ($item in $FileId) {
            # Validate input object
            if ($null -eq $item) {
                continue
            }
            else {
                # Add an object to queue
                $BatchBag.Add($item)
            }
        }
    }

    end {
        # Get vector store id
        [string][UrlEncodeTransformation()]$VsId = Get-VectorStoreIdFromInputObject $InputObject
        if (-not $VsId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vector store id.'))
            return
        }

        #region Construct parameters for API request
        $QueryUri = ($OpenAIParameter.Uri.ToString() -f $VsId)
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
            TimeoutSec        = $TimeoutSec
            MaxRetryCount     = $MaxRetryCount
            ApiKey            = $SecureToken
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $Organization
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
