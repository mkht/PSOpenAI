function Request-AudioTranscription {
    [CmdletBinding(DefaultParameterSetName = 'Language')]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$File,

        [Parameter()]
        [Completions('whisper-1')]
        [string][LowerCaseTransformation()]$Model = 'whisper-1',

        [Parameter()]
        [string]$Prompt,

        [Parameter()]
        [Alias('response_format')]
        [ValidateSet('json', 'text', 'srt', 'verbose_json', 'vtt')]
        [string]$Format = 'text',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateSet('word', 'segment')]
        [Alias('timestamp_granularities')]
        [string[]]$TimestampGranularities,

        [Parameter(ParameterSetName = 'Language')]
        [string]$Language,

        [Parameter(DontShow, ParameterSetName = 'LiteralLanguage')]
        [string]$LiteralLanguage,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Audio.Transcription' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop

        # Convert language name to ISO-639-1 format (if we can)
        if ($PSCmdlet.ParameterSetName -eq 'Language' -and $PSBoundParameters.ContainsKey('Language')) {
            $ci = Get-CultureInfo -LanguageName $Language -ErrorAction Ignore
            if ($ci -is [cultureinfo]) {
                $Language = $ci.TwoLetterISOLanguageName
            }
        }
        elseif ($PSBoundParameters.ContainsKey('LiteralLanguage')) {
            $Language = $LiteralLanguage
        }
    }

    process {
        $FileInfo = Resolve-FileInfo $File

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::OpenAI) {
            $PostBody.model = $Model
        }
        $PostBody.file = $FileInfo
        if ($Format) {
            $PostBody.response_format = $Format
        }
        if ($PSBoundParameters.ContainsKey('Prompt')) {
            $PostBody.prompt = $Prompt
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $PostBody.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('TimestampGranularities')) {
            $PostBody.timestamp_granularities = $TimestampGranularities
        }
        if ($Language) {
            $PostBody.language = $Language
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