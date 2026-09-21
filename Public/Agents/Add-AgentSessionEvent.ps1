function Add-AgentSessionEvent {
    [CmdletBinding(DefaultParameterSetName = 'Event')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('id', 'session_id')]
        [string][UrlEncodeTransformation()]$SessionId,

        [Parameter(ParameterSetName = 'Event', Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Event,

        [Parameter(ParameterSetName = 'Message', Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(ParameterSetName = 'Message')]
        [ValidateSet('user')]
        [string]$Role = 'user',

        [Parameter()]
        [string]$IdempotencyKey,

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
        if ($PSCmdlet.ParameterSetName -eq 'Message') {
            $InputMessage = [ordered]@{
                type    = 'message'
                role    = $Role
                content = @(
                    [ordered]@{
                        type = 'input_text'
                        text = $Message
                    }
                )
            }
            $Events = @(
                [ordered]@{
                    type  = 'agent.session.input.message'
                    input = @($InputMessage)
                }
            )
        }
        else {
            $Events = @($Event)
        }

        $RequestBody = [ordered]@{
            events = $Events
        }
        $RequestParameters = @{} + $PSBoundParameters

        if ($PSBoundParameters.ContainsKey('IdempotencyKey')) {
            $Headers = @{
                'Idempotency-Key' = $IdempotencyKey
            }
            if ($null -ne $AdditionalHeaders) {
                $Headers = Merge-Dictionary $Headers $AdditionalHeaders
            }
            $RequestParameters.AdditionalHeaders = $Headers
        }

        Invoke-AgentApiRequest `
            -EndpointName 'Agent.Sessions' `
            -Path "$SessionId/events" `
            -Method 'Post' `
            -Parameters $RequestParameters `
            -Body $RequestBody
    }
}
