function Add-ThreadMessage {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Thread', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.Thread')]$Thread,

        [Parameter(ParameterSetName = 'Id', Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Text')]
        [Alias('Content')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [object[]]$Images,

        [Parameter()]
        [ValidateSet('auto', 'low', 'high')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',

        [Parameter()]
        [Completions('user', 'assistant')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter()]
        [ValidateCount(0, 20)]
        [object[]]$FileIdsForCodeInterpreter,

        [Parameter()]
        [ValidateCount(0, 10000)]
        [object[]]$FileIdsForFileSearch,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization,

        [Parameter()]
        [switch]$PassThru,

        [Parameter()]
        [switch]$WaitForRunComplete,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Threads' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get thread_id
        if ($PSCmdlet.ParameterSetName -ceq 'Thread') {
            $ThreadId = $Thread.id
        }
        if (-not $ThreadID) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
            return
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$ThreadID/messages"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Construct parameters for API request
        $Attachments = @()
        if ($FileIdsForCodeInterpreter.Count -gt 0) {
            foreach ($item in $FileIdsForCodeInterpreter) {
                if ($item -is [string]) {
                    $fileid = $item
                }
                elseif ($item.psobject.TypeNames -contains 'PSOpenAI.File') {
                    $fileid = $item.id
                }
                $Attachments += @{
                    'file_id' = $fileid
                    'tools'   = @(@{'type' = 'code_interpreter' })
                }
            }
        }
        if ($FileIdsForFileSearch.Count -gt 0) {
            foreach ($item in $FileIdsForFileSearch) {
                if ($item -is [string]) {
                    $fileid = $item
                }
                elseif ($item.psobject.TypeNames -contains 'PSOpenAI.File') {
                    $fileid = $item.id
                }
                $Attachments += @{
                    'file_id' = $fileid
                    'tools'   = @(@{'type' = 'file_search' })
                }
            }
        }

        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.role = $Role
        if ($Images.Count -gt 0) {
            $ContentsList = [System.Collections.Generic.List[hashtable]]::new($Images.Count + 1)
            # Text Message
            $ContentsList.Add(
                @{
                    type = 'text'
                    text = $Message
                }
            )
            # Images
            foreach ($image in $Images) {
                # File object
                if ($image.psobject.TypeNames -contains 'PSOpenAI.File') {
                    $ContentsList.Add(
                        @{
                            type       = 'image_file'
                            image_file = @{
                                file_id = $image.id
                                detail  = $ImageDetail
                            }
                        }
                    )
                }
                elseif ($image -is [string]) {
                    $imageUri = [uri]$image
                    if ($imageUri.Scheme -in ('https', 'http')) {
                        # Image URL
                        $ContentsList.Add(
                            @{
                                type      = 'image_url'
                                image_url = @{
                                    url    = $imageUri.AbsoluteUri
                                    detail = $ImageDetail
                                }
                            }
                        )
                    }
                    else {
                        # File-ID or something else
                        $ContentsList.Add(
                            @{
                                type       = 'image_file'
                                image_file = @{
                                    file_id = $image
                                    detail  = $ImageDetail
                                }
                            }
                        )
                    }
                }
                else {
                    # Invalid
                    Write-Error -Message 'Invalid input. Please specify a valid URL or File ID.'
                    continue
                }
            }
            $PostBody.content = $ContentsList
        }
        else {
            # Only a text message
            $PostBody.content = $Message
        }
        if ($Attachments.Count -gt 0) {
            $PostBody.attachments = $Attachments
        }
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            $PostBody.metadata = $Metadata
        }
        #endregion

        #region Wait for good time to send API request
        if ($WaitForRunComplete) {
            # It is not possible to add a message to a Thread while the state of the Run associated with the Thread is "active" (will fail with a 400 bad request).
            # Wait for the Run to finish before adding a message.
            # Although requires_action is in the "active" state, it will not complete unless the user actively operates on it.
            # Do not wait to avoid getting stuck in an infinite loop.
            $null = PSOpenAI\Get-ThreadRun -ThreadId $ThreadId -All @CommonParams | `
                    Where-Object { $_.status -notin ('completed', 'cancelled', 'expired', 'failed', 'requires_action') } | `
                    ForEach-Object { Write-Verbose "Waiting for the run to complete. Run ID: $($_.id)"; $_ } | `
                    PSOpenAI\Wait-ThreadRun -StatusForWait ('queued', 'in_progress', 'cancelling') @CommonParams
        }
        #endregion

        #region Send API Request
        $params = @{
            Method            = $OpenAIParameter.Method
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIAPIRequest @params

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Output
        # Output thread object only when the PassThru switch is specified.
        if ($PassThru) {
            PSOpenAI\Get-Thread -ThreadId $ThreadID @CommonParams
        }
        #endregion
    }

    end {

    }
}
