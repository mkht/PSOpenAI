function New-Thread {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType([pscustomobject])]
    param (
        # Hidden param, for Set-Thread cmdlet
        [Parameter(DontShow, ParameterSetName = 'Thread', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.Thread')]$Thread,

        [Parameter(DontShow, ParameterSetName = 'Id', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(DontShow)]
        [object[]]$Messages,

        [Parameter()]
        [ValidateCount(0, 20)]
        [object[]]$FileIdsForCodeInterpreter,

        [Parameter()]
        [ValidateCount(1, 1)]
        [object[]]$VectorStoresForFileSearch,

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
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey -ErrorAction Stop

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType -ErrorAction Stop

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API context
        $OpenAIParameter = Get-OpenAIContext -EndpointName 'Threads' -ApiType $ApiType -AuthType $AuthType -ApiBase $ApiBase -ApiVersion $ApiVersion -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        #region Construct parameters for API request
        if ($Thread) {
            $ThreadId = $Thread.id
        }
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
            $list = [System.Collections.Generic.List[string]]::new($FileIdsForCodeInterpreter.Count)
            foreach ($item in $FileIdsForCodeInterpreter) {
                if ($item -is [string]) {
                    $list.Add($item)
                }
                elseif ($item.psobject.TypeNames -contains 'PSOpenAI.File') {
                    $list.Add($item.id)
                }
            }
            if ($list.Count -gt 0) {
                $ToolResources.code_interpreter = @{'file_ids' = $list.ToArray() }
            }
        }
        if ($FileIdsForFileSearch.Count -gt 0) {
            $list = [System.Collections.Generic.List[string]]::new($FileIdsForFileSearch.Count)
            foreach ($item in $FileIdsForFileSearch) {
                if ($item -is [string]) {
                    $list.Add($item)
                }
                elseif ($item.psobject.TypeNames -contains 'PSOpenAI.File') {
                    $list.Add($item.id)
                }
            }
            if ($list.Count -gt 0) {
                $ToolResources.file_search = @{'vector_stores' = @(@{'file_ids' = $list.ToArray() }) }
            }
        }
        if ($VectorStoresForFileSearch.Count -gt 0) {
            $list = [System.Collections.Generic.List[string]]::new($FileIdsForFileSearch.Count)
            foreach ($item in $VectorStoresForFileSearch) {
                if ($item -is [string]) {
                    $list.Add($item)
                }
                elseif ($item.psobject.TypeNames -contains 'PSOpenAI.VectorStore') {
                    $list.Add($item.id)
                }
            }
            if ($list.Count -gt 0) {
                $ToolResources.file_search = @{'vector_store_ids' = $list.ToArray() }
            }
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
                if ($msg.content -is [string] -and -not [string]::IsNullOrEmpty($msg.content)) {
                    $t.content = $msg.content
                }
                if ($msg.message -is [string] -and -not [string]::IsNullOrEmpty($msg.message)) {
                    $t.content = $msg.message
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
            TimeoutSec        = $TimeoutSec
            MaxRetryCount     = $MaxRetryCount
            ApiKey            = $SecureToken
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $Organization
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
