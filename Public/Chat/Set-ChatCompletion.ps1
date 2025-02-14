function Set-ChatCompletion {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Chat', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Chat.Completion')]$Completion,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [Alias('completion_id')]
        [string][UrlEncodeTransformation()]$CompletionId,

        [Parameter(Mandatory)]
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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Chat.Completion' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        # Get id
        if ($PSCmdlet.ParameterSetName -ceq 'Chat') {
            $CompletionId = $Completion.id
            if (-not $CompletionId) {
                Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve completion id.'))
                return
            }
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$CompletionId"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.metadata = $MetaData
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Post'
            Uri               = $QueryUri
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            ContentType       = $OpenAIParameter.ContentType
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
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
            return
        }
        #endregion

        #region Output
        ParseChatCompletionObject $Response -WarningAction Ignore
        #endregion
    }

    end {

    }
}