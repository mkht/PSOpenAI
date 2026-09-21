function Remove-AgentVault {
    [CmdletBinding(DefaultParameterSetName = 'Id', SupportsShouldProcess, ConfirmImpact = 'High')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Vault', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Agent.Vault')]$Vault,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'vault_id')]
        [string][UrlEncodeTransformation()]$VaultId,

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
        $TargetVaultId = if ($PSCmdlet.ParameterSetName -ceq 'Vault') { $Vault.id } else { $VaultId }
        if ([string]::IsNullOrWhiteSpace([string]$TargetVaultId)) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve agent vault id.'))
            return
        }
        if ($PSCmdlet.ShouldProcess($TargetVaultId, 'Delete agent vault')) {
            Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Path $TargetVaultId -Method 'Delete' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.Vault.Deleted'
        }
    }
}
