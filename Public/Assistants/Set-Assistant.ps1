function Set-Assistant {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('InputObject')]  # for backward compatibility
        [Alias('Assistant')]
        [Alias('assistant_id')]
        [string][UrlEncodeTransformation()]$AssistantId,

        [Parameter()]
        [ValidateLength(0, 256)]
        [string]$Name,

        [Parameter()]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-4o',
            'gpt-4o-mini',
            'gpt-3.5-turbo-16k',
            'gpt-3.5-turbo-1106',
            'gpt-3.5-turbo-0125',
            'gpt-4-0613',
            'gpt-4-32k',
            'gpt-4-32k-0613',
            'gpt-4-turbo',
            'gpt-4-turbo-2024-04-09',
            'gpt-4.1',
            'gpt-4.1-mini',
            'gpt-4.1-nano',
            'gpt-5',
            'gpt-5-mini',
            'gpt-5-nano',
            'o1',
            'o3-mini'
        )]
        [string]$Model = 'gpt-3.5-turbo',

        [Parameter()]
        [ValidateLength(0, 512)]
        [string]$Description,

        [Parameter()]
        [ValidateLength(0, 256000)]
        [string]$Instructions,

        [Parameter()]
        [Alias('reasoning_effort')]
        [Completions('none', 'minimal', 'low', 'medium', 'high', 'xhigh')]
        [string]$ReasoningEffort,

        [Parameter()]
        [switch]$UseCodeInterpreter,

        [Parameter()]
        [switch]$UseFileSearch,

        # [Parameter()]
        # [switch]$UseFunction,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Functions,

        [Parameter()]
        [ValidateCount(0, 20)]
        [string[]]$FileIdsForCodeInterpreter,

        [Parameter()]
        [ValidateCount(1, 1)]   # Currently, allow only 1 vector store
        [string[]]$VectorStoresForFileSearch,

        [Parameter()]
        [ValidateCount(0, 10000)]
        [string[]]$FileIdsForFileSearch,

        [Parameter()]
        [ValidateRange(1, 50)]
        [uint16]$MaxNumberOfFileSearchResults,

        [Parameter()]
        [Completions('auto')]
        [string]$RankerForFileSearch = 'auto',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$ScoreThresholdForFileSearch = 0.0,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [Alias('response_format')]
        [Alias('Format')]  # for backward compatibility
        [ValidateSet('default', 'auto', 'text', 'json_object', 'json_schema', 'raw_response')]
        [object]$ResponseFormat = 'default',

        [Parameter()]
        [string]$JsonSchema,

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

    begin {
        # Construct parameters
        $Parameters = $PSBoundParameters

        # Invoke base function
        $steppablePipeline = {
            PSOpenAI\New-Assistant @Parameters
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
