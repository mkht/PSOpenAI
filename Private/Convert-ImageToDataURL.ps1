function Convert-ImageToDataURL {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$File
    )

    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Write-Error -Exception ([System.IO.FileNotFoundException]::new())
        return
    }
    $FileItem = Get-Item -LiteralPath $File
    $MimeType = switch ($FileItem.Extension) {
        '.jpeg' { 'image/jpeg' }
        '.jpg' { 'image/jpeg' }
        '.png' { 'image/png' }
        '.gif' { 'image/gif' }
        '.webp' { 'image/webp' }
        Default { 'image/png' }
    }

    try {
        'data:' + $MimeType + ';base64,' + ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($FileItem.FullName)))
    }
    catch {
        Write-Error -Exception $_.Exception
    }
}
