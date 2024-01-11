function Should-Retry {
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '')]
    [OutputType([bool])]
    param (
        [int]$ErrorCode,
        [string]$ErrorMessage,
        [System.Collections.IEnumerable]$Headers,
        [int]$RetryCount = 0,
        [int]$MaxRetryCount = 0
    )

    if ($RetryCount -ge $MaxRetryCount) {
        Write-Debug ('Current retry count:{0} exceeds max retry count:{1}. Should not retry anymore.' -f $RetryCount, $MaxRetryCount)
        return $false
    }

    # Note: this is not a standard header
    try {
        $ShouldRetryHeader = @($Headers.GetValues('x-should-retry'))[0]
    }
    catch {}

    # If the server explicitly says whether or not to retry, obey.
    if ('true' -eq $ShouldRetryHeader) {
        Write-Debug 'Should retry because a header "x-should-retry" is set to "true".'
        return $true
    }
    if ('false' -eq $ShouldRetryHeader) {
        Write-Debug 'Should NOT retry because a header "x-should-retry" is set to "false".'
        return $false
    }

    if ($ErrorCode -eq 429) {
        # Retry on rate limits.
        if ($ErrorMessage -notmatch 'quota') {
            Write-Debug ('Should retry due to status code "{0}"' -f $ErrorCode)
            return $true
        }
        # Not retry on quota limits.
        else {
            Write-Debug 'Should NOT retry because it seems quota limit reached.'
            return $false
        }
    }

    # Retry internal errors.
    if ($ErrorCode -ge 500 -and $ErrorCode -le 599) {
        Write-Debug ('Should retry due to status code "{0}"' -f $ErrorCode)
        return $true
    }

    return $false
}
