function Get-ChatCompletion {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Completion')]
        [Alias('completion_id')]
        [Alias('Id')]   # for backword compatibility
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

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters

        # Iterator flag
        [bool]$HasMore = $true
    }

    process {
        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            #region Pagenation Loop
            while ($HasMore) {
                #region Construct Query URI
                $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
                if ($PSCmdlet.ParameterSetName -eq 'Get') {
                    $UriBuilder.Path += "/$CompletionId"
                    $QueryUri = $UriBuilder.Uri
                }
                else {
                    # List
                    $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)

                    if ($All) {
                        $Limit = 100
                    }
                    $QueryParam.Add('limit', $Limit)
                    $QueryParam.Add('order', $Order)
                    if ($After) {
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

                # Check cancellation
                $Cancellation.Token.ThrowIfCancellationRequested()

                # Update iterator flag
                if ($HasMore = [bool]$Response.has_more) {
                    if ($All -and $Response.last_id) {
                        $After = $Response.last_id
                    }
                    else {
                        $HasMore = $false
                        if (-not $PSBoundParameters.ContainsKey('Limit')) {
                            Write-Warning 'There is more data that has not been retrieved.'
                        }
                    }
                }

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
                        Get-ChatCompletionMessage -CompletionId $res.id -All -Order asc @CommonParams | ForEach-Object {
                            $Messages.Add($_)
                        }
                    }

                    # Add assistant response to messages list.
                    $msg = @($res.choices.message)[0]
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
            }
            #endregion
        }
        catch [OperationCanceledException] {
            Write-TimeoutError
            return
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        finally {
            if ($null -ne $Cancellation) {
                $Cancellation.Dispose()
            }
        }
    }

    end {

    }
}
