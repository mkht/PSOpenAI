function Get-ThreadRun {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('run_id')]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$RunId,

        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('thread_id')]
        [Alias('Thread')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('thread_', [StringComparison]::Ordinal)) -or `
                ($_.id -is [string]) -or `
                ($_.thread_id -is [string] -and $_.thread_id.StartsWith('thread_', [StringComparison]::Ordinal))
            })]
        [Object]$InputObject,

        [Parameter(ParameterSetName = 'List')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'ListAll')]
        [switch]$All,

        [Parameter(ParameterSetName = 'ListAll', DontShow = $true)]
        [string]$After,

        [Parameter(ParameterSetName = 'ListAll', DontShow = $true)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List')]
        [Parameter(ParameterSetName = 'ListAll')]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

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

        [Parameter(DontShow = $true)]
        [switch]$Primitive,

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
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Runs' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Runs' -ApiBase $ApiBase
        }

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get thread_id
        [string][UrlEncodeTransformation()]$ThreadID = ''
        if ($InputObject -is [string]) {
            $ThreadID = $InputObject
        }
        elseif ($InputObject.id -is [string] -and $InputObject.id.StartsWith('thread_', [StringComparison]::Ordinal)) {
            $ThreadID = $InputObject.id
        }
        elseif ($InputObject.thread_id -is [string] -and $InputObject.thread_id.StartsWith('thread_', [StringComparison]::Ordinal)) {
            $ThreadID = $InputObject.thread_id
        }
        if (-not $ThreadID) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
            return
        }

        # Get run_id (otional)
        if (-not $RunId) {
            if ($InputObject.id -is [string] -and $InputObject.id.StartsWith('run_', [StringComparison]::Ordinal)) {
                $RunId = $InputObject.id
            }
            elseif ($InputObject.run_id -is [string] -and $InputObject.run_id.StartsWith('run_', [StringComparison]::Ordinal)) {
                $RunId = $InputObject.run_id
            }
        }

        #region Construct Query URI
        $QueryUri = ($OpenAIParameter.Uri.ToString() -f $ThreadID)
        $UriBuilder = [System.UriBuilder]::new($QueryUri)
        if ($RunId.StartsWith('run_', [StringComparison]::Ordinal)) {
            $UriBuilder.Path += "/$RunId"
            $QueryUri = $UriBuilder.Uri
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ListAll') {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $QueryParam.Add('limit', '100');
            $QueryParam.Add('order', $Order);
            if ($After) {
                $QueryParam.Add('after', $After);
            }
            if ($Before) {
                $QueryParam.Add('before', $Before);
            }
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }
        else {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $QueryParam.Add('limit', $Limit);
            $QueryParam.Add('order', $Order);
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }
        #enregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Get' `
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
            ParseThreadRunObject $res -CommonParams $CommonParams -Primitive:$Primitive
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($PSCmdlet.ParameterSetName -eq 'ListAll') {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                PSOpenAI\Get-ThreadRun @PagenationParam
            }
            else {
                Write-Warning 'There is more data that has not been retrieved.'
            }
        }
        #endregion
    }

    end {

    }
}
