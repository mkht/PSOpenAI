function Parse-WebExceptionResponse {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
    [OutputType([System.Exception])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ErrorRecord')]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory, ParameterSetName = 'Properties')]
        [int]$ErrorCode,

        [Parameter(Mandatory, ParameterSetName = 'Properties')]
        [string]$ErrorReason,

        [Parameter(ParameterSetName = 'Properties')]
        [object]$ErrorResponse, # System.Net.Http.HttpResponseMessage

        [Parameter(ParameterSetName = 'Properties')]
        [object]$ErrorContent,

        [Parameter(ParameterSetName = 'Properties')]
        [System.Exception]$InnerException,

        [Parameter()]
        [string]$ServiceName = 'OpenAI'
    )

    if ($PSCmdlet.ParameterSetName -eq 'ErrorRecord') {
        $InnerException = $ErrorRecord.Exception
        # For PS 5.1
        if ($InnerException -is [System.Net.WebException]) {
            $ErrorResponse = $InnerException.Response
            if ($null -eq $ErrorResponse.StatusCode) {
                return $InnerException
            }
            $ErrorCode = $ErrorResponse.StatusCode.value__
            $ErrorReason = $ErrorResponse.StatusCode.ToString()
            $ResponseStream = $ErrorResponse.GetResponseStream()
            $ResponseStream.Position = 0
            $Reader = [System.IO.StreamReader]::new($ResponseStream)
            $Body = try { $Reader.ReadToEnd() }finally { if ($null -ne $Reader) { $Reader.Close() } }
            $ErrorContent = try { ($Body | ConvertFrom-Json -ErrorAction Ignore) }catch {}
        }
        # For PS 6+ or SSE
        elseif ($InnerException -is [System.Net.Http.HttpRequestException]) {
            $ErrorResponse = $InnerException.Response
            if ($null -eq $ErrorResponse.StatusCode) {
                return $InnerException
            }
            $ErrorCode = $ErrorResponse.StatusCode.value__
            $ErrorReason = $ErrorResponse.ReasonPhrase
            $ErrorContent = try { ($ErrorRecord.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Ignore) }catch {}
        }
        else {
            return $InnerException
        }
    }

    if ($ErrorContent.error.message) {
        $ErrorMessage = $ErrorContent.error.message
    }
    elseif ($InnerException.Message) {
        $ErrorMessage = $InnerException.Message
    }
    else {
        $ErrorMessage = $ErrorReason
    }

    $ErrorMessage = ('{3} API returned an {0} ({1}) Error: {2}' -f $ErrorCode, $ErrorReason, $ErrorMessage, $ServiceName)

    switch ($ErrorCode) {
        400 {
            if ($ErrorContent.error.code -eq 'content_filter') {
                $ex = [ContentFilteredException]::new($ErrorMessage, $ErrorResponse , $ErrorContent, $InnerException)
            }
            else {
                $ex = [BadRequestException]::new($ErrorMessage, $ErrorResponse , $ErrorContent, $InnerException)
            }
            continue
        }
        401 {
            $ex = [UnauthorizedException]::new($ErrorMessage, $ErrorResponse , $ErrorContent, $InnerException)
            continue
        }
        404 {
            $ex = [NotFoundException]::new($ErrorMessage, $ErrorResponse , $ErrorContent, $InnerException)
            continue
        }
        429 {
            if ($ErrorContent.error.code -match 'quota') {
                $ex = [QuotaLimitExceededException]::new($ErrorMessage, $ErrorResponse , $ErrorContent, $InnerException)
            }
            else {
                $ex = [RateLimitExceededException]::new($ErrorMessage, $ErrorResponse , $ErrorContent, $InnerException)
            }
            continue
        }
        Default {
            $ex = [APIRequestException]::new($ErrorMessage, $ErrorResponse , $ErrorContent, $ErrorCode, $InnerException)
        }
    }

    return $ex
}
