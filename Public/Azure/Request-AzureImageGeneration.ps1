function Request-AzureImageGeneration {
    [CmdletBinding(DefaultParameterSetName = 'Format')]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Prompt,

        [Parameter(Mandatory = $false)]
        [Alias('Model')]
        [ValidateNotNullOrEmpty()]
        [string]$Deployment,

        [Parameter()]
        [ValidateRange(1, 5)]
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

        [Parameter(ParameterSetName = 'OutFile', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [string]$ApiVersion,

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [ValidateSet('azure', 'azure_ad')]
        [string]$AuthType = 'azure',

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        $EndpointMode = 'Legacy'
        # Legacy (DALL-E 2)
        if (-not $PSBoundParameters.ContainsKey('Deployment')) {
            $EndpointMode = 'Legacy'
            # Initialize API Key
            [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

            # Initialize API Base
            $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType ([OpenAIApiType]::Azure)

            # Get API endpoint
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Image.Generation.Legacy' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }

        # Modern (DALL-E 3 and above)
        else {
            $EndpointMode = 'Modern'
            # Construct parameters
            $Parameters = $PSBoundParameters
            $Parameters.ApiType = [OpenAIApiType]::Azure
            $Parameters.AuthType = $AuthType
            $Parameters.Model = $Deployment
            $null = $Parameters.Remove('Deployment')

            # Invoke Request-ImageGeneration
            $steppablePipeline = {
                Request-ImageGeneration @Parameters
            }.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
    }

    process {
        # Legacy (DALL-E 2)
        if ($EndpointMode -eq 'Legacy') {
            $Format = 'url' # Legacy endpoint only supports url format.
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
            if ($PSBoundParameters.ContainsKey('User')) {
                $PostBody.user = $User
            }
            #endregion

            # Create cancellation token for timeout
            $Cancellation = [System.Threading.CancellationTokenSource]::new()
            if ($TimeoutSec -gt 0) {
                $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
            }

            #region Send API Request
            $params = @{
                Method            = $OpenAIParameter.Method
                Uri               = $OpenAIParameter.Uri
                ContentType       = $OpenAIParameter.ContentType
                TimeoutSec        = $TimeoutSec
                MaxRetryCount     = $MaxRetryCount
                ApiKey            = $SecureToken
                AuthType          = $AuthType
                Body              = $PostBody
                ReturnRawResponse = $true
                AdditionalQuery   = $AdditionalQuery
                AdditionalHeaders = $AdditionalHeaders
                AdditionalBody    = $AdditionalBody
            }
            $Response = Invoke-OpenAIAPIRequest @params

            # error check
            if ($null -eq $Response -or $Response.StatusDescription -ne 'Accepted') {
                if ($null -ne $Cancellation) { $Cancellation.Dispose() }
                Write-Error -Exception ([System.InvalidOperationException]::new(('Invalid response received. (Response: {0})' -f $Response.StatusDescription)))
                return
            }
            #endregion

            #region Parse response object
            $NextLocation = ([string]$Response.Headers['operation-location']) -as [uri]
            if (-not $NextLocation.AbsoluteUri) {
                if ($null -ne $Cancellation) { $Cancellation.Dispose() }
                Write-Error -Exception ([System.InvalidOperationException]::new('Invalid response received. (operation-location not found.)'))
                return
            }
            Write-Verbose ('The task is queued. (Operation-ID: {0})' -f $NextLocation.Segments[-1])
            #endregion

            # Wait for task complete
            $ResponseContent = $null
            $Status = ''
            $StopStatus = @('canceled', 'failed', 'deleted')
            $Interval = 200
            $InitialWait = if ($Response.Headers.ContainsKey('Retry-After') -and $Response.Headers['Retry-After'] -as [uint16]) {
            ([uint16]$Response.Headers['Retry-After']) * 1000
            }
            else {
                0
            }

            try {
                Write-Verbose ('Waiting for the task completed...')
                Start-CancelableWait -Milliseconds $InitialWait -CancellationToken $Cancellation.Token -ea Stop
                while ($Status -ne 'succeeded') {
                    Start-CancelableWait -Milliseconds $Interval -CancellationToken $Cancellation.Token -ea Stop
                    $ResponseContent = $null
                    $params = @{
                        Method            = 'Get'
                        Uri               = $NextLocation
                        TimeoutSec        = $TimeoutSec
                        ApiKey            = $SecureToken
                        AuthType          = $AuthType
                        AdditionalQuery   = $AdditionalQuery
                        AdditionalHeaders = $AdditionalHeaders
                        AdditionalBody    = $AdditionalBody
                        Verbose           = $false
                    }
                    $SubResponse = Invoke-OpenAIAPIRequest @params
                    if ($null -ne $SubResponse) {
                        $ResponseContent = $SubResponse | ConvertFrom-Json -ea Stop
                    }
                    $Status = $ResponseContent.status

                    if ($Status -in $StopStatus) {
                        throw [System.InvalidOperationException]::new(('The operation was failed. (Status: {0})' -f $Status))
                    }
                }
            }
            catch [OperationCanceledException] {
                Write-Error -ErrorRecord $_
                return
            }
            catch {
                Write-Error -Exception $_.Exception
                return
            }
            finally {
                if ($null -ne $Cancellation) {
                    $Cancellation.Dispose()
                }
            }

            if ($null -eq $ResponseContent) {
                return
            }

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
                $ResponseContent.result.data | Select-Object -ExpandProperty 'url' | Select-Object -First 1 | ForEach-Object {
                    Write-Verbose ('Downloading image to {0}' -f $OutFile)
                    $params = @{
                        Uri             = $_
                        Method          = 'Get'
                        OutFile         = $OutFile
                        UseBasicParsing = $true
                    }
                    Microsoft.PowerShell.Utility\Invoke-WebRequest @params
                }
            }
            elseif ($Format -eq 'url') {
                Write-Output $ResponseContent.result.data.url
            }
            #endregion
        }

        # Modern (DALL-E 3 and above)
        else {
            $steppablePipeline.Process($PSItem)
        }
    }

    end {
        # Legacy (DALL-E 2)
        if ($EndpointMode -eq 'Legacy') {
        }
        # Modern (DALL-E 3 and above)
        else {
            $steppablePipeline.End()
        }
    }
}
