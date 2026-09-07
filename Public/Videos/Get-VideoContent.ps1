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
        [string][LowerCaseTransformation()]$Variant = 'video',

        [Parameter()]
        [switch]$WaitForCompletion,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Videos.Content' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # region Wait for completion
        if ($WaitForCompletion) {
            Write-Verbose -Message "Waiting for the job with id '$VideoId' to be completed..."
            $FinishedJob = $VideoId | PSOpenAI\Wait-Video @CommonParams
            if ($FinishedJob.status -in ('completed', 'succeeded')) {
                Write-Verbose -Message "The job with id '$VideoId' is completed."
            }
            else {
                Write-Error -Message "The job with id '$VideoId' was not completed. The status is '$($FinishedJob.status)'."
                return
            }
        }
        # endregion



        #region Construct Query URI
        $QueryUri = $OpenAIParameter.Uri.ToString() -f $VideoId
        $UriBuilder = [System.UriBuilder]::new($QueryUri)


        if ($PSBoundParameters.ContainsKey('Variant')) {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $QueryParam.Add('variant', $Variant)
            $UriBuilder.Query = $QueryParam.ToString()
        }

        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Get'
            Uri               = $QueryUri
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            Organization      = $OpenAIParameter.Organization
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIHttpRequest @params

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
