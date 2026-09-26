function Get-OpenAIAPIParameter {
    param(
        [Parameter(Mandatory)]
        [string]$EndpointName,

        [Parameter(Mandatory)]
        [hashtable]
        $Parameters
    )
    # Get common params from session context
    $OpenAIParameter = ParseCommonParams $Parameters

    # Get params from environment variables
    $OpenAIParameter.ApiKey = Initialize-APIKey -ApiKey $OpenAIParameter.ApiKey -ErrorAction Stop
    $OpenAIParameter.ApiBase = Initialize-APIBase -ApiBase $OpenAIParameter.ApiBase -ErrorAction Stop
    $OpenAIParameter.Organization = Initialize-OrganizationID -OrgId $OpenAIParameter.Organization

    # Get API endpoint and etc.
    $ApiParam = Get-OpenAIAPIEndpoint -EndpointName $EndpointName -ApiBase $OpenAIParameter.ApiBase

    foreach ($key in $ApiParam.Keys) {
        $OpenAIParameter.$key = $ApiParam.$key
    }

    $OpenAIParameter
}
