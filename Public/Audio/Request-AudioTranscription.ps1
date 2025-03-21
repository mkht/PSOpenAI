function Request-AudioTranscription {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$File,

        [Parameter()]
        [Completions('whisper-1', 'gpt-4o-transcribe', 'gpt-4o-mini-transcribe')]
        [string]$Model = 'whisper-1',

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
        [Completions('logprobs')]
        [string[]]$Include,

        [Parameter()]
        [ValidateSet('word', 'segment')]
        [Alias('timestamp_granularities')]
        [string[]]$TimestampGranularities,

        [Parameter()]
        [string]$Language,

        [Parameter(DontShow, ParameterSetName = 'LiteralLanguage')]
        [string]$LiteralLanguage,

        #region Stream
        [Parameter(ParameterSetName = 'Stream')]
        [switch]$Stream = $false,

        [Parameter(ParameterSetName = 'Stream')]
        [ValidateSet('text', 'object')]
        [string]$StreamOutputType = 'text',
        #endregion Stream

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
        if ($PSBoundParameters.ContainsKey('Language')) {
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
        if ($PSBoundParameters.ContainsKey('Include')) {
            $PostBody.'include[]' = $Include
        }
        if ($Language) {
            $PostBody.language = $Language
        }
        if ($Stream) {
            $PostBody.stream = $Stream.ToBool()
        }

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

        #region Send API Request (Stream)
        if ($Stream) {
            # Stream output
            $splat.Stream = $true
            Invoke-OpenAIAPIRequest @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object {
                    try {
                        $_ | ConvertFrom-Json -ErrorAction Stop
                    }
                    catch {
                        Write-Error -Exception $_.Exception
                    }
                } | ForEach-Object -Process {
                    if ($StreamOutputType -eq 'text') {
                        if ($_.type -cne 'transcript.text.delta') {
                            continue
                        }
                        Write-Output $_.delta
                    }
                    else {
                        Write-Output $_
                    }
                }

            return
        }
        #endregion

        #region Send API Request
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