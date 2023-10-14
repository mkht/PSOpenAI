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
        [Completions('text-embedding-ada-002', 'text-search-ada-doc-001')]
        [string][LowerCaseTransformation()]$Model = 'text-embedding-ada-002',

        [Parameter()]
        [string]$User,

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
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Embeddings' -Engine $Model -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Embeddings' -ApiBase $ApiBase
        }
    }

    process {
        # Text is required
        if ($null -eq $Text -or $Text.Count -eq 0) {
            Write-Error -Exception ([System.ArgumentException]::new('"Text" property is required.'))
            return
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($ApiType -eq [OpenAIApiType]::OpenAI) {
            $PostBody.model = $Model
        }
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
            -ApiKey $SecureToken `
            -AuthType $AuthType `
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
