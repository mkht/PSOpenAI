function Set-AgentVaultCredential {
    [CmdletBinding(DefaultParameterSetName = 'StaticBearer', SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('vault_id')]
        [string][UrlEncodeTransformation()]$VaultId,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('credential_id')]
        [string][UrlEncodeTransformation()]$CredentialId,

        [Parameter(Mandatory, Position = 2, ParameterSetName = 'StaticBearer')]
        [securestring][SecureStringTransformation()]$Token,

        [Parameter(Mandatory, Position = 2, ParameterSetName = 'EnvironmentVariable')]
        [securestring][SecureStringTransformation()]$SecretValue,

        [Parameter(Mandatory, Position = 2, ParameterSetName = 'Auth')]
        [System.Collections.IDictionary]$Auth,

        [Parameter(Mandatory, Position = 2, ParameterSetName = 'Body')]
        [System.Collections.IDictionary]$Body,

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
        if (-not $PSCmdlet.ShouldProcess($CredentialId, 'Rotate agent vault credential')) {
            return
        }

        $SecretPointer = [System.IntPtr]::Zero
        $PlainSecret = $null
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'Body' {
                    $PostBody = $Body
                }
                'Auth' {
                    $PostBody = [ordered]@{ auth = $Auth }
                }
                'StaticBearer' {
                    $SecretPointer = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token)
                    $PlainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecretPointer)
                    $PostBody = [ordered]@{
                        auth = [ordered]@{
                            type  = 'static_bearer'
                            token = $PlainSecret
                        }
                    }
                }
                'EnvironmentVariable' {
                    $SecretPointer = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecretValue)
                    $PlainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecretPointer)
                    $PostBody = [ordered]@{
                        auth = [ordered]@{
                            type         = 'environment_variable'
                            secret_value = $PlainSecret
                        }
                    }
                }
            }

            Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Path "$VaultId/credentials/$CredentialId" -Method Post -Parameters $PSBoundParameters -Body $PostBody -TypeName 'PSOpenAI.Agent.Vault.Credential'
        }
        finally {
            if ($SecretPointer -ne [System.IntPtr]::Zero) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($SecretPointer)
            }
            $SecretPointer = [System.IntPtr]::Zero
            $PlainSecret = $PostBody = $null
        }
    }
}
