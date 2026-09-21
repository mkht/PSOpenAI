function Get-AgentSessionItem {
    [CmdletBinding(DefaultParameterSetName = 'Session')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'session_id')]
        [string][UrlEncodeTransformation()]$SessionId,

        [Parameter(ParameterSetName = 'Subagent', Mandatory)]
        [Parameter(ParameterSetName = 'Turn', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('subagent_id')]
        [string][UrlEncodeTransformation()]$SubagentId,

        [Parameter(ParameterSetName = 'Turn', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('turn_id')]
        [string][UrlEncodeTransformation()]$TurnId,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter()]
        [switch]$All,

        [Parameter()]
        [string]$After,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]$Order = 'asc',

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
        $Path = switch ($PSCmdlet.ParameterSetName) {
            'Turn' { "$SessionId/subagents/$SubagentId/turns/$TurnId/items" }
            'Subagent' { "$SessionId/subagents/$SubagentId/items" }
            default { "$SessionId/items" }
        }
        $Query = [ordered]@{
            limit = $Limit
            after = $After
            order = $Order
        }
        Invoke-AgentApiRequest -EndpointName 'Agent.Sessions' -Path $Path -Method 'Get' -Parameters $PSBoundParameters -Query $Query -All:$All -TypeName 'PSOpenAI.Agent.Session.Item'
    }
}
