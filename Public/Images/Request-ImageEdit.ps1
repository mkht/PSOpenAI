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
            'gpt-image-1-mini',
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

        [Parameter()]
        [ValidateSet('transparent', 'opaque', 'auto')]
        [string][LowerCaseTransformation()]$Background = 'auto',

        [Parameter()]
        [Alias('input_fidelity')]
        [ValidateSet('low', 'high')]
        [string][LowerCaseTransformation()]$InputFidelity = 'low',

        [Parameter()]
        [Alias('output_compression')]
        [ValidateRange(0, 100)]
        [uint16]$OutputCompression = 100,

        [Parameter()]
        [Alias('output_format')]
        [ValidateSet('png', 'jpeg', 'webp')]
        [string][LowerCaseTransformation()]$OutputFormat = 'png',

        [Parameter(ParameterSetName = 'Format')]
        [Alias('response_format')]
        [ValidateSet('url', 'base64', 'byte', 'object')]
        [string]$ResponseFormat = 'url',

        [Parameter(ParameterSetName = 'Format')]
        [switch]$OutputRawResponse,

        [Parameter(ParameterSetName = 'OutFile', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        #region Stream
        [Parameter()]
        [switch]$Stream = $false,

        [Parameter()]
        [Alias('partial_images')]
        [ValidateRange(0, 3)]
        [uint16]$PartialImages = 0,
        #endregion Stream

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Image.Edit' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop

        ## Set up masking patterns
        $MaskPatterns = [System.Collections.Generic.List[Tuple[regex, string]]]::new()
        $MaskPatterns.Add([Tuple[regex, string]]::new('("b64_json":\s")[^\s"]+', '$1<base64-image-data>'))
    }

    process {
        $InputImages = @()

        foreach ($img in $Image) {
            if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::OpenAI) {
                $InputImages += Resolve-FileInfo $img
            }
            else {
                $InputImages += Convert-ImageToDataURL $img
            }
        }

        if ($PSBoundParameters.ContainsKey('Mask')) {
            if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::OpenAI) {
                $MaskImage = Resolve-FileInfo $Mask
            }
            else {
                $MaskImage = Convert-ImageToDataURL $Mask
            }
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

        if ($MaskImage) {
            $PostBody.mask = $MaskImage
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
        if ($PSBoundParameters.ContainsKey('InputFidelity')) {
            $PostBody.input_fidelity = $InputFidelity
        }
        if ($PSBoundParameters.ContainsKey('Background')) {
            $PostBody.background = $Background
        }
        if ($PSBoundParameters.ContainsKey('OutputCompression')) {
            $PostBody.output_compression = $OutputCompression
        }
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        if ($PartialImages -gt 0) {
            $Stream = $true
            $PostBody.partial_images = $PartialImages
        }
        if ($Stream) {
            $PostBody.stream = [bool]$Stream
        }

        # GPT-Image model does not support response_format parameter
        if ($Model -like 'gpt-image-*') {
            if ($PSBoundParameters.ContainsKey('ResponseFormat') -and $ResponseFormat -eq 'url') {
                Write-Warning 'Your specified model does not support response_format=url. Defaulting to object.'
                $ResponseFormat = 'object'
            }
            elseif ($ResponseFormat -eq 'url') {
                $ResponseFormat = 'object'
            }
        }

        switch ($ResponseFormat) {
            { $PSCmdlet.ParameterSetName -eq 'OutFile' } {
                $ResponseFormat = 'base64'
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

        if ($Model -like 'gpt-image-*') {
            # The output_format parameter is only supported for gpt-image-1.
            if ($PSBoundParameters.ContainsKey('OutputFormat')) {
                $PostBody.output_format = $OutputFormat
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'OutFile') {
                $ext = [System.IO.Path]::GetExtension($OutFile).ToLower()
                if ($ext -eq '.png') {
                    $PostBody.output_format = 'png'
                }
                elseif ($ext -eq '.jpeg' -or $ext -eq '.jpg') {
                    $PostBody.output_format = 'jpeg'
                }
                elseif ($ext -eq '.webp') {
                    $PostBody.output_format = 'webp'
                }
                else {
                    $PostBody.output_format = 'png'
                }
            }

            # reponse_formart parameter is not supported for gpt-image-1.
            if ($PostBody.Contains('response_format')) {
                $PostBody.Remove('response_format')
            }
        }
        #endregion

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
            MaskPatterns      = $MaskPatterns
        }

        #region Send API Request (Stream)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequestSSE @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object -Process {
                    if ($OutputRawResponse) {
                        Write-Output $_
                    }
                    else {
                        # Parse response object
                        try {
                            $Response = $_ | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            Write-Error -Exception $_.Exception
                        }

                        if ($Response.type -in ('image_edit.partial_image', 'image_edit.completed') -and $Response.b64_json) {

                            if ($null -ne $Response.partial_image_index) {
                                $pidx = $Response.partial_image_index
                                Write-Verbose ('Partial image generated. Index:{0}' -f $pidx)
                            }
                            else {
                                $pidx = $null
                                Write-Verbose 'Final image generated.'
                            }

                            #region Output
                            if ($PSCmdlet.ParameterSetName -eq 'OutFile') {
                                # Save image
                                $AbsoluteFilePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutFile)
                                $Ext = [System.IO.Path]::GetExtension($AbsoluteFilePath)
                                $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($AbsoluteFilePath)
                                if ($null -ne $pidx) {
                                    $FileName = '{0}-{1}{2}' -f $BaseName, $pidx, $Ext
                                }
                                else {
                                    $FileName = '{0}{1}' -f $BaseName, $Ext
                                }
                                $SaveToPath = Join-Path (Split-Path $AbsoluteFilePath -Parent) $FileName

                                Write-Verbose ('Save image to {0}' -f $SaveToPath)
                                Write-ByteContent -OutFile $SaveToPath -Bytes ([Convert]::FromBase64String($Response.b64_json))
                            }
                            elseif ($ResponseFormat -eq 'object') {
                                ParseImageGenerationObject $Response
                            }
                            elseif ($ResponseFormat -eq 'base64') {
                                Write-Output ($Response.b64_json)
                            }
                            elseif ($ResponseFormat -eq 'byte') {
                                Write-Output (, ([Convert]::FromBase64String(($Response.b64_json))))
                            }
                            #endregion
                        }
                        else {
                            continue
                        }
                    }
                }
            return
        }
        #endregion

        #region Send API Request
        else {
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
                if ($null -ne $Response.error.message) {
                    Write-Error -Message ('API returned error: ({0}) {1}' -f $Response.error.code, $Response.error.message)
                    return
                }
            }
            catch {
                Write-Error -Exception $_.Exception
            }
            #endregion

            #region Output
            if ($ResponseFormat -eq 'object') {
                ParseImageGenerationObject $Response
                return
            }
            else {
                $Suffix = 0
                foreach ($content in $Response.data) {
                    if ($PSCmdlet.ParameterSetName -eq 'OutFile') {
                        $AbsoluteFilePath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutFile)

                        # Save image
                        if ($Suffix -gt 0) {
                            $Ext = [System.IO.Path]::GetExtension($AbsoluteFilePath)
                            $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($AbsoluteFilePath)
                            $FileName = '{0}-{1}{2}' -f $BaseName, $Suffix, $Ext
                            $SaveToPath = Join-Path (Split-Path $AbsoluteFilePath -Parent) $FileName
                        }
                        else {
                            $SaveToPath = $AbsoluteFilePath
                        }

                        Write-Verbose ('Save image to {0}' -f $SaveToPath)
                        Write-ByteContent -OutFile $SaveToPath -Bytes ([Convert]::FromBase64String($content.b64_json))
                        $Suffix++
                    }
                    elseif ($ResponseFormat -eq 'object') {
                        ParseImageGenerationObject $Response
                    }
                    elseif ($ResponseFormat -eq 'url') {
                        Write-Output ($content | Select-Object -ExpandProperty 'url')
                    }
                    elseif ($ResponseFormat -eq 'base64') {
                        Write-Output ($content | Select-Object -ExpandProperty 'b64_json')
                    }
                    elseif ($ResponseFormat -eq 'byte') {
                        Write-Output (, ([Convert]::FromBase64String(($content.b64_json))))
                    }
                }
            }
            #endregion
        }
    }

    end {

    }
}
