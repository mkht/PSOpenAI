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
    $UriBuilder.Path = $UriBuilder.Path.TrimEnd('/')

    switch ($EndpointName) {
        'Chat.Completion' {
            $UriBuilder.Path += '/chat/completions'
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
            @{
                Name        = 'text.completion'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Text.Edit' {
            $UriBuilder.Path += '/edits'
            @{
                Name        = 'text.edit'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Image.Generation' {
            $UriBuilder.Path += '/images/generations'
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
