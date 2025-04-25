function Remove-Response {
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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Responses' -Parameters $PSBoundParameters -ErrorAction Stop
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

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$ResponseId"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Delete'
            Uri               = $QueryUri
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

        #region Verbose Output
        if ($Response.deleted) {
            Write-Verbose ('The response with id "{0}" has been deleted.' -f $Response.id)
        }
        #endregion
    }

    end {

    }
}
