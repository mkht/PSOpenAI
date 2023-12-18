function Request-AzureChatCompletion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Alias('Request-AzureChatGPT')]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Text')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('user', 'system', 'function')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter()]
        [ValidatePattern('^[a-zA-Z0-9_-]{1,64}$')]   # May contain a-z, A-Z, 0-9, hyphens, and underscores, with a maximum length of 64 characters.
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [Alias('Model')]
        [Alias('Engine')]
        [string]$Deployment,

        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [Alias('RolePrompt')]
        [string[]]$SystemMessage,

        # For GPT-4 Turbo with Vision
        [Parameter()]
        [string[]]$Images,

        [Parameter()]
        [ValidateSet('auto', 'low', 'high')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',

        #region Function call params
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Tools,

        # deprecated
        [Parameter(DontShow = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Functions,

        [Parameter()]
        [Alias('tool_choice')]
        [Completions('none', 'auto')]
        [object]$ToolChoice,

        # deprecated
        [Parameter(DontShow = $true)]
        [Alias('function_call')]
        [Completions('none', 'auto')]
        [object]$FunctionCall,

        [Parameter()]
        [Alias('InvokeFunctionOnCallMode')] # For backward compatibilty
        [ValidateSet('None', 'Auto', 'Confirm')]
        [string]$InvokeTools = 'None',

        # deprecated
        [Parameter(DontShow = $true)]
        [uint16]$MaxFunctionCallCount,
        #endregion Function call params

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [Alias('n')]
        [uint16]$NumberOfAnswers,

        [Parameter()]
        [switch]$Stream = $false,

        [Parameter()]
        [ValidateCount(1, 4)]
        [Alias('stop')]
        [string[]]$StopSequence,

        [Parameter()]
        [ValidateRange(0, 2147483647)]
        [Alias('max_tokens')]
        [int]$MaxTokens,

        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [Alias('presence_penalty')]
        [double]$PresencePenalty,

        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [Alias('frequency_penalty')]
        [double]$FrequencyPenalty,

        [Parameter()]
        [Alias('logit_bias')]
        [System.Collections.IDictionary]$LogitBias,

        [Parameter()]
        [Alias('response_format')]
        [ValidateSet('text', 'json_object', 'raw_response')]
        [string][LowerCaseTransformation()]$Format = 'text',

        [Parameter()]
        [int64]$Seed,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [string]$ApiVersion,

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [ValidateSet('azure', 'azure_ad')]
        [string]$AuthType = 'azure',

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [object[]]$History
    )

    begin {
        # Construct parameters
        $Parameters = $PSBoundParameters
        $Parameters.ApiType = [OpenAIApiType]::Azure
        $Parameters.AuthType = $AuthType
        $Parameters.Model = $Deployment
        $null = $Parameters.Remove('Deployment')

        # Invoke Request-ChatCompletion
        $steppablePipeline = {
            Request-ChatCompletion @Parameters
        }.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        $steppablePipeline.Process($PSItem)
    }

    end {
        $steppablePipeline.End()
    }
}
