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
    $UriBuilder.Path = $UriBuilder.Path.TrimEnd('/')
    $ApiVersion = $ApiVersion.Trim()
    $DefaultApiVersion = '2023-09-01-preview'

    switch ($EndpointName) {
        'Chat.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/chat/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'chat.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Chat.Completion.Extensions' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/extensions/chat/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'chat.completion.extensions'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Text.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'text.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Image.Generation' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += '/openai/images/generations:submit'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'image.generation'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Audio.Transcription' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/audio/transcriptions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'audio.transcription'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Audio.Translation' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/audio/translations' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'audio.transcription'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Embeddings' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/embeddings' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'embeddings'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Models' {
            # https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/models/list
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += '/openai/models'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'models'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = ''
            }
            continue
        }
    }
}
