function Request-ImageEdit {
    [CmdletBinding(DefaultParameterSetName = 'Format')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('File')]
        [string[]]$Image,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Mask,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Prompt,

        [Parameter()]
        [Completions(
            'gpt-image-1',
            'dall-e-2'
        )]
        [string]$Model = 'dall-e-2',

        [Parameter()]
        [ValidateRange(1, 10)]
        [Alias('n')]
        [uint16]$NumberOfImages = 1,

        [Parameter()]
        [ValidateSet('auto', '1024x1024', '1536x1024', '1024x1536', '256x256', '512x512')]
        [string]$Size = 'auto',

        [Parameter()]
        [ValidateSet('standard', 'low', 'medium', 'high', 'auto')]
        [string][LowerCaseTransformation()]$Quality = 'auto',

        [Parameter(ParameterSetName = 'Format')]
        [Alias('response_format')]
        [ValidateSet('url', 'base64', 'byte')]
        [string]$ResponseFormat = 'url',

        [Parameter(ParameterSetName = 'Format')]
        [switch]$OutputRawResponse,

        [Parameter(ParameterSetName = 'OutFile', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        # [Parameter(DontShow)]
        # [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        # [Parameter(DontShow)]
        # [string]$ApiVersion,

        # [Parameter(DontShow)]
        # [string]$AuthType = 'openai',

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
        # Get API endpoint
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Image.Edit' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        $InputImages = @()
        foreach ($img in $Image) {
            $InputImages += Resolve-FileInfo $img
        }

        if ($PSBoundParameters.ContainsKey('Mask')) {
            $MaskFileInfo = Resolve-FileInfo $Mask
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.prompt = $Prompt

        if ( $InputImages.Count -gt 1) {
            $PostBody.image = $InputImages
        }
        else {
            $PostBody.image = $InputImages[0]
        }

        if ($MaskFileInfo) {
            $PostBody.mask = $MaskFileInfo
        }

        if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::OpenAI) {
            if ($PSBoundParameters.ContainsKey('Model')) {
                $PostBody.model = $Model
            }
        }

        if ($PSBoundParameters.ContainsKey('NumberOfImages')) {
            $PostBody.n = $NumberOfImages
        }
        if ($PSBoundParameters.ContainsKey('Size')) {
            $PostBody.size = $Size
        }
        if ($PSBoundParameters.ContainsKey('Quality')) {
            $PostBody.quality = $Quality
        }
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }

        switch ($ResponseFormat) {
            { $Model -like 'gpt-image-*' } {
                # GPT-Image model does not support response_format parameter
                break
            }
            { $PSCmdlet.ParameterSetName -eq 'OutFile' } {
                $PostBody.response_format = 'b64_json'
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
        #endregion

        #region Send API Request
        $splat = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
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

        #region Parse response object
        if ($OutputRawResponse) {
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
            $AbsoluteFilePath = New-ParentFolder -File $OutFile

            # Save image
            $ResponseContent | Select-Object -ExpandProperty 'b64_json' | ForEach-Object -Begin { $Suffix = 0 } -Process {
                if ( $Suffix -gt 0) {
                    $Ext = [System.IO.Path]::GetExtension($AbsoluteFilePath)
                    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($AbsoluteFilePath)
                    $FileName = '{0}-{1}{2}' -f $BaseName, $Suffix, $Ext
                    $SaveToPath = Join-Path (Split-Path $AbsoluteFilePath -Parent) $FileName
                }
                else {
                    $SaveToPath = $AbsoluteFilePath
                }

                Write-Verbose ('Save image to {0}' -f $SaveToPath)
                try {
                    [System.IO.File]::WriteAllBytes($SaveToPath, [Convert]::FromBase64String($_))
                }
                catch {
                    Write-Error -Exception $_.Exception
                }
                $Suffix++
            }
        }
        elseif ($ResponseFormat -eq 'url') {
            Write-Output ($ResponseContent | Select-Object -ExpandProperty 'url')
        }
        elseif ($ResponseFormat -eq 'base64') {
            Write-Output ($ResponseContent | Select-Object -ExpandProperty 'b64_json')
        }
        elseif ($ResponseFormat -eq 'byte') {
            $ByteArrayList = [System.Collections.Generic.List[byte[]]]::new()
            $ResponseContent | Select-Object -ExpandProperty 'b64_json' | ForEach-Object {
                $ByteArrayList.Add([Convert]::FromBase64String($_))
            }

            if ( $ByteArrayList.Count -eq 1) {
                Write-Output ($ByteArrayList[0])
            }
            else {
                Write-Output ($ByteArrayList.ToArray())
            }
        }
        #endregion
    }

    end {

    }
}
