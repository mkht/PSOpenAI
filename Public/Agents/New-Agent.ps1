function New-Agent {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, Position = 0)] [System.Collections.IDictionary]$Body,
        [int]$TimeoutSec = 0, [ValidateRange(0, 100)] [int]$MaxRetryCount = 0,
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI, [System.Uri]$ApiBase,
        [Parameter(DontShow)] [string]$ApiVersion,
        [ValidateSet('openai', 'azure', 'azure_ad')] [string]$AuthType = 'openai',
        [securestring][SecureStringTransformation()]$ApiKey, [Alias('OrgId')] [string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery, [System.Collections.IDictionary]$AdditionalHeaders,
        [object]$AdditionalBody
    )
    process { Invoke-AgentApiRequest -EndpointName Agents -Method Post -Parameters $PSBoundParameters -Body $Body -TypeName PSOpenAI.Agent }
}
