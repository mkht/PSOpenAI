function Register-OpenAIFile {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$File,

        [Parameter(Mandatory = $true)]
        [Completions('assistants', 'fine-tune')]
        [ValidateNotNullOrEmpty()]
        [string][LowerCaseTransformation()]$Purpose,

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
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType ([OpenAIApiType]::OpenAI)

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Files' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Files' -ApiBase $ApiBase
        }
    }

    process {
        $FileInfo = (Get-Item -LiteralPath $File)

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.file = $FileInfo
        $PostBody.purpose = $Purpose
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
        # Add custom type name and properties to output object.
        $Response.PSObject.TypeNames.Insert(0, 'PSOpenAI.File')
        if ($null -ne $Response.created_at -and ($unixtime = $Response.created_at -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $Response | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
        Write-Output $Response
        #endregion
    }

    end {

    }
}
