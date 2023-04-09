function Get-RetryDelay {
    [OutputType([int])]
    param (
        [int]$RetryCount = 0,
        [int]$BaseDelay = 1000, #1sec
        [int]$MaxDelay = 120000, #120sec
        [bool]$UseJitter = $true
    )

    # Exponential backoff
    $Random = [System.Random]::new()
    [int][Math]::Min((([Math]::Pow(2, $RetryCount) * $BaseDelay) + ($Random.NextDouble() * 1000 * [double]$UseJitter)), $MaxDelay)
}
