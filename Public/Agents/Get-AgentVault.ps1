function Get-AgentVault {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Vault', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Agent.Vault')]$Vault,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('id', 'vault_id')]
        [string][UrlEncodeTransformation()]$VaultId,

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
        if ($PSCmdlet.ParameterSetName -ceq 'List') {
            $Query = [ordered]@{
                status = $Status
                limit  = $Limit
                after  = $After
                order  = $Order
            }
            Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Method 'Get' -Parameters $PSBoundParameters -Query $Query -All:$All -TypeName 'PSOpenAI.Agent.Vault'
            return
        }

        $TargetVaultId = if ($PSCmdlet.ParameterSetName -ceq 'Vault') { $Vault.id } else { $VaultId }
        if ([string]::IsNullOrWhiteSpace([string]$TargetVaultId)) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve agent vault id.'))
            return
        }
        Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Path $TargetVaultId -Method 'Get' -Parameters $PSBoundParameters -TypeName 'PSOpenAI.Agent.Vault'
    }
}
