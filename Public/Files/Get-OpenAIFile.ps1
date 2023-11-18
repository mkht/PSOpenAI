function Get-OpenAIFile {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get', Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('file_id')]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$Id,

        [Parameter(ParameterSetName = 'List', Mandatory = $false)]
        [Completions('assistants', 'fine-tune')]
        [ValidateNotNullOrEmpty()]
        [string][LowerCaseTransformation()]$Purpose,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

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
        $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Files' -ApiBase $ApiBase
    }

    process {
        #region Construct Query URI
        if ($PSCmdlet.ParameterSetName -eq 'Get') {
            $QueryUri = $OpenAIParameter.Uri.ToString() + "/$Id"
        }
        else {
            if ($PSBoundParameters.ContainsKey('Purpose')) {
                $QueryParam = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
                $QueryParam.Add('purpose', $Purpose);
                $QueryUri = $OpenAIParameter.Uri.ToString() + '?' + $QueryParam.ToString()
            }
            else {
                $QueryUri = $OpenAIParameter.Uri
            }
        }
        #endregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Get' `
            -Uri $QueryUri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -Organization $Organization

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
        if ($Response.object -eq 'list' -and ($null -ne $Response.data)) {
            # List of object
            $Responses = @($Response.data)
        }
        else {
            # Single object
            $Responses = @($Response)
        }
        # parse objects
        foreach ($res in $Responses) {
            # Add custom type name and properties to output object.
            $res.PSObject.TypeNames.Insert(0, 'PSOpenAI.File')
            if ($null -ne $res.created_at -and ($unixtime = $res.created_at -as [long])) {
                # convert unixtime to [DateTime] for read suitable
                $res | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            Write-Output $res
        }
        #endregion
    }

    end {

    }
}
