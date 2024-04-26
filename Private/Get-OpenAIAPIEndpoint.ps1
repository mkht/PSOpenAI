function Get-OpenAIAPIEndpoint {
    [CmdletBinding()]
    [OutputType([hashtable])]
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
    if ($UriBuilder.Path.StartsWith('//', [StringComparison]::Ordinal)) {
        $UriBuilder.Path = $UriBuilder.Path.TrimStart('/')
    }

    switch ($EndpointName) {
        'Chat.Completion' {
            $UriBuilder.Path += '/chat/completions'
            @{
                Name          = 'chat.completion'
                Method        = 'Post'
                Uri           = $UriBuilder.Uri
                ContentType   = 'application/json'
                BatchEndpoint = '/v1/chat/completions'
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
        'ThreadAndRun' {
            $UriBuilder.Path += '/threads/runs'
            @{
                Name        = 'thread_and_run'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Batch' {
            $UriBuilder.Path += '/batches'
            @{
                Name        = 'batches'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores' {
            $UriBuilder.Path += '/vector_stores'
            @{
                Name        = 'vector_stores'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStore.Files' {
            $UriBuilder.Path += '/vector_stores/{0}/files'
            @{
                Name        = 'vector_store_files'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStore.FileBatches' {
            $UriBuilder.Path += '/vector_stores/{0}/file_batches'
            @{
                Name        = 'vector_store_file_batches'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        Default {
            Write-Error -Message ('{0} API endpoint is not provided by OpenAI' -f $_)
        }
    }
}
