function Get-AgentSessionItem {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0)] [Alias('session_id')] [string][UrlEncodeTransformation()]$SessionId,
        [string][UrlEncodeTransformation()]$SubagentId, [string][UrlEncodeTransformation()]$TurnId,
        [ValidateRange(1,100)] [int]$Limit=20, [switch]$All, [string]$After, [ValidateSet('asc','desc')] [string]$Order='asc',
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process {
        if($TurnId -and -not $SubagentId){ throw [System.ArgumentException]::new('TurnId requires SubagentId.') }
        $Path=if($TurnId){"$SessionId/subagents/$SubagentId/turns/$TurnId/items"}elseif($SubagentId){"$SessionId/subagents/$SubagentId/items"}else{"$SessionId/items"}
        Invoke-AgentApiRequest -EndpointName Agent.Sessions -Path $Path -Method Get -Parameters $PSBoundParameters -Query ([ordered]@{limit=$Limit;after=$After;order=$Order}) -All:$All -TypeName PSOpenAI.Agent.Session.Item
    }
}
