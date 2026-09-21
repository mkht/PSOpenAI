function Get-AgentEnvironmentTemplate {
    [CmdletBinding(DefaultParameterSetName='List')] [OutputType([pscustomobject])]
    param(
        [Parameter(ParameterSetName='Get', Mandatory, Position=0, ValueFromPipelineByPropertyName)] [Alias('environment_template_id')] [string][UrlEncodeTransformation()]$EnvironmentTemplateId,
        [Parameter(ParameterSetName='List')] [ValidateRange(1,100)] [int]$Limit = 20, [Parameter(ParameterSetName='List')] [switch]$All,
        [Parameter(ParameterSetName='List')] [string]$After, [Parameter(ParameterSetName='List')] [ValidateSet('asc','desc')] [string]$Order = 'desc',
        [int]$TimeoutSec = 0, [ValidateRange(0,100)] [int]$MaxRetryCount = 0, [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase, [Parameter(DontShow)] [string]$ApiVersion, [ValidateSet('openai','azure','azure_ad')] [string]$AuthType = 'openai',
        [securestring][SecureStringTransformation()]$ApiKey, [Alias('OrgId')] [string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery, [System.Collections.IDictionary]$AdditionalHeaders, [object]$AdditionalBody
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Get') { Invoke-AgentApiRequest -EndpointName Agent.Environments -Path "templates/$EnvironmentTemplateId" -Method Get -Parameters $PSBoundParameters -TypeName PSOpenAI.Agent.EnvironmentTemplate }
        else { Invoke-AgentApiRequest -EndpointName Agent.Environments -Path templates -Method Get -Parameters $PSBoundParameters -Query ([ordered]@{limit=$Limit;after=$After;order=$Order}) -All:$All -TypeName PSOpenAI.Agent.EnvironmentTemplate }
    }
}
