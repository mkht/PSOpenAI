function New-AzureOpenAIDeployments {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string][LowerCaseTransformation()]$Model,

        [Parameter()]
        [ValidateSet('standard', 'manual')]
        [string][LowerCaseTransformation()]$ScaleType = 'standard',

        [Parameter()]
        [int]$ScaleCapacity = 1,

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
        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        $PostBody.scale_settings = @{'scale_type' = $ScaleType }
        if ($ScaleType -eq 'manual') {
            $PostBody.scale_settings['capacity'] = $ScaleCapacity
        }
        #endregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Post' `
            -Uri $OpenAIParameter.Uri `
            -ContentType $OpenAIParameter.ContentType `
            -ApiKey $SecureToken `
            -AuthType $AuthType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -Body $PostBody

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
