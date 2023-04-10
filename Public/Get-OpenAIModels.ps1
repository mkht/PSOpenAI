function Get-OpenAIModels {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [Alias('ID')]
        [Alias('Model')]
        [string]$Name,

        [Parameter()]
        [object]$Token
    )

    begin {
        # Initialize API token
        [securestring]$SecureToken = Initialize-APIToken -Token $Token

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
            -Token $SecureToken

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Parse response object
        $Response = ($Response | ConvertFrom-Json -ErrorAction Ignore)
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
            # Add custom properties to output object.
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
