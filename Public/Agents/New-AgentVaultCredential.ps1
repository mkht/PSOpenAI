function New-AgentVaultCredential {
    [CmdletBinding(DefaultParameterSetName = 'StaticBearer')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id', 'vault_id')]
        [string][UrlEncodeTransformation()]$VaultId,

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'StaticBearer')]
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'EnvironmentVariable')]
        [Parameter(Mandatory, Position = 1, ParameterSetName = 'Auth')]
        [ValidateLength(1, 256)]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'StaticBearer')]
        [securestring][SecureStringTransformation()]$Token,

        [Parameter(Mandatory, ParameterSetName = 'StaticBearer')]
        [ValidateScript({ $_.IsAbsoluteUri -and $_.Scheme -eq 'https' })]
        [System.Uri]$McpServerUrl,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentVariable')]
        [ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')]
        [string]$SecretName,

        [Parameter(Mandatory, ParameterSetName = 'EnvironmentVariable')]
        [securestring][SecureStringTransformation()]$SecretValue,

        [Parameter(ParameterSetName = 'EnvironmentVariable')]
        [ValidateCount(1, 16)]
        [string[]]$AllowedHost,

        [Parameter(Mandatory, ParameterSetName = 'Auth')]
        [System.Collections.IDictionary]$Auth,

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'Body')]
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
        $SecretPointer = [System.IntPtr]::Zero
        $PlainSecret = $null
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'Body' {
                    $PostBody = $Body
                }
                'Auth' {
                    $PostBody = [ordered]@{
                        name = $Name
                        auth = $Auth
                    }
                }
                'StaticBearer' {
                    $SecretPointer = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token)
                    $PlainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecretPointer)
                    $PostBody = [ordered]@{
                        name = $Name
                        auth = [ordered]@{
                            type           = 'static_bearer'
                            token          = $PlainSecret
                            mcp_server_url = $McpServerUrl.AbsoluteUri
                        }
                    }
                }
                'EnvironmentVariable' {
                    $SecretPointer = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecretValue)
                    $PlainSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($SecretPointer)
                    $Networking = if ($PSBoundParameters.ContainsKey('AllowedHost')) {
                        [ordered]@{
                            type          = 'limited'
                            allowed_hosts = $AllowedHost
                        }
                    }
                    else {
                        [ordered]@{ type = 'unrestricted' }
                    }
                    $PostBody = [ordered]@{
                        name = $Name
                        auth = [ordered]@{
                            type         = 'environment_variable'
                            secret_name  = $SecretName
                            secret_value = $PlainSecret
                            networking   = $Networking
                        }
                    }
                }
            }

            Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Path "$VaultId/credentials" -Method Post -Parameters $PSBoundParameters -Body $PostBody -TypeName 'PSOpenAI.Agent.Vault.Credential'
        }
        finally {
            if ($SecretPointer -ne [System.IntPtr]::Zero) {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($SecretPointer)
            }
            $SecretPointer = [System.IntPtr]::Zero
            $PlainSecret = $PostBody = $Networking = $null
        }
    }
}
