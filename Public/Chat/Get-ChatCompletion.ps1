function Get-ChatCompletion {
    [CmdletBinding(DefaultParameterSetName = 'List')]
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

        [Parameter(ParameterSetName = 'List')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'List')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List', DontShow)]
        [string]$After,

        [Parameter(ParameterSetName = 'List', DontShow)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List', DontShow)]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

        # For internal use
        [Parameter(DontShow)]
        [switch]$Primitive,

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
        if ($PSCmdlet.ParameterSetName -like 'Get_*') {
            $UriBuilder.Path += "/$CompletionId"
            $QueryUri = $UriBuilder.Uri
        }
        else {
            # List
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
        }
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
            return
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
            # get messages
            $Messages = [System.Collections.Generic.List[object]]::new()

            if (-not $Primitive) {
                Get-ChatCompletionMessage -CompletionId $res.id -All -Order asc | ForEach-Object {
                    $Messages.Add($_)
                }
            }

            # Add assistant response to messages list.
            $msg = @($Response.choices.message)[0]
            $rcm = [ordered]@{
                role    = $msg.role
                content = $msg.content
            }
            if ($msg.refusal) {
                $rcm.Add('refusal', $msg.refusal)
            }
            if ($msg.audio) {
                $rcm.Add('audio', (@{id = $msg.audio.id }))
            }
            if ($msg.tool_calls) {
                $rcm.Add('tool_calls', $msg.tool_calls)
            }
            $Messages.Add($rcm)

            # parse object
            ParseChatCompletionObject $res -Messages $Messages -WarningAction Ignore
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($All) {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                PSOpenAI\Get-ChatCompletion @PagenationParam
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
