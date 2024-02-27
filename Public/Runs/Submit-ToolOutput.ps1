function Submit-ToolOutput {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ ([string]$_.id).StartsWith('run_') -and ([string]$_.thread_id).StartsWith('thread_') })]
        [Alias('Run')]
        [Object]$InputObject,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$ToolOutput,

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
        #region Parameter Validation
        if ($InputObject.status -ne 'requires_action' -or $InputObject.required_action.type -ne 'submit_tool_outputs') {
            Write-Error -Exception ([InvalidOperationException]::new(('Runs in status "{0}" do not accept tool outputs.' -f $InputObject.status)))
            return
        }
        #endregion

        #region Construct Query URI
        [string][UrlEncodeTransformation()]$ThreadId = $InputObject.thread_id
        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
            return
        }
        [string][UrlEncodeTransformation()]$RunId = $InputObject.id
        if (-not $RunId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Run ID.'))
            return
        }

        $QueryUri = ($OpenAIParameter.Uri.ToString() -f $ThreadId)
        $UriBuilder = [System.UriBuilder]::new($QueryUri)
        $UriBuilder.Path += "/$RunId/submit_tool_outputs"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Construct Post Body
        $innerToolOutputs = @()
        foreach ($to in $ToolOutput) {
            if ($to.tool_call_id -as [string] -and $to.output -as [string]) {
                $innerToolOutputs += @{
                    'tool_call_id' = [string]$to.tool_call_id
                    'output'       = [string]$to.output
                }
            }
        }
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.tool_outputs = @($innerToolOutputs)
        #endregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Post' `
            -Uri $QueryUri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -AuthType $AuthType `
            -Organization $Organization `
            -Headers (@{'OpenAI-Beta' = 'assistants=v1' }) `
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
        ParseThreadRunStepObject $Response -CommonParams $CommonParams
        #endregion
    }

    end {
    }
}
