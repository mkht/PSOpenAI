function Clear-OpenAIContext {
    [CmdletBinding()]
    [OutputType([void])]
    param()
    if ($null -eq $Global:PSOpenAIContextDictionary) {
        $Global:PSOpenAIContextDictionary = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
    }
    $Global:PSOpenAIContextDictionary.Clear()
    $Global:PSOpenAIContextDictionary['ApiKey'] = $null
    $Global:PSOpenAIContextDictionary['ApiType'] = [OpenAIApiType]::OpenAI
    $Global:PSOpenAIContextDictionary['ApiBase'] = $null
    $Global:PSOpenAIContextDictionary['ApiVersion'] = ''
    $Global:PSOpenAIContextDictionary['AuthType'] = 'openai'
    $Global:PSOpenAIContextDictionary['Organization'] = ''
    $Global:PSOpenAIContextDictionary['TimeoutSec'] = 0
    $Global:PSOpenAIContextDictionary['MaxRetryCount'] = 0
}
