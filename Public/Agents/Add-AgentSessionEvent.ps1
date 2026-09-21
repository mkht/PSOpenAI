function Add-AgentSessionEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)] [Alias('session_id')] [string][UrlEncodeTransformation()]$SessionId,
        [Parameter(Mandatory,Position=1)] [ValidateNotNullOrEmpty()] [object[]]$Event,
        [string]$IdempotencyKey,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process {
        $Body=[ordered]@{events=@($Event)}
        $RequestParameters = @{} + $PSBoundParameters
        if($PSBoundParameters.ContainsKey('IdempotencyKey')){
            $Headers = @{'Idempotency-Key' = $IdempotencyKey}
            if($null -ne $AdditionalHeaders){ $Headers = Merge-Dictionary $Headers $AdditionalHeaders }
            $RequestParameters.AdditionalHeaders = $Headers
        }
        Invoke-AgentApiRequest -EndpointName Agent.Sessions -Path "$SessionId/events" -Method Post -Parameters $RequestParameters -Body $Body
    }
}
