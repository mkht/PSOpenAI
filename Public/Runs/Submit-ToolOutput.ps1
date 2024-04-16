function Submit-ToolOutput {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({ ([string]$_.id).StartsWith('run_', [StringComparison]::Ordinal) -and ([string]$_.thread_id).StartsWith('thread_', [StringComparison]::Ordinal) })]
        [Alias('Run')]
        [Object]$InputObject,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$ToolOutput,

        [Parameter()]
        [switch]$Stream,

        [Parameter()]
        [ValidateSet('default', 'raw_response')]
        [string]$Format = 'default',

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter(DontShow)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter(DontShow)]
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
        if ($Stream) {
            $PostBody.stream = $true
        }
        #endregion

        #region Send API Request (Streaming)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequest `
                -Method 'Post' `
                -Uri $QueryUri `
                -ContentType $OpenAIParameter.ContentType `
                -TimeoutSec $TimeoutSec `
                -MaxRetryCount $MaxRetryCount `
                -ApiKey $SecureToken `
                -AuthType $AuthType `
                -Organization $Organization `
                -Headers (@{'OpenAI-Beta' = 'assistants=v1' }) `
                -Body $PostBody `
                -Stream $Stream `
                -AdditionalQuery $AdditionalQuery -AdditionalHeaders $AdditionalHeaders -AdditionalBody $AdditionalBody |`
                Where-Object {
                -not [string]::IsNullOrEmpty($_)
            } | ForEach-Object {
                if ($Format -eq 'raw_response') {
                    $_
                }
                elseif ($_.Contains('"object":"thread.message.delta"', [StringComparison]::OrdinalIgnoreCase)) {
                    try {
                        $deltaObj = $_ | ConvertFrom-Json -ErrorAction Stop
                    }
                    catch {
                        Write-Error -Exception $_.Exception
                    }
                    @($deltaObj.delta.content.Where({ $_.type -eq 'text' }))[0]
                }
            } | Where-Object {
                $Format -eq 'raw_response' -or ($null -ne $_.text)
            } | ForEach-Object -Process {
                if ($Format -eq 'raw_response') {
                    Write-Output $_
                }
                else {
                    # Writes content to both the Information stream(6>) and the Standard output stream(1>).
                    $InfoMsg = [System.Management.Automation.HostInformationMessage]::new()
                    $InfoMsg.Message = $_.text.value
                    $InfoMsg.NoNewLine = $true
                    Write-Information $InfoMsg
                    Write-Output $InfoMsg.Message
                }
            }

            return
        }
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
            -Body $PostBody `
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
        ParseThreadRunStepObject $Response -CommonParams $CommonParams
        #endregion
    }

    end {
    }
}
