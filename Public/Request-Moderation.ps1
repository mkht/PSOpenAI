function Request-Moderation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        <#
          In OpenAI's API, this corresponds to the "Input" parameter name.
          But avoid using the variable name $Input for variable name,
          because it is used as an automatic variable in PowerShell.
        #>
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Input')]
        [string[]]$Text,

        [Parameter()]
        [Completions('text-moderation-latest', 'text-moderation-stable')]
        [string][LowerCaseTransformation()]$Model,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

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
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType [OpenAIApiType]::OpenAI

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Moderation' -ApiBase $ApiBase
    }

    process {
        # Text is required
        if ($null -eq $Text -or $Text.Count -eq 0) {
            Write-Error -Exception ([System.ArgumentException]::new('"Text" property is required.'))
            return
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($Text.Count -eq 1) {
            $PostBody.input = [string](@($Text)[0])
        }
        else {
            $PostBody.input = $Text
        }
        if ($PSBoundParameters.ContainsKey('Model')) {
            $PostBody.model = $Model
        }
        #endregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method $OpenAIParameter.Method `
            -Uri $OpenAIParameter.Uri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -Organization $Organization `
            -Body $PostBody

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Parse response object
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        #region Output
        if ($null -ne $Response) {
            # Add custom type name and properties to output object.
            $Response.PSObject.TypeNames.Insert(0, 'PSOpenAI.Moderation')
            for ($i = 0; $i -lt @($Response.results).Count; $i++) {
                @($Response.results)[$i] | Add-Member -MemberType NoteProperty -Name 'Text' -Value @($Text)[$i]

                # Output a warning message when input text violates the content policy
                if (@($Response.results)[$i].flagged -eq $true) {
                    $Violate = @($Response.results)[$i].categories.psobject.Properties.Where({ $_.Value -eq $true }).Name -join ', '
                    Write-Warning "This content may violate the content policy. ($Violate)"
                }
            }
            Write-Output $Response
        }
        #endregion
    }

    end {

    }
}
