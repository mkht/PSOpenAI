function Set-AgentSession {
    [CmdletBinding(DefaultParameterSetName = 'Properties', SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id', 'session_id')]
        [string][UrlEncodeTransformation()]$SessionId,

        [Parameter(ParameterSetName = 'Properties')]
        [ValidateNotNull()]
        [object]$Agent,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Collections.IDictionary]$Metadata,

        [Parameter(ParameterSetName = 'Raw', Mandatory, Position = 1)]
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

            if ($PSBoundParameters.ContainsKey('Agent')) {
                $RequestBody.agent = $Agent
            }
            if ($PSBoundParameters.ContainsKey('Metadata')) {
                $RequestBody.metadata = $Metadata
            }
        }

        if ($PSCmdlet.ShouldProcess($SessionId, 'Update agent session')) {
            Invoke-AgentApiRequest `
                -EndpointName 'Agent.Sessions' `
                -Path $SessionId `
                -Method 'Post' `
                -Parameters $PSBoundParameters `
                -Body $RequestBody `
                -TypeName 'PSOpenAI.Agent.Session'
        }
    }
}
