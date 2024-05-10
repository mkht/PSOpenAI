function Get-OpenAIFileContent {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType([byte[]])]
    param (
        [Parameter(ParameterSetName = 'File', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.File')]$File,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('file_id')]
        [Alias('Id')]   # for backword compatibility
        [string][UrlEncodeTransformation()]$FileId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

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
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey -ErrorAction Stop

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType ([OpenAIApiType]::OpenAI) -ErrorAction Stop

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API context
        $OpenAIParameter = Get-OpenAIContext -EndpointName 'Files' -ApiType $ApiType -AuthType $AuthType -ApiBase $ApiBase -ApiVersion $ApiVersion -ErrorAction Stop
    }

    process {
        # Get file id
        if ($PSCmdlet.ParameterSetName -ceq 'File') {
            $FileId = $File.id
        }
        if (-not $FileId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve file id.'))
            return
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$FileId/content"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Get'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $TimeoutSec
            MaxRetryCount     = $MaxRetryCount
            ApiKey            = $SecureToken
            Organization      = $Organization
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIAPIRequest @params

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Output
        if ($OutFile) {
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
        }
        else {
            Write-Output $Response
        }
        #endregion
    }

    end {

    }
}
