function Remove-AgentSession {
    [CmdletBinding(DefaultParameterSetName = 'Id', SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Session', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Agent.Session')]$Session,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'session_id')]
        [string][UrlEncodeTransformation()]$SessionId,

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

    process {
        $TargetSessionId = if ($PSCmdlet.ParameterSetName -ceq 'Session') { $Session.id } else { $SessionId }
        if ([string]::IsNullOrWhiteSpace([string]$TargetSessionId)) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve agent session id.'))
            return
        }
        if ($PSCmdlet.ShouldProcess($TargetSessionId, 'Delete agent session')) {
            Invoke-AgentApiRequest -EndpointName 'Agent.Sessions' -Path $TargetSessionId -Method 'Delete' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.Session.Deleted'
        }
    }
}
