function Get-ThreadRun {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get_Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('InputObject')]  # for backword compatibility
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(ParameterSetName = 'Get_Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('run_id')]
        [string][UrlEncodeTransformation()]$RunId,

        [Parameter(ParameterSetName = 'Get_ThreadRun', Mandatory, Position = 0, ValueFromPipeline)]
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'List')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'List')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List', DontShow)]
        [string]$After,

        [Parameter(ParameterSetName = 'List', DontShow)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List')]
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

        [Parameter(DontShow)]
        [switch]$Primitive,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Runs' -Parameters $PSBoundParameters -ErrorAction Stop

        # Iterator flag
        [bool]$HasMore = $true
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -like '*_ThreadRun') {
            $ThreadId = $Run.thread_id
            $RunId = $Run.id
        }

        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve thread id.'))
            return
        }

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            #region Pagenation Loop
            while ($HasMore) {
                #region Construct Query URI
                $QueryUri = ($OpenAIParameter.Uri.ToString() -f $ThreadID)
                $UriBuilder = [System.UriBuilder]::new($QueryUri)
                if ($PSCmdlet.ParameterSetName -like 'Get_*') {
                    $UriBuilder.Path += "/$RunId"
                    $QueryUri = $UriBuilder.Uri
                }
                else {
                    $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
                    if ($All) {
                        $Limit = 100
                    }
                    $QueryParam.Add('limit', $Limit)
                    $QueryParam.Add('order', $Order)
                    if ($After) {
                        $QueryParam.Add('after', $After)
                    }
                    if ($Before) {
                        $QueryParam.Add('before', $Before)
                    }
                    $UriBuilder.Query = $QueryParam.ToString()
                    $QueryUri = $UriBuilder.Uri
                }
                #enregion

                #region Send API Request
                $params = @{
                    Method            = 'Get'
                    Uri               = $QueryUri
                    ContentType       = $OpenAIParameter.ContentType
                    TimeoutSec        = $OpenAIParameter.TimeoutSec
                    MaxRetryCount     = $OpenAIParameter.MaxRetryCount
                    ApiKey            = $OpenAIParameter.ApiKey
                    AuthType          = $OpenAIParameter.AuthType
                    Organization      = $OpenAIParameter.Organization
                    Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
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
                    ParseThreadRunObject $res
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
