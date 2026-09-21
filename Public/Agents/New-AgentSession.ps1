function New-AgentSession {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0)] [System.Collections.IDictionary]$Body, [switch]$Stream,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process {
        $RequestBody = [ordered]@{}
        foreach($Entry in $Body.GetEnumerator()){ $RequestBody[$Entry.Key] = $Entry.Value }
        if($Stream){ $RequestBody.stream = $true }
        Invoke-AgentApiRequest -EndpointName Agent.Sessions -Method Post -Parameters $PSBoundParameters -Body $RequestBody -Stream:$Stream -TypeName PSOpenAI.Agent.Session
    }
}
