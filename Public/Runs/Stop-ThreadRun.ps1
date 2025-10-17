function Stop-ThreadRun {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Run', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backward compatibility
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('run_id')]
        [string][UrlEncodeTransformation()]$RunId,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Runs' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -ceq 'Run') {
            $ThreadId = $Run.thread_id
            $RunId = $Run.id
        }
        else {
            $Run = PSOpenAI\Get-ThreadRun -RunId $RunId -ThreadId $ThreadId @CommonParams
        }
        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
            return
        }
        if (-not $RunId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Run ID.'))
            return
        }

        if (-not $Force) {
            if ((-not $Run.status) -or ($Run.status -notin @('queued', 'in_progress', 'requires_action'))) {
                Write-Error -Exception ([System.InvalidOperationException]::new(('Cannot cancel run with status "{0}".' -f $Run.status)))
                return
            }
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new(($OpenAIParameter.Uri -f $ThreadId))
        $UriBuilder.Path += "/$RunId/cancel"
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

        Write-Verbose 'Requested to cancel run.'

        #region Parse response object
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop | ParseThreadRunObject
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
                $Response
            }
            #endregion
        }
    }

    end {

    }
}