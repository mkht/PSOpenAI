function New-AgentEnvironmentTemplate {
    [CmdletBinding(DefaultParameterSetName = 'Properties')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Properties')]
        [ValidateLength(1, 256)]
        [string]$Name,

        [Parameter(ParameterSetName = 'Properties')]
        [Alias('capability_directories')]
        [string[]]$CapabilityDirectory,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Env,

        [Parameter(ParameterSetName = 'Properties')]
        [Alias('files')]
        [System.Collections.IDictionary[]]$File,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Network,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Packages,

        [Parameter(ParameterSetName = 'Properties')]
        [Alias('plugins')]
        [System.Collections.IDictionary[]]$Plugin,

        [Parameter(ParameterSetName = 'Properties')]
        [Alias('skills')]
        [System.Collections.IDictionary[]]$Skill,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary[]]$Setup,

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
            if ($PSBoundParameters.ContainsKey('CapabilityDirectory')) {
                $PostBody.capability_directories = $CapabilityDirectory
            }
            if ($PSBoundParameters.ContainsKey('Env')) {
                $PostBody.env = $Env
            }
            if ($PSBoundParameters.ContainsKey('File')) {
                $PostBody.files = $File
            }
            if ($PSBoundParameters.ContainsKey('Network')) {
                $PostBody.network = $Network
            }
            if ($PSBoundParameters.ContainsKey('Packages')) {
                $PostBody.packages = $Packages
            }
            if ($PSBoundParameters.ContainsKey('Plugin')) {
                $PostBody.plugins = $Plugin
            }
            if ($PSBoundParameters.ContainsKey('Skill')) {
                $PostBody.skills = $Skill
            }
            if ($PSBoundParameters.ContainsKey('Setup')) {
                $PostBody.setup_commands = $Setup
            }
        }

        Invoke-AgentApiRequest -EndpointName 'Agent.Environments' -Path 'templates' -Method Post -Parameters $PSBoundParameters -Body $PostBody -TypeName 'PSOpenAI.Agent.EnvironmentTemplate'
    }
}
