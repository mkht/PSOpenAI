function Get-ResponseInputItem {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Response', Mandatory, Position = 0, ValueFromPipeline)]
        [Alias('InputObject')]
        [PSTypeName('PSOpenAI.Response')]$Response,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [Alias('response_id')]
        [string][UrlEncodeTransformation()]$ResponseId,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter()]
        [switch]$All,

        [Parameter(DontShow)]
        [string]$After,

        [Parameter(DontShow)]
        [string]$Before,

        [Parameter(DontShow)]
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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Responses.InputItems' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters

        # Iterator flag
        [bool]$HasMore = $true
    }

    process {
        # Get id
        if ($PSCmdlet.ParameterSetName -ceq 'Response') {
            $ResponseId = $Response.id
            if (-not $ResponseId) {
                Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve response id.'))
                return
            }
        }

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        #region Construct Query URI
        $QueryUri = $OpenAIParameter.Uri.ToString() -f $ResponseId

        try {
            #region Pagenation Loop
            while ($HasMore) {
                #region Construct Query URI
                $UriBuilder = [System.UriBuilder]::new($QueryUri)
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
                    Write-Output $res
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
