function Remove-AgentVault {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')] [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory,Position=0,ValueFromPipelineByPropertyName)] [Alias('vault_id')] [string][UrlEncodeTransformation()]$VaultId,
        [int]$TimeoutSec=0,[ValidateRange(0,100)][int]$MaxRetryCount=0,[OpenAIApiType]$ApiType=[OpenAIApiType]::OpenAI,
        [System.Uri]$ApiBase,[Parameter(DontShow)][string]$ApiVersion,[ValidateSet('openai','azure','azure_ad')][string]$AuthType='openai',
        [securestring][SecureStringTransformation()]$ApiKey,[Alias('OrgId')][string]$Organization,
        [System.Collections.IDictionary]$AdditionalQuery,[System.Collections.IDictionary]$AdditionalHeaders,[object]$AdditionalBody
    )
    process {if($PSCmdlet.ShouldProcess($VaultId,'Delete agent vault')){Invoke-AgentApiRequest -EndpointName Agent.Vaults -Path $VaultId -Method Delete -Parameters $PSBoundParameters -TypeName PSOpenAI.Agent.Vault.Deleted}}
}
