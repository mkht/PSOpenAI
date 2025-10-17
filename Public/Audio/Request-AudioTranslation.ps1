function Request-AudioTranslation {
    [CmdletBinding(DefaultParameterSetName = 'Language')]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$File,

        [Parameter()]
        [Completions('whisper-1')]
        [string]$Model = 'whisper-1',

        [Parameter()]
        [string]$Prompt,

        [Parameter()]
        [Alias('response_format')]
        [Alias('Format')]  # for backward compatibility
        [ValidateSet('json', 'text', 'srt', 'verbose_json', 'vtt')]
        [string]$ResponseFormat = 'text',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$Temperature,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Audio.Translation' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop
    }

    process {
        $FileInfo = Resolve-FileInfo $File

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        $PostBody.file = $FileInfo
        if ($ResponseFormat) {
            $PostBody.response_format = $ResponseFormat
        }
        if ($PSBoundParameters.ContainsKey('Prompt')) {
            $PostBody.prompt = $Prompt
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $PostBody.temperature = $Temperature
        }

        #region Send API Request
        $splat = @{
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
        $Response = Invoke-OpenAIAPIRequest @splat

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Output
        Write-Output $Response
        #endregion
    }

    end {

    }
}