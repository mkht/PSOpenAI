function Request-Moderation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        <#
          In OpenAI's API, this corresponds to the "Input" parameter name.
          But avoid using the variable name $Input for variable name,
          because it is used as an automatic variable in PowerShell.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
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
        [string]$Organization,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Get API endpoint
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Moderations' -Parameters $PSBoundParameters -ErrorAction Stop
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
        $params = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            Organization      = $OpenAIParameter.Organization
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIAPIRequest @params

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

