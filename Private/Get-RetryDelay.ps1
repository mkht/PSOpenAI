function Get-RetryDelay {
    # Returns a milliseconds value
    [OutputType([int])]
    param (
        [int]$RetryCount = 0,
        [int]$BaseDelay = 1000, #1sec
        [int]$MaxDelay = 129000, #129sec
        [bool]$UseJitter = $true,
        [System.Collections.IEnumerable]$ResponseHeaders
    )

    if ($ResponseHeaders) {
        [int]$FromHeaderValue = -1
        try {
            # First, try parsing the `retry-after-ms` header value as milliseconds
            if ($ResponseHeaders.Contains('retry-after-ms')) {
                $FromHeaderValue = @($ResponseHeaders.GetValues('retry-after-ms'))[0] -as [int]
            }
            elseif ($ResponseHeaders.Contains('retry-after')) {
                $retry_after = @($ResponseHeaders.GetValues('retry-after'))[0]
                # Second, try parsing the `retry-after` header as seconds
                if ($s = $retry_after -as [int]) {
                    $FromHeaderValue = $s * 1000
                }
                # Third, try parsing the `retry-after` header as http-date
                elseif ($dt = $retry_after -as [datetime]) {
                    $FromHeaderValue = ($dt - [datetime]::Now).TotalMilliseconds
                }
            }
        }
        catch {}

        if ($FromHeaderValue -gt 0 -and $FromHeaderValue -le 60000) {
            return $FromHeaderValue
        }
    }

    # Finally, use exponential backoff
    # 2^RetryCount * BaseDelay * Random(0.8 to 1.2)
    if ($UseJitter) {
        $jitter = [System.Random]::new().NextDouble() * 0.4 + 0.8
    }
    else {
        $jitter = 1.0
    }
    [int][Math]::Min([Math]::Pow(2, $RetryCount) * $BaseDelay * $jitter, $MaxDelay)
}
