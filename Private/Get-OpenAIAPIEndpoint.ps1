function Get-OpenAIAPIEndpoint {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$EndpointName,

        [Parameter()]
        [System.Uri]$ApiBase
    )

    # Default base API URI
    if (-not $ApiBase.IsAbsoluteUri) {
        $ApiBase = [System.Uri]::new('https://api.openai.com/v1')
    }
    $UriBuilder = [System.UriBuilder]::new($ApiBase)
    if ($UriBuilder.Path.StartsWith('//', [StringComparison]::Ordinal)) {
        $UriBuilder.Path = $UriBuilder.Path.TrimStart('/')
    }

    switch ($EndpointName) {
        'Chat.Completions' {
            $UriBuilder.Path += '/chat/completions'
            @{
                Name          = 'chat.completions'
                Method        = 'Post'
                Uri           = $UriBuilder.Uri
                ContentType   = 'application/json'
                BatchEndpoint = '/v1/chat/completions'
            }
            continue
        }
        'Completions' {
            $UriBuilder.Path += '/completions'
            @{
                Name          = 'completions'
                Method        = 'Post'
                Uri           = $UriBuilder.Uri
                ContentType   = 'application/json'
                BatchEndpoint = '/v1/completions'
            }
            continue
        }
        'Images.Generations' {
            $UriBuilder.Path += '/images/generations'
            @{
                Name        = 'images.generations'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Images.Edits' {
            $UriBuilder.Path += '/images/edits'
            @{
                Name        = 'images.edits'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Images.Variations' {
            $UriBuilder.Path += '/images/variations'
            @{
                Name        = 'images.variations'
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
        'Audio.Transcriptions' {
            $UriBuilder.Path += '/audio/transcriptions'
            @{
                Name        = 'audio.transcriptions'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Audio.Translations' {
            $UriBuilder.Path += '/audio/translations'
            @{
                Name        = 'audio.translations'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'multipart/form-data'
            }
            continue
        }
        'Embeddings' {
            $UriBuilder.Path += '/embeddings'
            @{
                Name          = 'embeddings'
                Method        = 'Post'
                Uri           = $UriBuilder.Uri
                ContentType   = 'application/json'
                BatchEndpoint = '/v1/embeddings'
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
        'Files.List' {
            $UriBuilder.Path += '/files'
            @{
                Name        = 'files.list'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Files.Retrieve' {
            $UriBuilder.Path += '/files/{0}'
            @{
                Name        = 'files.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Files.Delete' {
            $UriBuilder.Path += '/files/{0}'
            @{
                Name        = 'files.delete'
                Method      = 'Delete'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Files.Content' {
            $UriBuilder.Path += '/files/{0}/content'
            @{
                Name        = 'files.content'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = ''
            }
            continue
        }
        'FineTuning.Jobs' {
            $UriBuilder.Path += '/fine_tuning/jobs'
            @{
                Name        = 'finetuning.jobs'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'FineTuning.Jobs.List' {
            $UriBuilder.Path += '/fine_tuning/jobs'
            @{
                Name        = 'finetuning.jobs.list'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'FineTuning.Jobs.Retrieve' {
            $UriBuilder.Path += '/fine_tuning/jobs/{0}'
            @{
                Name        = 'finetuning.jobs.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'FineTuning.Jobs.Cancel' {
            $UriBuilder.Path += '/fine_tuning/jobs/{0}/cancel'
            @{
                Name        = 'finetuning.jobs.cancel'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'FineTuning.Jobs.Events' {
            $UriBuilder.Path += '/fine_tuning/jobs/{0}/events'
            @{
                Name        = 'finetuning.jobs.events'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'FineTuning.Jobs.Checkpoints' {
            $UriBuilder.Path += '/fine_tuning/jobs/{0}/checkpoints'
            @{
                Name        = 'finetuning.jobs.checkpoints'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Moderations' {
            $UriBuilder.Path += '/moderations'
            @{
                Name        = 'moderations'
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
                ContentType = 'application/json'
            }
            continue
        }
        'Models.Retrieve' {
            $UriBuilder.Path += '/models/{0}'
            @{
                Name        = 'models.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Models.Delete' {
            $UriBuilder.Path += '/models/{0}'
            @{
                Name        = 'models.delete'
                Method      = 'Delete'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
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
        'Assistants.List' {
            $UriBuilder.Path += '/assistants'
            @{
                Name        = 'assistants.list'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Assistants.Retrieve' {
            $UriBuilder.Path += '/assistants/{0}'
            @{
                Name        = 'assistants.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Assistants.Delete' {
            $UriBuilder.Path += '/assistants/{0}'
            @{
                Name        = 'assistants.delete'
                Method      = 'Delete'
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
        'Threads.Retrieve' {
            $UriBuilder.Path += '/threads/{0}'
            @{
                Name        = 'threads.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Delete' {
            $UriBuilder.Path += '/threads/{0}'
            @{
                Name        = 'threads.delete'
                Method      = 'Delete'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Messages' {
            $UriBuilder.Path += '/threads/{0}/messages'
            @{
                Name        = 'threads.messages'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Messages.List' {
            $UriBuilder.Path += '/threads/{0}/messages'
            @{
                Name        = 'threads.messages.list'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Messages.Retrieve' {
            $UriBuilder.Path += '/threads/{0}/messages/{1}'
            @{
                Name        = 'threads.messages.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Messages.Delete' {
            $UriBuilder.Path += '/threads/{0}/messages/{1}'
            @{
                Name        = 'threads.messages.delete'
                Method      = 'Delete'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Runs' {
            $UriBuilder.Path += '/threads/{0}/runs'
            @{
                Name        = 'threads.runs'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Runs.List' {
            $UriBuilder.Path += '/threads/{0}/runs'
            @{
                Name        = 'threads.runs.list'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Runs.Retrieve' {
            $UriBuilder.Path += '/threads/{0}/runs/{1}'
            @{
                Name        = 'threads.runs.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Runs.Cancel' {
            $UriBuilder.Path += '/threads/{0}/runs/{1}/cancel'
            @{
                Name        = 'threads.runs.cancel'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Runs.SubmitToolOutputs' {
            $UriBuilder.Path += '/threads/{0}/runs/{1}/submit_tool_outputs'
            @{
                Name        = 'threads.runs.submittooloutputs'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Runs.Steps' {
            $UriBuilder.Path += '/threads/{0}/runs/{1}/steps'
            @{
                Name        = 'threads.runs.steps'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Runs.Steps.Retrieve' {
            $UriBuilder.Path += '/threads/{0}/runs/{1}/steps/{2}'
            @{
                Name        = 'threads.runs.steps.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Threads.Runs.CreateAndRun' {
            $UriBuilder.Path += '/threads/runs'
            @{
                Name        = 'Threads.Runs.CreateAndRun'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Batches' {
            $UriBuilder.Path += '/batches'
            @{
                Name          = 'batches'
                Method        = 'Post'
                Uri           = $UriBuilder.Uri
                ContentType   = 'application/json'
                BatchEndpoint = $null
            }
            continue
        }
        'Batches.List' {
            $UriBuilder.Path += '/batches'
            @{
                Name        = 'batches.list'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Batches.Retrieve' {
            $UriBuilder.Path += '/batches/{0}'
            @{
                Name        = 'batches.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Batches.Cancel' {
            $UriBuilder.Path += '/batches/{0}/cancel'
            @{
                Name        = 'batches.cancel'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores' {
            $UriBuilder.Path += '/vector_stores'
            @{
                Name        = 'vectorstores'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.List' {
            $UriBuilder.Path += '/vector_stores'
            @{
                Name        = 'vectorstores.list'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.Retrieve' {
            $UriBuilder.Path += '/vector_stores/{0}'
            @{
                Name        = 'vectorstores.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.Delete' {
            $UriBuilder.Path += '/vector_stores/{0}'
            @{
                Name        = 'vectorstores.delete'
                Method      = 'Delete'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.Files' {
            $UriBuilder.Path += '/vector_stores/{0}/files'
            @{
                Name        = 'vectorstores.files'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.Files.List' {
            $UriBuilder.Path += '/vector_stores/{0}/files'
            @{
                Name        = 'vectorstores.files.list'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.Files.Retrieve' {
            $UriBuilder.Path += '/vector_stores/{0}/files/{1}'
            @{
                Name        = 'vectorstores.files.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.Files.Delete' {
            $UriBuilder.Path += '/vector_stores/{0}/files/{1}'
            @{
                Name        = 'vectorstores.files.delete'
                Method      = 'Delete'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.FileBatches' {
            $UriBuilder.Path += '/vector_stores/{0}/file_batches'
            @{
                Name        = 'vectorstores.filebatches'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.FileBatches.Retrieve' {
            $UriBuilder.Path += '/vector_stores/{0}/file_batches/{1}'
            @{
                Name        = 'vectorstores.filebatches.retrieve'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.FileBatches.Cancel' {
            $UriBuilder.Path += '/vector_stores/{0}/file_batches/{1}/cancel'
            @{
                Name        = 'vectorstores.filebatches.cancel'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'VectorStores.FileBatches.Files' {
            $UriBuilder.Path += '/vector_stores/{0}/file_batches/{1}/files'
            @{
                Name        = 'vectorstores.filebatches.files'
                Method      = 'Get'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
            continue
        }
        'Assistants.Modify' {
            $UriBuilder.Path += '/assistants/{0}'
            @{
                Name        = 'assistants.modify'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Threads.Modify' {
            $UriBuilder.Path += '/threads/{0}'
            @{
                Name        = 'threads.modify'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Threads.Messages.Modify' {
            $UriBuilder.Path += '/threads/{0}/messages/{1}'
            @{
                Name        = 'threads.messages.modify'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'Threads.Runs.Modify' {
            $UriBuilder.Path += '/threads/{0}/runs/{1}'
            @{
                Name        = 'threads.runs.modify'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        'VectorStores.Modify' {
            $UriBuilder.Path += '/vector_stores/{0}'
            @{
                Name        = 'vectorstores.modify'
                Method      = 'Post'
                Uri         = $UriBuilder.Uri
                ContentType = 'application/json'
            }
        }
        Default {
            Write-Error -Message ('{0} API endpoint is not provided by OpenAI' -f $_)
        }
    }
}