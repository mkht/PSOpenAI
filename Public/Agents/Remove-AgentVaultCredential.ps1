function Remove-AgentVaultCredential {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0)] [Alias('vault_id')] [string][UrlEncodeTransformation()]$VaultId,
        [Parameter(Mandatory,Position=1,ValueFromPipelineByPropertyName)] [Alias('credential_id')] [string][UrlEncodeTransformation()]$CredentialId,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process{if($PSCmdlet.ShouldProcess($CredentialId,'Delete agent vault credential')){Invoke-AgentApiRequest -EndpointName Agent.Vaults -Path "$VaultId/credentials/$CredentialId" -Method Delete -Parameters $PSBoundParameters -TypeName PSOpenAI.Agent.Vault.Credential.Deleted}}
}
