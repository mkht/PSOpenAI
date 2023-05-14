function Get-RetryDelay {
    [OutputType([int])]
    param (
        [int]$RetryCount = 0,
        [int]$BaseDelay = 1000, #1sec
        [int]$MaxDelay = 129000, #129sec
        [bool]$UseJitter = $true
    )

    # Exponential backoff
    # 2^RetryCount * BaseDelay * Random(0.8 to 1.2)
    if ($UseJitter) {
        $jitter = [System.Random]::new().NextDouble() * 0.4 + 0.8
    }
    else {
        $jitter = 1.0
    }
    [int][Math]::Min([Math]::Pow(2, $RetryCount) * $BaseDelay * $jitter, $MaxDelay)
}
