function Submit-ToolOutput {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Run', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backward compatibility
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('run_id')]
        [string][UrlEncodeTransformation()]$RunId,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

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

        [Parameter()]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
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
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Runs' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -ceq 'Run') {
            $ThreadId = $Run.thread_id
            $RunId = $Run.id
        }
        else {
            $Run = PSOpenAI\Get-ThreadRun -RunId $RunId -ThreadId $ThreadId @CommonParams
        }
        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
            return
        }
        if (-not $RunId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Run ID.'))
            return
        }

        #region Parameter Validation
        if ($Run.status -ne 'requires_action' -or $Run.required_action.type -ne 'submit_tool_outputs') {
            Write-Error -Exception ([InvalidOperationException]::new(('Runs in status "{0}" does not accept tool outputs.' -f $Run.status)))
            return
        }
        #endregion

        #region Construct Query URI
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

        $splat = @{
            Method            = 'Post'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }

        #region Send API Request (Streaming)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequestSSE @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object {
                    if ($Format -eq 'raw_response') {
                        $_
                    }
                    elseif ($_.Contains('"object":"thread.message.delta"')) {
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

        #region Send API Request (No Stream)
        else {
            $Response = Invoke-OpenAIAPIRequest @splat

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
    }

    end {
    }
}
