function Remove-AgentSession {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)] [Alias('session_id')] [string][UrlEncodeTransformation()]$SessionId,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process { if($PSCmdlet.ShouldProcess($SessionId,'Delete agent session')){ Invoke-AgentApiRequest -EndpointName Agent.Sessions -Path $SessionId -Method Delete -Parameters $PSBoundParameters -TypeName PSOpenAI.Agent.Session.Deleted } }
}
