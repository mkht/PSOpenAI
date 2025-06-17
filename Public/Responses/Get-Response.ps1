function Get-Response {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('InputObject')]
        [Alias('Id')]
        [Alias('Response')]
        [Alias('response_id')]
        [string][UrlEncodeTransformation()]$ResponseId,

        [Parameter()]
        [Completions('file_search_call.results', 'message.input_image.image_url', 'computer_call_output.output.image_url', 'reasoning.encrypted_content')]
        [AllowEmptyCollection()]
        [string[]]$Include,

        #region Stream
        [Parameter()]
        [switch]$Stream = $false,

        [Parameter()]
        [ValidateSet('text', 'object')]
        [string]$StreamOutputType = 'text',

        [Parameter()]
        [Alias('starting_after')]
        [int]$StartingAfter,
        #endregion Stream

        [Parameter()]
        [switch]$OutputRawResponse,

        # For internal use
        [Parameter(DontShow)]
        [switch]$Primitive,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Responses' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$ResponseId"
        $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)

        if ($Stream) {
            $QueryParam.Add('stream', ($Stream.ToString().ToLowerInvariant()))
        }
        if ($PSBoundParameters.ContainsKey('StartingAfter')) {
            $QueryParam.Add('starting_after', $StartingAfter)
        }
        if ($PSBoundParameters.ContainsKey('Include')) {
            foreach ($IncludeItem in $Include) {
                $QueryParam.Add('include[]', $IncludeItem)
            }
        }

        $UriBuilder.Query = $QueryParam.ToString()
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $splat = @{
            Method            = 'Get'
            Uri               = $QueryUri
            # ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }

        #region Send API Request (Stream)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequestSSE @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object -Process {
                    if ($OutputRawResponse) {
                        Write-Output $_
                    }
                    else {
                        # Parse response object
                        try {
                            $Response = $_ | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            Write-Error -Exception $_.Exception
                        }

                        if ($StreamOutputType -eq 'text') {
                            if ($Response.type -cne 'response.output_text.delta') {
                                continue
                            }
                            Write-Output $Response.delta
                        }
                        else {
                            Write-Output $Response
                        }
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
            if ($OutputRawResponse) {
                Write-Output $Response
                return
            }
            try {
                $Response = $Response | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                Write-Error -Exception $_.Exception
                return
            }
            #endregion
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
            # get messages
            $Messages = [System.Collections.Generic.List[object]]::new()

            if (-not $Primitive) {
                Get-ResponseInputItem -ResponseId $res.id -All -Order asc @CommonParams | ForEach-Object {
                    $Messages.Add($_)
                }
            }

            # Add assistant response to messages list.
            if ($res.output.Count -ge 1) {
                $Messages.AddRange(@($res.output))
            }

            # parse object
            ParseResponseObject $res -Messages $Messages -WarningAction Ignore
        }
        #endregion
    }

    end {

    }
}
