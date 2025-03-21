function Request-AudioSpeech {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([void])]
    param (
        [Parameter(ParameterSetName = 'Default', Mandatory, Position = 0)]
        [Alias('Input')]
        [ValidateNotNullOrEmpty()]
        [string]$Text,

        # For pipeline input from chat completion
        [Parameter(ParameterSetName = 'Pipeline', DontShow, Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Object]$InputObject,

        [Parameter()]
        [Completions('tts-1', 'tts-1-hd', 'gpt-4o-mini-tts')]
        [string]$Model = 'tts-1',

        [Parameter()]
        [Completions(
            'alloy',
            'ash',
            'coral',
            'echo',
            'fable',
            'onyx',
            'nova',
            'sage',
            'shimmer'
        )]
        [string][LowerCaseTransformation()]$Voice = 'alloy',

        [Parameter()]
        [string]$Instructions,

        [Parameter()]
        [Alias('response_format')]
        [Completions(
            'mp3',
            'opus',
            'aac',
            'flac',
            'wav',
            'pcm'
        )]
        [string][LowerCaseTransformation()]$Format,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter()]
        [ValidateRange(0.25, 4.0)]
        [double]$Speed = 1.0,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Audio.Speech' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline') {
            if ($InputObject -is [string]) {
                $Text = $InputObject
            }
            elseif ($InputObject.Answer -as [string]) {
                $Text = [string]$InputObject.Answer
            }
            else {
                Write-Error -Exception ([System.ArgumentException]::new('Input object is invalid.'))
                return
            }
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        $PostBody.input = $Text
        $PostBody.voice = $Voice
        if ($PSBoundParameters.ContainsKey('Format')) {
            $PostBody.response_format = $Format
        }
        else {
            $PostBody.response_format =
            switch -Wildcard ($OutFile) {
                '*.mp3' { 'mp3'; break }
                '*.opus' { 'opus'; break }
                '*.aac' { 'aac'; break }
                '*.flac' { 'flac'; break }
                '*.wav' { 'wav'; break }
                Default { 'mp3' }
            }
        }
        if ($PSBoundParameters.ContainsKey('Speed')) {
            $PostBody.speed = $Speed
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $PostBody.instructions = $Instructions
        }

        #region Send API Request
        try {
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
        }
        catch {
            Write-Error -Exception $_.Exception
        }

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Output
        Write-ByteContent -OutFile $OutFile -Bytes ([byte[]]$Response)
        #endregion
    }

    end {

    }
}