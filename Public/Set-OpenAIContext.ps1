function Set-OpenAIContext {
    [CmdletBinding()]
    [OutputType([System.Collections.Concurrent.ConcurrentDictionary[string, object]])]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Uri]$ApiBase,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('OrgId')]
        [string]$Organization,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int]$TimeoutSec = 0,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0
    )

    if ($null -eq $Global:PSOpenAIContextDictionary) {
        Clear-OpenAIContext
    }

    if ($PSBoundParameters.ContainsKey('ApiKey')) {
        $Global:PSOpenAIContextDictionary['ApiKey'] = $ApiKey
    }
    if ($PSBoundParameters.ContainsKey('ApiBase')) {
        $Global:PSOpenAIContextDictionary['ApiBase'] = $ApiBase
    }
    if ($PSBoundParameters.ContainsKey('Organization')) {
        $Global:PSOpenAIContextDictionary['Organization'] = $Organization
    }
    if ($PSBoundParameters.ContainsKey('TimeoutSec')) {
        $Global:PSOpenAIContextDictionary['TimeoutSec'] = $TimeoutSec
    }
    if ($PSBoundParameters.ContainsKey('MaxRetryCount')) {
        $Global:PSOpenAIContextDictionary['MaxRetryCount'] = $MaxRetryCount
    }
}
