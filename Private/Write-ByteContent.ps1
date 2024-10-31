function Write-ByteContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$OutFile,

        [Parameter(Mandatory)]
        [byte[]]$Bytes
    )

    $AbsoluteOutFile = New-ParentFolder -File $OutFile

    try {
        [System.IO.File]::WriteAllBytes($AbsoluteOutFile, $Bytes)
    }
    catch {
        Write-Error -Exception $_.Exception
    }
}
