function New-AgentVault {
    [CmdletBinding(DefaultParameterSetName = 'Properties')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Properties')]
        [ValidateLength(1, 256)]
        [string]$Name,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Metadata,

        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Body')]
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
        if ($PSCmdlet.ParameterSetName -eq 'Body') {
            $PostBody = $Body
        }
        else {
            $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
            if ($PSBoundParameters.ContainsKey('Name')) {
                $PostBody.name = $Name
            }
            if ($PSBoundParameters.ContainsKey('Metadata')) {
                $PostBody.metadata = $Metadata
            }
        }

        Invoke-AgentApiRequest -EndpointName 'Agent.Vaults' -Method Post -Parameters $PSBoundParameters -Body $PostBody -TypeName 'PSOpenAI.Agent.Vault'
    }
}
