function Get-OpenAIAPIEndpoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$EndpointName,

        [Parameter()]
        [System.Uri]$ApiBase
    )

    #Default base API URI
    if (-not $ApiBase.IsAbsoluteUri) {
        $ApiBase = [System.Uri]::new('https://api.openai.com/v1')
    }
    $UriBuilder = [System.UriBuilder]::new($ApiBase)

    switch ($EndpointName) {
        'Chat.Completion' {
            $UriBuilder.Path += '/chat/completions'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'chat.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Text.Completion' {
            $UriBuilder.Path += '/completions'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'text.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Image.Generation' {
            $UriBuilder.Path += '/images/generations'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'image.generation'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Image.Edit' {
            $UriBuilder.Path += '/images/edits'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'image.edit'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Image.Variation' {
            $UriBuilder.Path += '/images/variations'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'image.variation'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Audio.Speech' {
            $UriBuilder.Path += '/audio/speech'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'audio.speech'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Audio.Transcription' {
            $UriBuilder.Path += '/audio/transcriptions'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'audio.transcription'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Audio.Translation' {
            $UriBuilder.Path += '/audio/translations'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'audio.translation'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Moderation' {
            $UriBuilder.Path += '/moderations'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'moderation'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Models' {
            $UriBuilder.Path += '/models'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'models'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = ''
            }
            continue
        }
        'Embeddings' {
            $UriBuilder.Path += '/embeddings'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'embeddings'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Files' {
            $UriBuilder.Path += '/files'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'files'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Assistants' {
            $UriBuilder.Path += '/assistants'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'assistants'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads' {
            $UriBuilder.Path += '/threads'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
            @{
                Name        = 'threads'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Runs' {
            $UriBuilder.Path += '/threads/{0}/runs'
            if ($UriBuilder.Path.StartsWith('//')) { $UriBuilder.Path = $UriBuilder.Path.TrimStart('/') }
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
