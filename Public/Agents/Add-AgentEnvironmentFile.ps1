function Add-AgentEnvironmentFile {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)] [Alias('environment_id')] [string][UrlEncodeTransformation()]$EnvironmentId,
        [Parameter(Mandatory,Position=1)] [System.Collections.IDictionary]$Body,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process { Invoke-AgentApiRequest -EndpointName Agent.Environments -Path "$EnvironmentId/files" -Method Post -Parameters $PSBoundParameters -Body $Body -TypeName PSOpenAI.Agent.EnvironmentFile }
}
