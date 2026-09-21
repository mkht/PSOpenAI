function Get-AgentSessionTurn {
    [CmdletBinding(DefaultParameterSetName = 'SessionList')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('session_id')]
        [string][UrlEncodeTransformation()]$SessionId,

        [Parameter(ParameterSetName = 'SubagentList', Mandatory)]
        [Parameter(ParameterSetName = 'SubagentId', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('subagent_id')]
        [string][UrlEncodeTransformation()]$SubagentId,

        [Parameter(ParameterSetName = 'SessionId', Mandatory, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'SubagentId', Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'turn_id')]
        [string][UrlEncodeTransformation()]$TurnId,

        [Parameter(ParameterSetName = 'SessionList')]
        [Parameter(ParameterSetName = 'SubagentList')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'SessionList')]
        [Parameter(ParameterSetName = 'SubagentList')]
        [switch]$All,

        [Parameter(ParameterSetName = 'SessionList')]
        [Parameter(ParameterSetName = 'SubagentList')]
        [string]$After,

        [Parameter(ParameterSetName = 'SessionList')]
        [Parameter(ParameterSetName = 'SubagentList')]
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
        $BasePath = if ($PSCmdlet.ParameterSetName -like 'Subagent*') {
            "$SessionId/subagents/$SubagentId/turns"
        }
        else {
            "$SessionId/turns"
        }

        if ($PSCmdlet.ParameterSetName -like '*Id') {
            Invoke-AgentApiRequest -EndpointName 'Agent.Sessions' -Path "$BasePath/$TurnId" -Method 'Get' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.Session.Turn'
            return
        }

        $Query = [ordered]@{
            limit = $Limit
            after = $After
            order = $Order
        }
        Invoke-AgentApiRequest -EndpointName 'Agent.Sessions' -Path $BasePath -Method 'Get' -Parameters $PSBoundParameters -Query $Query -All:$All -TypeName 'PSOpenAI.Agent.Session.Turn'
    }
}
