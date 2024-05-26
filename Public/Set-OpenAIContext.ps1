function Set-OpenAIContext {
    [CmdletBinding()]
    [OutputType([System.Collections.Concurrent.ConcurrentDictionary[string, object]])]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter(ValueFromPipelineByPropertyName)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter(ValueFromPipelineByPropertyName)]
        [System.Uri]$ApiBase,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$ApiVersion,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('DeploymentName')]
        [string]$Deployment,

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
    if ($PSBoundParameters.ContainsKey('ApiType')) {
        $Global:PSOpenAIContextDictionary['ApiType'] = $ApiType
    }
    if ($PSBoundParameters.ContainsKey('ApiBase')) {
        $Global:PSOpenAIContextDictionary['ApiBase'] = $ApiBase
    }
    if ($PSBoundParameters.ContainsKey('ApiVersion')) {
        $Global:PSOpenAIContextDictionary['ApiVersion'] = $ApiVersion
    }
    if ($PSBoundParameters.ContainsKey('AuthType')) {
        $Global:PSOpenAIContextDictionary['AuthType'] = $AuthType
    }
    elseif (
        $Global:PSOpenAIContextDictionary['ApiType'] -eq [OpenAIApiType]::Azure `
            -and $Global:PSOpenAIContextDictionary['AuthType'] -ieq 'openai'
    ) {
        $Global:PSOpenAIContextDictionary['AuthType'] = 'azure'
    }
    elseif (
        $Global:PSOpenAIContextDictionary['ApiType'] -eq [OpenAIApiType]::OpenAI
    ) {
        $Global:PSOpenAIContextDictionary['AuthType'] = 'openai'
    }
    if ($PSBoundParameters.ContainsKey('Deployment')) {
        $script:DefaultDeploymentModel = $Deployment
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
