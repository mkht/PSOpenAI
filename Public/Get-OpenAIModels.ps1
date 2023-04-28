function Get-OpenAIModels {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [Alias('ID')]
        [Alias('Model')]
        [string]$Name,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [Alias('Token')]  #for backword compatibility
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Models'
    }

    process {
        if ($Name) {
            $Name = $Name.ToLower()
            $OpenAIParameter.Uri = $OpenAIParameter.Uri + "/$Name"
        }

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method $OpenAIParameter.Method `
            -Uri $OpenAIParameter.Uri `
            -ApiKey $SecureToken `
            -Organization $Organization `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Parse response object
        $Response = try { ($Response | ConvertFrom-Json -ErrorAction Ignore) }catch { Write-Error -Exception $_.Exception }
        if ($Response.object -eq 'list') {
            $Models = @($Response.data)
        }
        else {
            $Models = @($Response)
        }
        #endregion

        #region Output
        foreach ($m in $Models) {
            if ($null -eq $m) { continue }
            # Add custom type name and properties to output object.
            $m.PSObject.TypeNames.Insert(0, 'PSOpenAI.Model')
            if ($unixtime = $m.created -as [long]) {
                # convert unixtime to [DateTime] for read suitable
                $m | Add-Member -MemberType NoteProperty -Name 'created' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            Write-Output $m
        }
        #endregion
    }

    end {

    }
}
