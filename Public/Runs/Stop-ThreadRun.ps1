function Stop-ThreadRun {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ ([string]$_.id).StartsWith('run_', [StringComparison]::Ordinal) -and ([string]$_.thread_id).StartsWith('thread_', [StringComparison]::Ordinal) })]
        [Alias('Run')]
        [Object]$InputObject,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter(DontShow = $true)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow = $true)]
        [string]$ApiVersion,

        [Parameter(DontShow = $true)]
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
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Runs' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Runs' -ApiBase $ApiBase
        }

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        [string][UrlEncodeTransformation()]$ThreadId = $InputObject.thread_id
        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
            return
        }
        [string][UrlEncodeTransformation()]$RunId = $InputObject.id
        if (-not $RunId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Run ID.'))
            return
        }

        if (-not $Force) {
            if ((-not $InputObject.status) -or ($InputObject.status -notin @('queued', 'in_progress', 'requires_action'))) {
                Write-Error -Exception ([System.InvalidOperationException]::new(('Cannot cancel run with status "{0}".' -f $InputObject.status)))
                return
            }
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$RunId/cancel"
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
            AuthType          = $AuthType
            Organization      = $Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v1' }
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        Invoke-OpenAIAPIRequest @param

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        Write-Verbose 'Requested to cancel run.'

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
            Write-Verbose 'Waiting for cancelled...'
            $Result = $Response | PSOpenAI\Wait-ThreadRun -StatusForExit ('cancelled', 'completed', 'failed', 'expired') @CommonParams
            if ($null -ne $Result -and $PassThru) {
                Write-Output $Result
            }
        }
        else {
            #region Output
            # No output on default
            if ($PassThru) {
                ParseThreadRunObject $Response -CommonParams $CommonParams
            }
            #endregion
        }
    }

    end {

    }
}