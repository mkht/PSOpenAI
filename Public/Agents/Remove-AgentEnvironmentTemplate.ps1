function Remove-AgentEnvironmentTemplate {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)] [Alias('environment_template_id')] [string][UrlEncodeTransformation()]$EnvironmentTemplateId,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process { if ($PSCmdlet.ShouldProcess($EnvironmentTemplateId,'Delete agent environment template')) { Invoke-AgentApiRequest -EndpointName Agent.Environments -Path "templates/$EnvironmentTemplateId" -Method Delete -Parameters $PSBoundParameters -TypeName PSOpenAI.Agent.EnvironmentTemplate.Deleted } }
}
