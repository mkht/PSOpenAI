function Get-AzureOpenAIDeployments {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
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
        [int]$MaxRetryCount = 0
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-AzureAPIBase -ApiBase $ApiBase

        # Get API endpoint
        $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Deployments' -ApiBase $ApiBase -ApiVersion $ApiVersion
    }

    process {
        if ($Deployment) {
            $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
            $UriBuilder.Path += "/$Deployment"
            $OpenAIParameter.Uri = $UriBuilder.Uri
        }

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Get' `
            -Uri $OpenAIParameter.Uri `
            -ApiKey $SecureToken `
            -AuthType $AuthType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Parse response object
        $Response = try { ($Response | ConvertFrom-Json -ErrorAction Ignore) }catch { Write-Error -Exception $_.Exception }
        if ($Response.data.Count -ge 1) {
            $Deployments = @($Response.data)
        }
        else {
            $Deployments = @($Response)
        }
        #endregion

        #region Output
        foreach ($m in $Deployments) {
            if ($null -eq $m) { continue }
            # Add custom type name and properties to output object.
            # $m.PSObject.TypeNames.Insert(0, 'PSOpenAI.Model')
            if ($unixtime = $m.created_at -as [long]) {
                # convert unixtime to [DateTime] for read suitable
                $m | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            if ($unixtime = $m.updated_at -as [long]) {
                # convert unixtime to [DateTime] for read suitable
                $m | Add-Member -MemberType NoteProperty -Name 'updated_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            Write-Output $m
        }
        #endregion
    }

    end {

    }
}
