function Get-AgentVaultCredential {
    [CmdletBinding()] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0)] [Alias('vault_id')] [string][UrlEncodeTransformation()]$VaultId,
        [string][UrlEncodeTransformation()]$CredentialId,[ValidateSet('active','archived')][string[]]$Status,
        [ValidateRange(1,100)][int]$Limit=20,[switch]$All,[string]$After,[ValidateSet('asc','desc')][string]$Order='desc',
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process{
        $Path=if($CredentialId){"$VaultId/credentials/$CredentialId"}else{"$VaultId/credentials"};$Query=if($CredentialId){$null}else{[ordered]@{status=$Status;limit=$Limit;after=$After;order=$Order}}
        Invoke-AgentApiRequest -EndpointName Agent.Vaults -Path $Path -Method Get -Parameters $PSBoundParameters -Query $Query -All:($All -and -not $CredentialId) -TypeName PSOpenAI.Agent.Vault.Credential
    }
}
