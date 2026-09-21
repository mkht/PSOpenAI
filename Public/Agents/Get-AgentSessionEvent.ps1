function Get-AgentSessionEvent {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
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
        [System.Collections.IDictionary]$AdditionalHeaders
    )

    process {
        Invoke-AgentApiRequest -EndpointName 'Agent.Sessions' -Path "$SessionId/events" -Method 'Get' -Parameters $PSBoundParameters -Stream
    }
}
