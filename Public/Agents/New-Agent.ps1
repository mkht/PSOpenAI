function New-Agent {
    [CmdletBinding(DefaultParameterSetName = 'Properties')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Properties', Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Model,

        [Parameter(ParameterSetName = 'Properties')]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Properties')]
        [AllowEmptyString()]
        [string]$Instructions,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Metadata,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$MultiAgent,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Reasoning,

        [Parameter(ParameterSetName = 'Properties')]
        [Completions('auto', 'default', 'flex', 'priority', 'fast')]
        [string]$ServiceTier,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Text,

        [Parameter(ParameterSetName = 'Properties')]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Tool,

        [Parameter(ParameterSetName = 'Raw', Mandatory, Position = 0)]
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
        if ($PSCmdlet.ParameterSetName -eq 'Raw') {
            $RequestBody = $Body
        }
        else {
            $RequestBody = [System.Collections.Specialized.OrderedDictionary]::new()
            $RequestBody.model = $Model

            if ($PSBoundParameters.ContainsKey('Name')) {
                $RequestBody.name = $Name
            }
            if ($PSBoundParameters.ContainsKey('Instructions')) {
                $RequestBody.instructions = $Instructions
            }
            if ($PSBoundParameters.ContainsKey('Metadata')) {
                $RequestBody.metadata = $Metadata
            }
            if ($PSBoundParameters.ContainsKey('MultiAgent')) {
                $RequestBody.multi_agent = $MultiAgent
            }
            if ($PSBoundParameters.ContainsKey('Reasoning')) {
                $RequestBody.reasoning = $Reasoning
            }
            if ($PSBoundParameters.ContainsKey('ServiceTier')) {
                $RequestBody.service_tier = $ServiceTier
            }
            if ($PSBoundParameters.ContainsKey('Text')) {
                $RequestBody.text = $Text
            }
            if ($PSBoundParameters.ContainsKey('Tool')) {
                $RequestBody.tools = @($Tool)
            }
        }

        Invoke-AgentApiRequest `
            -EndpointName 'Agents' `
            -Method 'Post' `
            -Parameters $PSBoundParameters `
            -Body $RequestBody `
            -TypeName 'PSOpenAI.Agent'
    }
}
