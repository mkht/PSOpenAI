function Get-AgentEnvironmentFile {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('environment_id')]
        [string][UrlEncodeTransformation()]$EnvironmentId,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]$Order = 'asc',

        [Parameter()]
        [string]$Page,

        [Parameter()]
        [string]$Path,

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
        $Query = [ordered]@{
            limit = $Limit
            order = $Order
            page  = $Page
            path  = $Path
        }
        Invoke-AgentApiRequest -EndpointName 'Agent.Environments' -Path "$EnvironmentId/files" -Method 'Get' -Parameters $PSBoundParameters -Query $Query -TypeName 'PSOpenAI.Agent.EnvironmentFile'
    }
}
