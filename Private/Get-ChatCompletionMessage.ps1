function Get-ChatCompletionMessage {
    [CmdletBinding(DefaultParameterSetName = 'Get_Id')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get_Chat', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Chat.Completion')]$Completion,

        [Parameter(ParameterSetName = 'Get_Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [Alias('completion_id')]
        [string][UrlEncodeTransformation()]$CompletionId,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter()]
        [switch]$All,

        [Parameter(DontShow)]
        [string]$After,

        [Parameter(DontShow)]
        [string]$Before,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

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
        if ($PSCmdlet.ParameterSetName -ceq 'Get_Chat') {
            $CompletionId = $Completion.id
            if (-not $CompletionId) {
                Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve completion id.'))
                return
            }
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$CompletionId/messages"
        $QueryUri = $UriBuilder.Uri

        $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)

        if ($All) {
            $QueryParam.Add('limit', 100)
        }
        elseif ($PSBoundParameters.ContainsKey('Limit')) {
            $QueryParam.Add('limit', $Limit)
        }
        if ($PSBoundParameters.ContainsKey('Order')) {
            $QueryParam.Add('order', $Order)
        }
        if ($PSBoundParameters.ContainsKey('After')) {
            $QueryParam.Add('after', $After)
        }

        $UriBuilder.Query = $QueryParam.ToString()
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Get'
            Uri               = $QueryUri
            # ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
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
        if ($Response.object -eq 'list' -and ($null -ne $Response.data)) {
            # List of object
            $Responses = @($Response.data)
        }
        else {
            # Single object
            $Responses = @($Response)
        }
        # parse objects
        foreach ($res in $Responses) {
            # $res.PSObject.TypeNames.Insert(0, 'PSOpenAI.Chat.Completion.Message')
            ParseChatCompletionMessageObject $res
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($All) {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                PSOpenAI\Get-ChatCompletionMessage @PagenationParam
            }
            else {
                Write-Warning 'There is more data that has not been retrieved.'
            }
        }
        #endregion
    }

    end {

    }
}
