function Stop-Batch {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Batch', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.Batch')]$Batch,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('batch_id')]
        [Alias('Id')]   # for backword compatibility
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
        [switch]$Force,

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
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Batch' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get id
        if ($PSCmdlet.ParameterSetName -ceq 'Batch') {
            $BatchId = $Batch.id
        }
        else {
            $Batch = PSOpenAI\Get-Batch -BatchId $BatchId @CommonParams
        }
        if (-not $BatchId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve batch id.'))
            return
        }

        if (-not $Force) {
            if ((-not $Batch.status) -or ($Batch.status -notin @('validating', 'in_progress', 'finalizing'))) {
                Write-Error -Exception ([System.InvalidOperationException]::new(('Cannot cancel batch with status "{0}".' -f $Batch.status)))
                return
            }
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$BatchId/cancel"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Post'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
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
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop | ParseBatchObject
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        # Wait for cancel
        if ($Wait) {
            Write-Verbose 'Waiting for a cancellation...'
            $Result = $Response | PSOpenAI\Wait-Batch -StatusForExit ('cancelled', 'completed', 'failed', 'expired') @CommonParams
            if ($null -ne $Result -and $PassThru) {
                Write-Output $Result
            }
        }
        else {
            #region Output
            # No output on default
            if ($PassThru) {
                $Response
            }
            #endregion
        }
    }

    end {

    }
}