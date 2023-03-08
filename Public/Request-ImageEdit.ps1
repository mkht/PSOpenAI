function Request-ImageEdit {
    [CmdletBinding(DefaultParameterSetName = 'Format')]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('File')]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$Image,

        [Parameter()]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$Mask,

        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 1000)]
        [string]$Prompt,

        [Parameter()]
        [ValidateRange(1, 10)]
        [Alias('n')]
        [uint16]$NumberOfImages = 1,

        [Parameter()]
        [ValidateSet('256', '512', '1024', '256x256', '512x512', '1024x1024')]
        [string]$Size = '1024x1024',

        [Parameter(ParameterSetName = 'Format')]
        [Alias('response_format')]
        [ValidateSet('url', 'base64', 'byte')]
        [string]$Format = 'url',

        [Parameter(ParameterSetName = 'OutFile', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [object]$Token
    )

    begin {
        # Initialize API token
        [securestring]$SecureToken = Initialize-APIToken -Token $Token

        # Get API endpoint
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Image.Edit'
    }

    process {
        $ImageFileInfo = (Get-Item -LiteralPath $Image)
        # (Only PS6+)
        # If the filename contains non-ASCII characters,
        # the OpenAI API cannot recognize the file format correctly and returns an error.
        # As a workaround, copy the file to a temporary file and send it.
        # We need to find a better way.
        $IsTempImageFileCreated = $false
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            if ($ImageFileInfo.Name -match '[^\u0000-\u007F]') {
                Write-Warning 'File name contains non-ASCII characters. It is strongly recommended that file name only contains ASCII characters.'
                $ImageFileInfo = Copy-TempFile -SourceFile $ImageFileInfo -ErrorAction Stop
                $IsTempImageFileCreated = $true
            }
        }

        if ($PSBoundParameters.ContainsKey('Mask')) {
            $MaskFileInfo = (Get-Item -LiteralPath $Mask)
            # (Only PS6+)
            # If the filename contains non-ASCII characters,
            # the OpenAI API cannot recognize the file format correctly and returns an error.
            # As a workaround, copy the file to a temporary file and send it.
            # We need to find a better way.
            $IsTempMaskFileCreated = $false
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                if ($MaskFileInfo.Name -match '[^\u0000-\u007F]') {
                    Write-Warning 'File name contains non-ASCII characters. It is strongly recommended that file name only contains ASCII characters.'
                    $MaskFileInfo = Copy-TempFile -SourceFile $MaskFileInfo -ErrorAction Stop
                    $IsTempMaskFileCreated = $true
                }
            }
        }

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
        $PostBody.image = $ImageFileInfo
        $PostBody.prompt = $Prompt
        if ($MaskFileInfo) {
            $PostBody.mask = $MaskFileInfo
        }
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
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        #endregion

        #region Send API Request
        try {
            $Response = Invoke-OpenAIAPIRequest `
                -Method $OpenAIParameter.Method `
                -Uri $OpenAIParameter.Uri `
                -ContentType $OpenAIParameter.ContentType `
                -TimeoutSec $TimeoutSec `
                -Token $SecureToken `
                -Body $PostBody
        }
        finally {
            if ($IsTempImageFileCreated -and (Test-Path $ImageFileInfo -PathType Leaf)) {
                Remove-Item $ImageFileInfo -Force -ErrorAction SilentlyContinue
            }
            if ($IsTempMaskFileCreated -and (Test-Path $MaskFileInfo -PathType Leaf)) {
                Remove-Item $MaskFileInfo -Force -ErrorAction SilentlyContinue
            }
        }
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
        if ($null -ne $Response.data) {
            $ResponseContent = $Response.data
        }
        #endregion

        #region Output
        if ($PSCmdlet.ParameterSetName -eq 'OutFile') {
            # create parent directory if it does not exist
            $ParentDirectory = Split-Path $OutFile -Parent
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
