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

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType ([OpenAIApiType]::OpenAI)

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Files' -ApiBase $ApiBase
    }

    process {
        $QueryUri = $OpenAIParameter.Uri.ToString() + "/$Id/content"

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Get' `
            -Uri $QueryUri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -Organization $Organization

        # error check
        if ($null -eq $Response) {
            return
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

            # Output file
            try {
                [System.IO.File]::WriteAllBytes($OutFile, ([byte[]]$Response))
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
