function Get-AgentEnvironment {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)] [Alias('environment_id')] [string][UrlEncodeTransformation()]$EnvironmentId,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process { Invoke-AgentApiRequest -EndpointName Agent.Environments -Path $EnvironmentId -Method Get -Parameters $PSBoundParameters -TypeName PSOpenAI.Agent.Environment }
}
