function Get-OpenAIAPIEndpoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$EndpointName
    )

    switch ($EndpointName) {
        'Chat.Completion' {
            @{
                Name        = 'chat.completion'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/chat/completions'
                ContentType = 'application/json'
            }
        }
        'Text.Completion' {
            @{
                Name        = 'text.completion'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/completions'
                ContentType = 'application/json'
            }
        }
        'Text.Edit' {
            @{
                Name        = 'text.edit'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/edits'
                ContentType = 'application/json'
            }
        }
        'Image.Generation' {
            @{
                Name        = 'image.generation'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/images/generations'
                ContentType = 'application/json'
            }
        }
        'Image.Edit' {
            @{
                Name        = 'image.edit'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/images/edits'
                ContentType = 'multipart/form-data'
            }
        }
        'Image.Variation' {
            @{
                Name        = 'image.variation'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/images/variations'
                ContentType = 'multipart/form-data'
            }
        }
        'Audio.Transcription' {
            @{
                Name        = 'audio.transcription'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/audio/transcriptions'
                ContentType = 'multipart/form-data'
            }
        }
        'Audio.Translation' {
            @{
                Name        = 'audio.translation'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/audio/translations'
                ContentType = 'multipart/form-data'
            }
        }
        'Moderation' {
            @{
                Name        = 'moderation'
                Method      = 'Post'
                Uri         = 'https://api.openai.com/v1/moderations'
                ContentType = 'application/json'
            }
        }
        'Model' {
            @{
                Name        = 'model'
                Method      = 'Get'
                Uri         = 'https://api.openai.com/v1/models'
                ContentType = ''
            }
        }
    }
}
