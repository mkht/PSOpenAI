function Request-ImageGeneration {
    [CmdletBinding(DefaultParameterSetName = 'Format')]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Prompt,

        [Parameter()]
        [Completions(
            'dall-e-2',
            'dall-e-3'
        )]
        [string][LowerCaseTransformation()]$Model = 'dall-e-2',

        [Parameter()]
        [ValidateRange(1, 10)]
        [Alias('n')]
        [uint16]$NumberOfImages = 1,

        [Parameter()]
        [ValidateSet('256', '512', '1024', '256x256', '512x512', '1024x1024', '1792x1024', '1024x1792')]
        [string]$Size = '1024x1024',

        [Parameter()]
        [ValidateSet('standard', 'hd')]
        [string][LowerCaseTransformation()]$Quality = 'standard',

        [Parameter()]
        [ValidateSet('vivid', 'natural')]
        [string][LowerCaseTransformation()]$Style = 'vivid',

        [Parameter(ParameterSetName = 'Format')]
        [Alias('response_format')]
        [ValidateSet('url', 'base64', 'byte', 'raw_response')]
        [string]$Format = 'url',

        [Parameter(ParameterSetName = 'OutFile', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter(DontShow = $true)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow = $true)]
        [string]$ApiVersion,

        [Parameter(DontShow = $true)]
        [string]$AuthType = 'openai',

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

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
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Image.Generation' -Engine $Model -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Image.Generation' -ApiBase $ApiBase
        }
    }

    process {
        if ($NumberOfImages -gt 1) {
            if ($PSCmdlet.ParameterSetName -eq 'OutFile') {
                $NumberOfImages = 1
            }
            elseif ($Format -eq 'byte') {
                Write-Error -Message "When the format is specified as $Format, NumberOfImages should be 1."
                return
            }
        }

        # Parse Size property
        if ($PSBoundParameters.ContainsKey('Size') -and ($num = $Size -as [int])) {
            $Size = ('{0}x{0}' -f $num)
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.prompt = $Prompt
        if ($NumberOfImages -ge 1) {
            $PostBody.n = $NumberOfImages
        }
        if ($null -ne $Size) {
            $PostBody.size = $Size
        }
        switch ($Format) {
            { $PSCmdlet.ParameterSetName -eq 'OutFile' } {
                $PostBody.response_format = 'url'
                break
            }
            'url' {
                $PostBody.response_format = 'url'
                break
            }
            'base64' {
                $PostBody.response_format = 'b64_json'
                break
            }
            'byte' {
                $PostBody.response_format = 'b64_json'
                break
            }
        }
        if ($ApiType -eq [OpenAIApiType]::OpenAI) {
            if ($PSBoundParameters.ContainsKey('Model')) {
                $PostBody.model = $Model
            }
        }
        if ($PSBoundParameters.ContainsKey('Quality')) {
            $PostBody.quality = $Quality
        }
        if ($PSBoundParameters.ContainsKey('Style')) {
            $PostBody.style = $Style
        }
        #endregion

        #region Send API Request
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

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Parse response object
        if ($Format -eq 'raw_response') {
            Write-Output $Response
            return
        }
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        if ($null -ne $Response.data) {
            $ResponseContent = $Response.data
        }
        #endregion

        #region Output
        if ($PSCmdlet.ParameterSetName -eq 'OutFile') {
            # create parent directory if it does not exist
            $ParentDirectory = Split-Path $OutFile -Parent
            if (-not $ParentDirectory) {
                $ParentDirectory = [string]$PWD
            }
            if (-not (Test-Path -LiteralPath $ParentDirectory -PathType Container)) {
                $null = New-Item -Path $ParentDirectory -ItemType Directory -Force
            }
            # error check
            if (-not (Test-Path -LiteralPath $ParentDirectory -PathType Container)) {
                Write-Error -Message ('Destination folder "{0}" does not exist.' -f $ParentDirectory)
                return
            }

            # Download image
            $ResponseContent | Select-Object -ExpandProperty 'url' | select -First 1 | % {
                Write-Verbose ('Downloading image to {0}' -f $OutFile)
                Microsoft.PowerShell.Utility\Invoke-WebRequest `
                    -Uri $_ `
                    -Method Get `
                    -OutFile $OutFile `
                    -UseBasicParsing
            }
        }
        elseif ($Format -eq 'url') {
            Write-Output ($ResponseContent | Select-Object -ExpandProperty 'url')
        }
        elseif ($Format -eq 'base64') {
            Write-Output ($ResponseContent | Select-Object -ExpandProperty 'b64_json')
        }
        elseif ($Format -eq 'byte') {
            [byte[]]$b = [Convert]::FromBase64String(($ResponseContent | Select-Object -ExpandProperty 'b64_json' | select -First 1))
            Write-Output (, $b)
        }
        #endregion
    }

    end {

    }
}
