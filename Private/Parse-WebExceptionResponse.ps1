function Parse-WebExceptionResponse {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
    param (
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    if ($ErrorRecord.Exception -is [System.Net.WebException]) {
        $ErrorCode = $ErrorRecord.Exception.Response.StatusCode.value__
        $ErrorReason = $ErrorRecord.Exception.Response.StatusCode.ToString()
        $Headers = $ErrorRecord.Exception.Response.Headers
        $ResponseStream = $ErrorRecord.Exception.Response.GetResponseStream()
        $ResponseStream.Position = 0
        $Reader = [System.IO.StreamReader]::new($ResponseStream)
        $ErrorResponse = try { $Reader.ReadToEnd() }finally { if ($null -ne $Reader) { $Reader.Close() } }
        $ErrorMessage = try { ($ErrorResponse | ConvertFrom-Json -ErrorAction Ignore).error.message }catch {}
        if (-not $ErrorMessage) {
            $ErrorMessage = $ErrorRecord.Exception.Message
        }
    }
    elseif ($ErrorRecord.Exception -is [System.Net.Http.HttpRequestException]) {
        $ErrorCode = $ErrorRecord.Exception.Response.StatusCode.value__
        $ErrorReason = $ErrorRecord.Exception.Response.ReasonPhrase
        $Headers = $ErrorRecord.Exception.Response.Headers
        $ErrorMessage = try { ($ErrorRecord.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Ignore).error.message }catch {}
        if (-not $ErrorMessage) {
            $ErrorMessage = $ErrorRecord.Exception.Message
        }
    }

    $ResponseObject = [pscustomobject]@{
        ErrorCode    = $ErrorCode
        ErrorReason  = $ErrorReason
        Headers      = $Headers
        ErrorMessage = $ErrorMessage
    }

    return $ResponseObject
}
