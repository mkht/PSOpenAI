function Request-Embeddings {
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
        [string]$Model = 'text-embedding-ada-002',

        [Parameter()]
        [string]$User,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [object]$Token
    )

    begin {
        # Initialize API token
        [securestring]$SecureToken = Initialize-APIToken -Token $Token

        # Get API endpoint
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Embeddings'
    }

    process {
        # Text is required
        if ($null -eq $Text -or $Text.Count -eq 0) {
            Write-Error -Exception ([System.ArgumentException]::new('"Text" property is required.'))
            return
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        if ($Text.Count -eq 1) {
            $PostBody.input = [string](@($Text)[0])
        }
        else {
            $PostBody.input = $Text
        }
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        #endregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method $OpenAIParameter.Method `
            -Uri $OpenAIParameter.Uri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -Token $SecureToken `
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
            for ($i = 0; $i -lt @($Response.data).Count; $i++) {
                # Convert [Object[]] to [float[]]
                @($Response.data)[$i].embedding = [float[]]@($Response.data)[$i].embedding
                # Add custom properties to output object.
                @($Response.data)[$i] | Add-Member -MemberType NoteProperty -Name 'Text' -Value @($Text)[$i]
            }
            Write-Output $Response
        }
        #endregion
    }

    end {

    }
}