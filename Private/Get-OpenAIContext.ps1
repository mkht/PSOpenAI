function Get-OpenAIContext {
    param(
        [Parameter(Mandatory)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter(Mandatory)]
        [string]$EndpointName,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Engine = '',

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [string]$ApiVersion,

        [Parameter()]
        [string]$AuthType = 'openai'
    )

    if ($ApiType -eq [OpenAIApiType]::Azure) {
        $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName $EndpointName -ApiBase $ApiBase -ApiVersion $ApiVersion -Engine $Engine
    }
    else {
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName $EndpointName -ApiBase $ApiBase
    }

    # When the user wants to use Azure, the AuthType is also set to Azure.
    if ($ApiType -eq [OpenAIApiType]::Azure -and $AuthType -notlike 'azure*') {
        $OpenAIParameter.AuthType = 'azure'
    }
    else {
        $OpenAIParameter.AuthType = $AuthType
    }

    $OpenAIParameter
}
