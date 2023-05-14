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
    $Random = [System.Random]::new()
    [int][Math]::Min(([Math]::Pow(2, $RetryCount) * $BaseDelay * ($Random.NextDouble() * 0.4 + 0.8) * [double]$UseJitter), $MaxDelay)
}
