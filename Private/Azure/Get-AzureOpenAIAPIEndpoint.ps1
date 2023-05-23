function Get-AzureOpenAIAPIEndpoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$EndpointName,

        [Parameter()]
        [string]$Engine,

        [Parameter(Mandatory)]
        [System.Uri]$ApiBase,

        [Parameter()]
        [AllowEmptyString()]
        [string]$ApiVersion
    )

    $UriBuilder = [System.UriBuilder]::new($ApiBase)
    if ([string]::IsNullOrWhiteSpace($ApiVersion)) {
        $ApiVersion = '2023-05-15'  # default api version
    }

    switch ($EndpointName) {
        'Chat.Completion' {
            $UriBuilder.Path = ('/openai/deployments/{0}/chat/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $ApiVersion.Trim())
            @{
                Name        = 'chat.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Text.Completion' {
            $UriBuilder.Path = ('/openai/deployments/{0}/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $ApiVersion.Trim())
            @{
                Name        = 'text.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Embeddings' {
            $UriBuilder.Path = ('/openai/deployments/{0}/embeddings' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $ApiVersion.Trim())
            @{
                Name        = 'embeddings'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Models' {
            # https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/models/list
            $UriBuilder.Path = '/openai/models'
            $UriBuilder.Query = ('api-version={0}' -f $ApiVersion.Trim())
            @{
                Name        = 'models'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = ''
            }
        }
        'Deployments' {
            # https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/deployments/list
            $UriBuilder.Path = '/openai/deployments'
            $UriBuilder.Query = ('api-version={0}' -f '2023-03-15-preview')
            @{
                Name        = 'deployments'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
    }
}
