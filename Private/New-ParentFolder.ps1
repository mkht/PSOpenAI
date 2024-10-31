function New-ParentFolder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$File
    )

    try {
        # Convert to absolute path
        $AbsoluteOutFile = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($File)
        # create parent directory if it does not exist
        $ParentDirectory = Split-Path $AbsoluteOutFile -Parent
        if (-not $ParentDirectory) {
            $ParentDirectory = [string](Get-Location -PSProvider FileSystem).ProviderPath
            $AbsoluteOutFile = Join-Path $ParentDirectory $AbsoluteOutFile
        }
        if (-not (Test-Path -LiteralPath $ParentDirectory -PathType Container)) {
            $null = New-Item -Path $ParentDirectory -ItemType Directory -Force
        }
        $AbsoluteOutFile
    }
    catch {
        Write-Error -Exception $_.Exception
    }
}
