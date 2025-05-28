function Set-Thread {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter( Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('InputObject')]  # for backword compatibility
        [Alias('Thread')]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter()]
        [ValidateCount(0, 20)]
        [string[]]$FileIdsForCodeInterpreter,

        [Parameter()]
        [ValidateCount(1, 1)]
        [string[]]$VectorStoresForFileSearch,

        [Parameter()]
        [ValidateCount(0, 10000)]
        [string[]]$FileIdsForFileSearch,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

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
            PSOpenAI\New-Thread @Parameters
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
