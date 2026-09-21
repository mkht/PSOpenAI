function Get-AgentEnvironment {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Environment', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Agent.Environment')]$Environment,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'environment_id')]
        [string][UrlEncodeTransformation()]$EnvironmentId,

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
        $TargetEnvironmentId = if ($PSCmdlet.ParameterSetName -ceq 'Environment') { $Environment.id } else { $EnvironmentId }
        if ([string]::IsNullOrWhiteSpace([string]$TargetEnvironmentId)) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve agent environment id.'))
            return
        }

        Invoke-AgentApiRequest -EndpointName 'Agent.Environments' -Path $TargetEnvironmentId -Method 'Get' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.Environment'
    }
}
