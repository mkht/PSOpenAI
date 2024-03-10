function Request-AudioSpeech {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([void])]
    param (
        [Parameter(ParameterSetName = 'Default', Mandatory = $true, Position = 0)]
        [Alias('Input')]
        [ValidateNotNullOrEmpty()]
        [string]$Text,

        # For pipeline input from chat completion
        [Parameter(ParameterSetName = 'Pipeline', DontShow = $true, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Object]$InputObject,

        [Parameter()]
        [Completions('tts-1', 'tts-1-hd')]
        [string][LowerCaseTransformation()]$Model = 'tts-1',

        [Parameter()]
        [Completions(
            'alloy',
            'echo',
            'fable',
            'onyx',
            'nova',
            'shimmer'
        )]
        [string][LowerCaseTransformation()]$Voice = 'alloy',

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

        [Parameter(Mandatory = $true)]
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

        [Parameter(DontShow = $true)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow = $true)]
        [string]$ApiVersion,

        [Parameter(DontShow = $true)]
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
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType ([OpenAIApiType]::OpenAI)

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Audio.Speech' -Engine $Model -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Audio.Speech' -ApiBase $ApiBase
        }
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
            $PostBody.response_format = `
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

        #region Send API Request
        try {
            $Response = Invoke-OpenAIAPIRequest `
                -Method $OpenAIParameter.Method `
                -Uri $OpenAIParameter.Uri `
                -ContentType $OpenAIParameter.ContentType `
                -TimeoutSec $TimeoutSec `
                -MaxRetryCount $MaxRetryCount `
                -ApiKey $SecureToken `
                -AuthType $AuthType `
                -Organization $Organization `
                -Body $PostBody `
                -AdditionalQuery $AdditionalQuery -AdditionalHeaders $AdditionalHeaders -AdditionalBody $AdditionalBody
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
        try {
            # Convert to absolute path
            $AbsoluteOutFile = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutFile)
            # create parent directory if it does not exist
            $ParentDirectory = Split-Path $AbsoluteOutFile -Parent
            if (-not $ParentDirectory) {
                $ParentDirectory = [string](Get-Location -PSProvider FileSystem).ProviderPath
                $AbsoluteOutFile = Join-Path $ParentDirectory $AbsoluteOutFile
            }
            if (-not (Test-Path -LiteralPath $ParentDirectory -PathType Container)) {
                $null = New-Item -Path $ParentDirectory -ItemType Directory -Force
            }

            # Output file
            [System.IO.File]::WriteAllBytes($AbsoluteOutFile, ([byte[]]$Response))
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion
    }

    end {

    }
}