function Get-OpenAIModels {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [Alias('ID')]
        [Alias('Model')]
        [string][LowerCaseTransformation()]$Name,

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
        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Models' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Models' -ApiBase $ApiBase
        }
    }

    process {
        if ($Name) {
            $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
            $UriBuilder.Path = $UriBuilder.Path.TrimEnd('/') + "/$Name"
            $OpenAIParameter.Uri = $UriBuilder.Uri
        }

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method $OpenAIParameter.Method `
            -Uri $OpenAIParameter.Uri `
            -ApiKey $SecureToken `
            -AuthType $AuthType `
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
            if ($ApiType -eq [OpenAIApiType]::OpenAI) {
                $m.PSObject.TypeNames.Insert(0, 'PSOpenAI.Model')
            }
            if ($unixtime = $m.created -as [long]) {
                # convert unixtime to [DateTime] for read suitable
                $m | Add-Member -MemberType NoteProperty -Name 'created' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
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
