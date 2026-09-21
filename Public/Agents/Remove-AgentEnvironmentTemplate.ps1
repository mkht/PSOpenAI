function Remove-AgentEnvironmentTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Id', SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Template', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Agent.EnvironmentTemplate')]$EnvironmentTemplate,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'environment_template_id')]
        [string][UrlEncodeTransformation()]$EnvironmentTemplateId,

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
        $TargetTemplateId = if ($PSCmdlet.ParameterSetName -ceq 'Template') { $EnvironmentTemplate.id } else { $EnvironmentTemplateId }
        if ([string]::IsNullOrWhiteSpace([string]$TargetTemplateId)) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve agent environment template id.'))
            return
        }
        if ($PSCmdlet.ShouldProcess($TargetTemplateId, 'Delete agent environment template')) {
            Invoke-AgentApiRequest -EndpointName 'Agent.Environments' -Path "templates/$TargetTemplateId" -Method 'Delete' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.EnvironmentTemplate.Deleted'
        }
    }
}
