function Copy-TempFile {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param (
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$SourceFile,

        [Parameter()]
        [string]$Destination
    )

    if (-not $Destination) {
        $Destination = [System.IO.Path]::GetTempFileName() + $SourceFile.Extension
    }

    if (-not (Test-Path -LiteralPath (Split-Path $Destination -Parent) -PathType Container)) {
        $null = New-Item -Path (Split-Path $Destination -Parent) -ItemType Directory -Force
    }

    Copy-Item -LiteralPath $SourceFile.FullName -Destination $Destination -PassThru
}
