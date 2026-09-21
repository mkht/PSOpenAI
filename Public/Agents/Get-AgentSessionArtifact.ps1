function Get-AgentSessionArtifact {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('session_id')]
        [string][UrlEncodeTransformation()]$SessionId,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'artifact_id')]
        [string][UrlEncodeTransformation()]$ArtifactId,

        [Parameter(ParameterSetName = 'List')]
        [Alias('environment_id')]
        [string]$EnvironmentId,

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
        if ($PSCmdlet.ParameterSetName -ceq 'Id') {
            Invoke-AgentApiRequest -EndpointName 'Agent.Sessions' -Path "$SessionId/artifacts/$ArtifactId" -Method 'Get' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.Session.Artifact'
            return
        }

        $Query = [ordered]@{
            environment_id = $EnvironmentId
            limit          = $Limit
            after          = $After
            order          = $Order
        }
        Invoke-AgentApiRequest -EndpointName 'Agent.Sessions' -Path "$SessionId/artifacts" -Method 'Get' -Parameters $PSBoundParameters -Query $Query -All:$All -TypeName 'PSOpenAI.Agent.Session.Artifact'
    }
}
