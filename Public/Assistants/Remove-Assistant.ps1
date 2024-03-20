function Remove-Assistant {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('assistant_id')]
        [Alias('Assistant')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('asst_', [StringComparison]::Ordinal)) -or `
                ($_.id -is [string] -and $_.id.StartsWith('asst_', [StringComparison]::Ordinal)) -or `
                ($_.assistant_id -is [string] -and $_.assistant_id.StartsWith('asst_', [StringComparison]::Ordinal))
            })]
        [Object]$InputObject,

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
        [string]$Organization,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Assistants' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Assistants' -ApiBase $ApiBase
        }
    }

    process {
        # Get assistant_id
        $AssistantId = ''
        if ($InputObject -is [string]) {
            $AssistantId = $InputObject
        }
        elseif ($InputObject.id -is [string] -and $InputObject.id.StartsWith('asst_', [StringComparison]::Ordinal)) {
            $AssistantId = $InputObject.id
        }
        elseif ($InputObject.assistant_id -is [string] -and $InputObject.assistant_id.StartsWith('asst_', [StringComparison]::Ordinal)) {
            $AssistantId = $InputObject.assistant_id
        }
        if (-not $AssistantId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Assistant ID.'))
            return
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$AssistantId"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Delete' `
            -Uri $QueryUri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -AuthType $AuthType `
            -Organization $Organization `
            -Headers (@{'OpenAI-Beta' = 'assistants=v1' }) `
            -AdditionalQuery $AdditionalQuery -AdditionalHeaders $AdditionalHeaders -AdditionalBody $AdditionalBody

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

        #region Verbose Output
        if ($Response.deleted) {
            Write-Verbose ('The assistant with id "{0}" has been deleted.' -f $Response.id)
        }
        #endregion
    }

    end {

    }
}
