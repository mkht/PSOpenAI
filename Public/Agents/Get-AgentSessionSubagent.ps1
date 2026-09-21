function Get-AgentSessionSubagent {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0)] [Alias('session_id')] [string][UrlEncodeTransformation()]$SessionId,
        [string][UrlEncodeTransformation()]$SubagentId,
        [ValidateRange(1,100)] [int]$Limit=20, [switch]$All, [string]$After, [ValidateSet('asc','desc')] [string]$Order='asc',
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process {
        $Path=if($SubagentId){"$SessionId/subagents/$SubagentId"}else{"$SessionId/subagents"}; $Query=if($SubagentId){$null}else{[ordered]@{limit=$Limit;after=$After;order=$Order}}
        Invoke-AgentApiRequest -EndpointName Agent.Sessions -Path $Path -Method Get -Parameters $PSBoundParameters -Query $Query -All:($All -and -not $SubagentId) -TypeName PSOpenAI.Agent.Session.Subagent
    }
}
