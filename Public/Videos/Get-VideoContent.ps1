function Get-VideoContent {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('video_id')]
        [Alias('Id')]
        [string][UrlEncodeTransformation()]$VideoId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter()]
        [Completions('video', 'thumbnail', 'spritesheet')]
        [string][LowerCaseTransformation()]$Variant,

        [Parameter()]
        [switch]$WaitForCompletion,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Videos' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # region Wait for completion
        if ($WaitForCompletion) {
            $null = $VideoId | PSOpenAI\Wait-Video @CommonParams
        }
        # endregion

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$VideoId/content"
        $QueryUri = $UriBuilder.Uri

        if ($PSBoundParameters.ContainsKey('Variant')) {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $QueryParam.Add('variant', $Variant)
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Get'
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

        #region Output
        if ($OutFile) {
            Write-ByteContent -OutFile $OutFile -Bytes ([byte[]]$Response)
        }
        else {
            Write-Output $Response
        }
        #endregion
    }

    end {

    }
}
