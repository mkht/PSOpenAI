function Get-OpenAIContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    if ($null -eq $Global:PSOpenAIContextDictionary) {
        Clear-OpenAIContext # This initializes the dictionary
    }

    [PSCustomObject]@{
        ApiKey        = $Global:PSOpenAIContextDictionary['ApiKey']
        ApiBase       = $Global:PSOpenAIContextDictionary['ApiBase']
        Organization  = $Global:PSOpenAIContextDictionary['Organization']
        TimeoutSec    = $Global:PSOpenAIContextDictionary['TimeoutSec']
        MaxRetryCount = $Global:PSOpenAIContextDictionary['MaxRetryCount']
    }
}
