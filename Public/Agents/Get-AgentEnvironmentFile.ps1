function Get-AgentEnvironmentFile {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)] [Alias('environment_id')] [string][UrlEncodeTransformation()]$EnvironmentId,
        [ValidateRange(1,100)] [int]$Limit=20, [ValidateSet('asc','desc')] [string]$Order='asc', [string]$Page, [string]$Path,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process { Invoke-AgentApiRequest -EndpointName Agent.Environments -Path "$EnvironmentId/files" -Method Get -Parameters $PSBoundParameters -Query ([ordered]@{limit=$Limit;order=$Order;page=$Page;path=$Path}) -TypeName PSOpenAI.Agent.EnvironmentFile }
}
