function Remove-Agent {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)] [Alias('agent_id')] [string][UrlEncodeTransformation()]$AgentId,
        [int]$TimeoutSec = 0, [ValidateRange(0, 100)] [int]$MaxRetryCount = 0, [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase, [Parameter(DontShow)] [string]$ApiVersion, [ValidateSet('openai', 'azure', 'azure_ad')] [string]$AuthType = 'openai',
        [securestring][SecureStringTransformation()]$ApiKey, [Alias('OrgId')] [string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery, [System.Collections.IDictionary]$AdditionalHeaders, [object]$AdditionalBody
    )
    process { if ($PSCmdlet.ShouldProcess($AgentId, 'Delete agent')) { Invoke-AgentApiRequest -EndpointName Agents -Path $AgentId -Method Delete -Parameters $PSBoundParameters -TypeName PSOpenAI.Agent.Deleted } }
}
