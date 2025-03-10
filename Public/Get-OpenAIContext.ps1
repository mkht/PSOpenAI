function Get-OpenAIContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    if ($null -eq $Global:PSOpenAIContextDictionary) {
        Clear-OpenAIContext # This initializes the dictionary
    }

    [PSCustomObject]@{
        ApiKey        = $Global:PSOpenAIContextDictionary['ApiKey']
        ApiType       = $Global:PSOpenAIContextDictionary['ApiType']
        ApiBase       = $Global:PSOpenAIContextDictionary['ApiBase']
        ApiVersion    = $Global:PSOpenAIContextDictionary['ApiVersion']
        AuthType      = $Global:PSOpenAIContextDictionary['AuthType']
        Organization  = $Global:PSOpenAIContextDictionary['Organization']
        TimeoutSec    = $Global:PSOpenAIContextDictionary['TimeoutSec']
        MaxRetryCount = $Global:PSOpenAIContextDictionary['MaxRetryCount']
    }
}
