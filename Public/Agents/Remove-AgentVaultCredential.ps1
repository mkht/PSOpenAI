function Remove-AgentVaultCredential {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('vault_id')]
        [string][UrlEncodeTransformation()]$VaultId,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'credential_id')]
        [string][UrlEncodeTransformation()]$CredentialId,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    process {
        if ($PSCmdlet.ShouldProcess($CredentialId, 'Delete agent vault credential')) {
            Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Path "$VaultId/credentials/$CredentialId" -Method 'Delete' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.Vault.Credential.Deleted'
        }
    }
}
