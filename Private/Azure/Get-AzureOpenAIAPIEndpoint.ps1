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
    $DefaultApiVersion = '2024-02-15-preview'

    switch ($EndpointName) {
        'Chat.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/chat/completions' -f $Engine.Replace('/', '').Trim())
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
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
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
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
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
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
            $UriBuilder.Path += ('/openai/deployments/{0}/images/generations' -f $Engine.Replace('/', '').Trim())
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'image.generation'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        # Legacy version of image generations endpoint
        'Image.Generation.Legacy' {
            $InnerApiVersion = '2023-08-01-preview'
            $UriBuilder.Path += '/openai/images/generations:submit'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'image.generation'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Audio.Speech' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/audio/speech' -f $Engine.Replace('/', '').Trim())
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'audio.speech'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Audio.Transcription' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/audio/transcriptions' -f $Engine.Replace('/', '').Trim())
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
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
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
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
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
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
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
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
