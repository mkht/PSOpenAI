function Get-AgentVaultCredential {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('vault_id')]
        [string][UrlEncodeTransformation()]$VaultId,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'credential_id')]
        [string][UrlEncodeTransformation()]$CredentialId,

        [Parameter(ParameterSetName = 'List')]
        [ValidateSet('active', 'archived')]
        [string[]]$Status,

        [Parameter(ParameterSetName = 'List')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'List')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List')]
        [string]$After,

        [Parameter(ParameterSetName = 'List')]
        [ValidateSet('asc', 'desc')]
        [string]$Order = 'desc',

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
        if ($PSCmdlet.ParameterSetName -ceq 'Id') {
            Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Path "$VaultId/credentials/$CredentialId" -Method 'Get' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.Vault.Credential'
            return
        }

        $Query = [ordered]@{
            status = $Status
            limit  = $Limit
            after  = $After
            order  = $Order
        }
        Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Path "$VaultId/credentials" -Method 'Get' -Parameters $PSBoundParameters -Query $Query -All:$All -TypeName 'PSOpenAI.Agent.Vault.Credential'
    }
}
