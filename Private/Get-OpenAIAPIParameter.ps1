function Get-OpenAIAPIParameter {
    param(
        [Parameter(Mandatory)]
        [string]$EndpointName,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Engine = '',

        [Parameter(Mandatory)]
        [hashtable]
        $Parameters
    )
    # Get common params from session context
    $OpenAIParameter = ParseCommonParams $Parameters

    # Get params from environment variables
    $OpenAIParameter.ApiKey = Initialize-APIKey -ApiKey $OpenAIParameter.ApiKey -ErrorAction Stop
    $OpenAIParameter.ApiBase = Initialize-APIBase -ApiBase $OpenAIParameter.ApiBase -ApiType $OpenAIParameter.ApiType -ErrorAction Stop
    $OpenAIParameter.Organization = Initialize-OrganizationID -OrgId $OpenAIParameter.Organization

    # Get API endpoint and etc.
    if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::Azure) {
        # When the user wants to use Azure, the AuthType is also set to Azure.
        if ($OpenAIParameter.AuthType -notlike 'azure*') {
            $OpenAIParameter.AuthType = 'azure'
        }
        $ApiParam = Get-AzureOpenAIAPIEndpoint -EndpointName $EndpointName -ApiBase $OpenAIParameter.ApiBase -ApiVersion $OpenAIParameter.ApiVersion -Engine $Engine
    }
    else {
        # It looks like the API base URL is Azure even though the API type is OpenAI. In this case, ignore the base URL.
        if (([string]([uri]$OpenAIParameter.ApiBase).IdnHost).EndsWith('.azure.com', [System.StringComparison]::OrdinalIgnoreCase)) {
            $OpenAIParameter.ApiBase = $null
        }
        $OpenAIParameter.AuthType = 'openai'
        $ApiParam = Get-OpenAIAPIEndpoint -EndpointName $EndpointName -ApiBase $OpenAIParameter.ApiBase
    }

    foreach ($key in $ApiParam.Keys) {
        $OpenAIParameter.$key = $ApiParam.$key
    }

    $OpenAIParameter
}
