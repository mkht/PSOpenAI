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

    $ApiVersion = $ApiVersion.Trim()
    $DefaultApiVersion = '2024-03-01-preview'

    $UriBuilder = [System.UriBuilder]::new($ApiBase)
    if ($UriBuilder.Path.StartsWith('//', [StringComparison]::Ordinal)) {
        $UriBuilder.Path = $UriBuilder.Path.TrimStart('/')
    }

    switch ($EndpointName) {
        'Chat.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/chat/completions' -f $Engine.Replace('/', '', [StringComparison]::Ordinal).Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'chat.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Text.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('/openai/deployments/{0}/completions' -f $Engine.Replace('/', '', [StringComparison]::Ordinal).Trim())
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
            $UriBuilder.Path += ('/openai/deployments/{0}/images/generations' -f $Engine.Replace('/', '', [StringComparison]::Ordinal).Trim())
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
            $UriBuilder.Path += ('/openai/deployments/{0}/audio/speech' -f $Engine.Replace('/', '', [StringComparison]::Ordinal).Trim())
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
            $UriBuilder.Path += ('/openai/deployments/{0}/audio/transcriptions' -f $Engine.Replace('/', '', [StringComparison]::Ordinal).Trim())
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
            $UriBuilder.Path += ('/openai/deployments/{0}/audio/translations' -f $Engine.Replace('/', '', [StringComparison]::Ordinal).Trim())
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
            $UriBuilder.Path += ('/openai/deployments/{0}/embeddings' -f $Engine.Replace('/', '', [StringComparison]::Ordinal).Trim())
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
        'Files' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += '/openai/files'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'files'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Assistants' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += '/openai/assistants'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'assistants'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += '/openai/threads'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'threads'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Runs' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += '/openai/threads/{0}/runs'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'runs'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
    }
}
