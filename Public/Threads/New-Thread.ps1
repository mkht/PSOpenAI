function New-Thread {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        # Hidden param, for Set-Thread cmdlet
        [Parameter(DontShow, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Object]$InputObject,

        [Parameter(DontShow)]
        [object[]]$Messages,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter(DontShow)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter(DontShow)]
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
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Threads' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Threads' -ApiBase $ApiBase
        }

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get thread_id
        if ($null -ne $InputObject) {
            [string][UrlEncodeTransformation()]$ThreadID = Get-ThreadIdFromInputObject $InputObject
        }

        #region Construct parameters for API request
        if (-not [string]::IsNullOrEmpty($ThreadID)) {
            $QueryUri = $OpenAIParameter.Uri.ToString() + "/$ThreadID"
        }
        else {
            $QueryUri = $OpenAIParameter.Uri
        }

        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
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
                if ($null -ne $msg.file_ids) {
                    $i = [string[]]@()
                    foreach ($fileid in $msg.file_ids) {
                        $i += [string]$fileid
                    }
                    if ($i.Count -gt 0) {
                        $t.file_ids = $i
                    }
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
            AuthType          = $AuthType
            Organization      = $Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v1' }
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
        Write-Output (ParseThreadObject $Response -CommonParams $CommonParams -Primitive)
        #endregion
    }

    end {

    }
}
