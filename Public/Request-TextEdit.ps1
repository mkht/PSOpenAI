function Request-TextEdit {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Message')]
        [string]$Instruction,

        <#
          In OpenAI's API, this corresponds to the "Input" parameter name.
          But avoid using the variable name $Input for variable name,
          because it is used as an automatic variable in PowerShell.
        #>
        [Parameter()]
        [AllowEmptyString()]
        [Alias('Input')]
        [string]$Text = '',

        [Parameter()]
        [Completions('text-davinci-edit-001', 'code-davinci-edit-001')]
        [string][LowerCaseTransformation()]$Model = 'text-davinci-edit-001',

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [Alias('n')]
        [uint16]$NumberOfAnswers,

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
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Text.Edit'
    }

    process {
        # Instruction is required
        if ([string]::IsNullOrWhiteSpace($Instruction)) {
            Write-Error -Exception ([System.ArgumentException]::new('"Instruction" property is required.'))
            return
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        $PostBody.instruction = $Instruction
        if ($PSBoundParameters.ContainsKey('Text')) {
            $PostBody.input = $Text
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $PostBody.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('TopP')) {
            $PostBody.top_p = $TopP
        }
        if ($PSBoundParameters.ContainsKey('NumberOfAnswers')) {
            $PostBody.n = $NumberOfAnswers
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
        if ($null -ne $Response.choices) {
            $ResponseContent = $Response.choices
        }
        #endregion

        #region Output
        # Add custom type name and properties to output object.
        $Response.PSObject.TypeNames.Insert(0, 'PSOpenAI.Text.Edit')
        if ($unixtime = $Response.created -as [long]) {
            # convert unixtime to [DateTime] for read suitable
            $Response | Add-Member -MemberType NoteProperty -Name 'created' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
        $Response | Add-Member -MemberType NoteProperty -Name 'Text' -Value $Text
        $Response | Add-Member -MemberType NoteProperty -Name 'Instruction' -Value $Instruction
        $Response | Add-Member -MemberType NoteProperty -Name 'Answer' -Value ([string[]]$ResponseContent.text)
        Write-Output $Response
        #endregion
    }

    end {

    }
}
