function New-AgentVaultCredential {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0)] [Alias('vault_id')] [string][UrlEncodeTransformation()]$VaultId,
        [Parameter(Mandatory,Position=1)] [System.Collections.IDictionary]$Body,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process{Invoke-AgentApiRequest -EndpointName Agent.Vaults -Path "$VaultId/credentials" -Method Post -Parameters $PSBoundParameters -Body $Body -TypeName PSOpenAI.Agent.Vault.Credential}
}
