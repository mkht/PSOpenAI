function Get-OpenAIFileContent {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('file_id')]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$Id,

        [Parameter(ParameterSetName = 'OutFile')]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

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
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Files' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Files' -ApiBase $ApiBase
        }
    }

    process {
        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$Id/content"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Get' `
            -Uri $QueryUri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -Organization $Organization `
            -AdditionalQuery $AdditionalQuery -AdditionalHeaders $AdditionalHeaders -AdditionalBody $AdditionalBody

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Output
        if ($PSCmdlet.ParameterSetName -eq 'OutFile') {
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
