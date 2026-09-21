function Get-Agent {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Agent', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Agent')]$Agent,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'agent_id')]
        [string][UrlEncodeTransformation()]$AgentId,

        [Parameter(ParameterSetName = 'List')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'List')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List')]
        [string]$After,

        [Parameter(ParameterSetName = 'List')]
        [ValidateSet('asc', 'desc')]
        [string]$Order = 'desc',

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
        if ($PSCmdlet.ParameterSetName -ceq 'List') {
            $Query = [ordered]@{
                limit = $Limit
                after = $After
                order = $Order
            }
            Invoke-AgentApiRequest -EndpointName 'Agents' -Method 'Get' -Parameters $PSBoundParameters -Query $Query -All:$All -TypeName 'PSOpenAI.Agent'
            return
        }

        $TargetAgentId = if ($PSCmdlet.ParameterSetName -ceq 'Agent') { $Agent.id } else { $AgentId }
        if ([string]::IsNullOrWhiteSpace([string]$TargetAgentId)) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve agent id.'))
            return
        }
        Invoke-AgentApiRequest -EndpointName 'Agents' -Path $TargetAgentId -Method 'Get' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent'
    }
}
