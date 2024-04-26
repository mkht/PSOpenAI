function Stop-VectorStoreFileBatch {
    [CmdletBinding()]
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
        [switch]$Wait,

        [Parameter()]
        [switch]$PassThru,

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

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get vector store id
        [string][UrlEncodeTransformation()]$VsId = Get-VectorStoreIdFromInputObject $InputObject
        if (-not $VsId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vectore store id.'))
            return
        }

        #region Construct Query URI
        $QueryUri = $OpenAIParameter.Uri.ToString() -f $VsId
        $UriBuilder = [System.UriBuilder]::new($QueryUri)
        $UriBuilder.Path += "/$BatchId/cancel"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Post'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $TimeoutSec
            MaxRetryCount     = $MaxRetryCount
            ApiKey            = $SecureToken
            AuthType          = $OpenAIParameter.AuthType
            Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
            Organization      = $Organization
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

        Write-Verbose 'Requested to cancel batch.'

        #region Parse response object
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        # Wait for cancel
        if ($Wait) {
            Write-Verbose 'Waiting for a cancellation...'
            $Result = $Response | PSOpenAI\Wait-VectorStoreFileBatch -StatusForExit ('cancelled', 'completed', 'failed', 'expired') @CommonParams
            if ($null -ne $Result -and $PassThru) {
                Write-Output $Result
            }
        }
        else {
            #region Output
            # No output on default
            if ($PassThru) {
                ParseVectorStoreFileBatchObject $Response
            }
            #endregion
        }
    }

    end {

    }
}