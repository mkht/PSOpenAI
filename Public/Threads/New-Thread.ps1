function New-Thread {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        # Hidden param, for Set-Thread cmdlet
        [Parameter(DontShow, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Thread')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(DontShow)]
        [object[]]$Messages,

        [Parameter()]
        [ValidateCount(0, 20)]
        [string[]]$FileIdsForCodeInterpreter,

        [Parameter()]
        [ValidateCount(1, 1)]
        [string[]]$VectorStoresForFileSearch,

        [Parameter()]
        [ValidateCount(0, 10000)]
        [string[]]$FileIdsForFileSearch,

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
        #region Construct parameters for API request
        if (-not [string]::IsNullOrEmpty($ThreadID)) {
            $QueryUri = $OpenAIParameter.Uri.ToString() + "/$ThreadID"
        }
        else {
            $QueryUri = $OpenAIParameter.Uri
        }
        #endregion

        #region Construct tools resources
        $ToolResources = @{}
        if ($FileIdsForCodeInterpreter.Count -gt 0) {
            $ToolResources.code_interpreter = @{'file_ids' = $FileIdsForCodeInterpreter }
        }
        if ($FileIdsForFileSearch.Count -gt 0) {
            $ToolResources.file_search = @{'vector_stores' = @(@{'file_ids' = $FileIdsForFileSearch }) }
        }
        if ($VectorStoresForFileSearch.Count -gt 0) {
            $ToolResources.file_search = @{'vector_store_ids' = $VectorStoresForFileSearch }
        }
        #endregion

        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($ToolResources.Count -gt 0) {
            $PostBody.tool_resources = $ToolResources
        }
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            $PostBody.metadata = $Metadata
        }

        if ($Messages.Count -gt 0) {
            $innerMessages = [System.Collections.Generic.List[hashtable]]::new($Messages.Count)
            foreach ($msg in $Messages) {
                $t = @{
                    'role'    = 'user'
                    'content' = $null
                }
                if ($msg -is [string]) {
                    $t.content = $msg
                }
                if ($msg.role -is [string] -and -not [string]::IsNullOrEmpty($msg.role)) {
                    $t.user = $msg.role
                }
                if ($msg.message -is [string] -and -not [string]::IsNullOrEmpty($msg.message)) {
                    $t.content = $msg.message
                }
                if ($msg.content -is [string] -and -not [string]::IsNullOrEmpty($msg.content)) {
                    $t.content = $msg.content
                }
                elseif ($msg.content -is [array]) {
                    $t.content = $msg.content
                }
                if ($msg.attachments.Count -gt 0) {
                    $t.attachments = @($msg.attachments)
                }
                if ($msg.metadata -is [System.Collections.IDictionary]) {
                    $t.metadata = $msg.metadata
                }
                if ($null -ne $t.content) {
                    $innerMessages.Add($t)
                }
            }
            $PostBody.messages = $innerMessages.ToArray()
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

        #region Parse response object
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        #region Output
        Write-Verbose ('The thread with id "{0}" has been created.' -f $Response.id)
        ParseThreadObject $Response -CommonParams $CommonParams -Primitive
        #endregion
    }

    end {

    }
}
