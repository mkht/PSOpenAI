function Remove-AzureOpenAIDeployments {
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Engine', 'id')]
        [string]$Deployment,

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
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [Switch]$Force
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-AzureAPIBase -ApiBase $ApiBase

        # Get API endpoint
        $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Deployments' -ApiBase $ApiBase -ApiVersion $ApiVersion

        # Set Confirm flag
        if ($Force -and -not $Confirm) {
            $ConfirmPreference = 'None'
        }
    }

    process {
        if ($Deployment) {
            $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
            $UriBuilder.Path += "/$Deployment"
            $OpenAIParameter.Uri = $UriBuilder.Uri
        }

        #region Send API Request
        # Delete is risky process, need to confirm.
        if ($PSCmdlet.ShouldProcess($Deployment, 'Delete')) {
            $null = Invoke-OpenAIAPIRequest `
                -Method 'Delete' `
                -Uri $OpenAIParameter.Uri `
                -ApiKey $SecureToken `
                -AuthType $AuthType `
                -TimeoutSec $TimeoutSec `
                -MaxRetryCount $MaxRetryCount
        }
        #endregion
    }

    end {

    }
}
