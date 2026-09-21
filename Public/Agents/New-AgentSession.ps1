function New-AgentSession {
    [CmdletBinding(DefaultParameterSetName = 'Properties')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Properties', Position = 0)]
        [ValidateNotNull()]
        [System.Collections.IDictionary]$Environment,

        [Parameter(ParameterSetName = 'Properties')]
        [Alias('environment_template_id')]
        [ValidateNotNullOrEmpty()]
        [string]$EnvironmentTemplateId,

        [Parameter(ParameterSetName = 'Properties', ValueFromPipeline)]
        [ValidateNotNull()]
        [object]$Agent,

        [Parameter(ParameterSetName = 'Properties')]
        [Alias('agent_id')]
        [ValidateNotNullOrEmpty()]
        [string]$AgentId,

        [Parameter(ParameterSetName = 'Properties')]
        [ValidateNotNull()]
        [object]$Input,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Metadata,

        [Parameter(ParameterSetName = 'Properties')]
        [Alias('vault_ids')]
        [ValidateNotNullOrEmpty()]
        [string[]]$VaultId,

        [Parameter(ParameterSetName = 'Raw', Mandatory, Position = 0)]
        [System.Collections.IDictionary]$Body,

        [Parameter()]
        [switch]$Stream,

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
        $RequestBody = [System.Collections.Specialized.OrderedDictionary]::new()

        if ($PSCmdlet.ParameterSetName -eq 'Raw') {
            foreach ($Entry in $Body.GetEnumerator()) {
                $RequestBody[$Entry.Key] = $Entry.Value
            }
        }
        else {
            if ($PSBoundParameters.ContainsKey('Environment') -and
                $PSBoundParameters.ContainsKey('EnvironmentTemplateId')) {
                throw [System.ArgumentException]::new(
                    'Environment and EnvironmentTemplateId cannot be specified together.'
                )
            }

            if ($PSBoundParameters.ContainsKey('EnvironmentTemplateId')) {
                $RequestBody.environment = [ordered]@{
                    type                    = 'openai_hosted'
                    environment_template_id = $EnvironmentTemplateId
                }
            }
            elseif ($PSBoundParameters.ContainsKey('Environment')) {
                $RequestBody.environment = $Environment
            }
            else {
                $RequestBody.environment = [ordered]@{type = 'none' }
            }

            if ($PSBoundParameters.ContainsKey('Agent') -and $PSBoundParameters.ContainsKey('AgentId')) {
                throw [System.ArgumentException]::new('Agent and AgentId cannot be specified together.')
            }

            if ($PSBoundParameters.ContainsKey('Agent')) {
                $IsSavedAgent = $Agent.psobject.TypeNames -contains 'PSOpenAI.Agent'
                if ($IsSavedAgent -and -not [string]::IsNullOrWhiteSpace([string]$Agent.id)) {
                    $RequestBody.agent_id = [string]$Agent.id
                }
                elseif ($Agent -is [string]) {
                    $RequestBody.agent_id = [string]$Agent
                }
                else {
                    $RequestBody.agent = $Agent
                }
            }
            elseif ($PSBoundParameters.ContainsKey('AgentId')) {
                $RequestBody.agent_id = $AgentId
            }

            if ($PSBoundParameters.ContainsKey('Input')) {
                # $input is an automatic PowerShell variable in pipeline blocks.
                $RequestBody.input = $PSBoundParameters['Input']
            }
            if ($PSBoundParameters.ContainsKey('Metadata')) {
                $RequestBody.metadata = $Metadata
            }
            if ($PSBoundParameters.ContainsKey('VaultId')) {
                $RequestBody.vault_ids = @($VaultId)
            }
        }

        if ($Stream) {
            $RequestBody.stream = $true
        }

        Invoke-AgentApiRequest `
            -EndpointName 'Agent.Sessions' `
            -Method 'Post' `
            -Parameters $PSBoundParameters `
            -Body $RequestBody `
            -Stream:$Stream `
            -TypeName 'PSOpenAI.Agent.Session'
    }
}
