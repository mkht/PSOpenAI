function New-Video {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Prompt,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('input_reference')]
        [string]$InputReference,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Completions(
            'sora-2',
            'sora-2-pro'
        )]
        [string]$Model = 'sora-2',

        [Parameter()]
        [Completions('4', '8', '12')]
        [string]$Seconds = '4',

        [Parameter()]
        [Completions(
            '720x1280',
            '1280x720',
            '1024x1792',
            '1792x1024'
        )]
        [string]$Size = '720x1280',

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
    }

    process {
        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.prompt = $Prompt
        $PostBody.model = $Model

        if ($PSBoundParameters.ContainsKey('Seconds')) {
            $PostBody.seconds = $Seconds
        }
        if ($PSBoundParameters.ContainsKey('Size')) {
            $PostBody.size = $Size
        }

        if ($ToolResources.Count -gt 0) {
            $PostBody.tool_resources = $ToolResources
        }
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            $PostBody.metadata = $Metadata
        }

        if ($PSBoundParameters.ContainsKey('InputReference')) {
            $FileInfo = Resolve-FileInfo $InputReference
            $PostBody.input_reference = $FileInfo
        }
        #endregion

        #region Send API Request
        $params = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
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
        }
        #endregion

        #region Output
        Write-Verbose ('Start create video job with id "{0}". The current status is "{1}"' -f $Response.id, $Response.status)
        ParseVideoJobObject $Response
        #endregion
    }

    end {

    }
}
