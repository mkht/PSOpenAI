function Get-AgentSessionArtifactContent {
    [CmdletBinding()] [OutputType([byte[]])]
    param(
        [Parameter(Mandatory,Position=0)] [Alias('session_id')] [string][UrlEncodeTransformation()]$SessionId,
        [Parameter(Mandatory,Position=1,ValueFromPipelineByPropertyName)] [Alias('artifact_id')] [string][UrlEncodeTransformation()]$ArtifactId,
        [string]$OutFile,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders
    )
    process { Invoke-AgentApiRequest -EndpointName Agent.Sessions -Path "$SessionId/artifacts/$ArtifactId/content" -Method Get -Parameters $PSBoundParameters -Binary -OutFile $OutFile }
}
