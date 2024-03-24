function Set-Assistant {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('assistant_id')]
        [Alias('Assistant')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('asst_', [StringComparison]::Ordinal)) -or `
                ($_.id -is [string] -and $_.id.StartsWith('asst_', [StringComparison]::Ordinal)) -or `
                ($_.assistant_id -is [string] -and $_.assistant_id.StartsWith('asst_', [StringComparison]::Ordinal))
            })]
        [Object]$InputObject,

        [Parameter()]
        [ValidateLength(0, 256)]
        [string]$Name,

        [Parameter()]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-3.5-turbo-16k',
            'gpt-3.5-turbo-0613',
            'gpt-3.5-turbo-16k-0613',
            'gpt-3.5-turbo-1106',
            'gpt-3.5-turbo-0125',
            'gpt-4-0613',
            'gpt-4-32k',
            'gpt-4-32k-0613',
            'gpt-4-turbo-preview',
            'gpt-4-1106-preview',
            'gpt-4-0125-preview',
            'gpt-4-vision-preview'
        )]
        [string][LowerCaseTransformation()]$Model = 'gpt-3.5-turbo',

        [Parameter()]
        [ValidateLength(0, 512)]
        [string]$Description,

        [Parameter()]
        [ValidateLength(0, 32768)]
        [string]$Instructions,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [switch]$UseCodeInterpreter,

        [Parameter()]
        [switch]$UseRetrieval,

        [Parameter()]
        [Alias('file_ids')]
        [ValidateRange(0, 20)]
        [string[]]$FileId,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter(DontShow = $true)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow = $true)]
        [string]$ApiVersion,

        [Parameter(DontShow = $true)]
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
