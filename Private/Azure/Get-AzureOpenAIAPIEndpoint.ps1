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
    $ApiVersion = $ApiVersion.Trim()
    $DefaultApiVersion = '2023-05-15'

    switch ($EndpointName) {
        'Chat.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path = ('/openai/deployments/{0}/chat/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'chat.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Chat.Completion.Extensions' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { '2023-06-01-preview' }
            $UriBuilder.Path = ('/openai/deployments/{0}/extensions/chat/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'chat.completion.extensions'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Text.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path = ('/openai/deployments/{0}/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'text.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Image.Generation' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { '2023-06-01-preview' }
            $UriBuilder.Path = '/openai/images/generations:submit'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'image.generation'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Embeddings' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path = ('/openai/deployments/{0}/embeddings' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'embeddings'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Models' {
            # https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/models/list
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path = '/openai/models'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'models'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = ''
            }
        }
        'Deployments' {
            # https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/deployments/list
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { '2023-03-15-preview' }
            $UriBuilder.Path = '/openai/deployments'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'deployments'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
    }
}
