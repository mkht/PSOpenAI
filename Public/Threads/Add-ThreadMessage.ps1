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
        $PostBody.content = $Message
        if ($Attachments.Count -gt 0) {
            $PostBody.attachments = $Attachments
        }
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            $PostBody.metadata = $Metadata
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
