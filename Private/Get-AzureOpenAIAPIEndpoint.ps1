function Get-AzureOpenAIAPIEndpoint {
    [CmdletBinding()]
    [OutputType([hashtable])]
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
    $DefaultApiVersion = '2024-10-01-preview'
    $UriBuilder = [System.UriBuilder]::new($ApiBase)
    if (-not $UriBuilder.Path.EndsWith('/', [StringComparison]::Ordinal)) {
        $UriBuilder.Path += '/'
    }

    switch ($EndpointName) {
        'Chat.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('openai/deployments/{0}/chat/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name          = 'chat.completion'
                Method        = 'Post'
                Uri           = $UriBuilder.Uri
                ContentType   = 'application/json'
                BatchEndpoint = '/chat/completions'
            }
            continue
        }
        'Text.Completion' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('openai/deployments/{0}/completions' -f $Engine.Replace('/', '').Trim())
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name          = 'text.completion'
                Method        = 'Post'
                Uri           = $UriBuilder.Uri
                ContentType   = 'application/json'
                BatchEndpoint = '/completions'
            }
            continue
        }
        'Image.Generation' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += ('openai/deployments/{0}/images/generations' -f $Engine.Replace('/', '').Trim())
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
            $UriBuilder.Path += 'openai/images/generations:submit'
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
            $UriBuilder.Path += ('openai/deployments/{0}/audio/speech' -f $Engine.Replace('/', '').Trim())
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
            $UriBuilder.Path += ('openai/deployments/{0}/audio/transcriptions' -f $Engine.Replace('/', '').Trim())
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
            $UriBuilder.Path += ('openai/deployments/{0}/audio/translations' -f $Engine.Replace('/', '').Trim())
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
            $UriBuilder.Path += ('openai/deployments/{0}/embeddings' -f $Engine.Replace('/', '').Trim())
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
            $UriBuilder.Path += 'openai/models'
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
            $UriBuilder.Path += 'openai/files'
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
            $UriBuilder.Path += 'openai/assistants'
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
            $UriBuilder.Path += 'openai/threads'
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
            $UriBuilder.Path += 'openai/threads/{0}/runs'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'runs'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'ThreadAndRun' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += 'openai/threads/runs'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'thread_and_run'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Batch' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += 'openai/batches'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'batches'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += 'openai/vector_stores'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'vector_stores'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStore.Files' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += 'openai/vector_stores/{0}/files'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'vector_store_files'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStore.FileBatches' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += 'openai/vector_stores/{0}/file_batches'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            @{
                Name        = 'vector_store_file_batches'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Realtime' {
            $InnerApiVersion = if ($ApiVersion) { $ApiVersion }else { $DefaultApiVersion }
            $UriBuilder.Path += 'openai/realtime'
            $UriBuilder.Query = ('api-version={0}' -f $InnerApiVersion)
            if ($UriBuilder.Scheme -eq 'https') {
                $UriBuilder.Scheme = 'wss'
            }
            elseif ($UriBuilder.Scheme -eq 'http') {
                $UriBuilder.Scheme = 'ws'
            }
            @{
                Name        = 'realtime'
                Method      = ''
                Uri         = $UriBuilder.Uri
                ContentType = ''
            }
            continue
        }
        Default {
            Write-Error -Message ('{0} API endpoint is not provided by Azure OpenAI Service' -f $_)
        }
    }
}
