function Convert-ImageToDataURL {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$File
    )
    Convert-FileToDataURL -File $File -DefaultMimeType 'image/png'
}

function Convert-FileToDataURL {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$File,

        [Parameter()]
        [string]$DefaultMimeType = 'application/octet-stream'
    )

    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        Write-Error -Exception ([System.IO.FileNotFoundException]::new())
        return
    }

    $FileItem = Get-Item -LiteralPath $File
    $MimeType = switch ($FileItem.Extension) {
        '.jpeg' { 'image/jpeg'; continue }
        '.jpg' { 'image/jpeg'; continue }
        '.png' { 'image/png'; continue }
        '.gif' { 'image/gif'; continue }
        '.webp' { 'image/webp'; continue }
        '.c' { 'text/x-c'; continue }
        '.cpp' { 'text/x-c++'; continue }
        '.cs' { 'text/x-csharp'; continue }
        '.css' { 'text/css'; continue }
        '.doc' { 'application/msword'; continue }
        '.docx' { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'; continue }
        '.go' { 'text/x-golang'; continue }
        '.html' { 'text/html'; continue }
        '.java' { 'text/x-java'; continue }
        '.js' { 'text/javascript'; continue }
        '.json' { 'application/json'; continue }
        '.md' { 'text/markdown'; continue }
        '.pdf' { 'application/pdf'; continue }
        '.php' { 'text/x-php'; continue }
        '.pptx' { 'application/vnd.openxmlformats-officedocument.presentationml.presentation'; continue }
        '.py' { 'text/x-python'; continue }
        '.rb' { 'text/x-ruby'; continue }
        '.sh' { 'application/x-sh'; continue }
        '.tex' { 'text/x-tex'; continue }
        '.ts' { 'application/typescript'; continue }
        '.txt' { 'text/plain'; continue }
        Default { $DefaultMimeType }
    }

    try {
        'data:' + $MimeType + ';base64,' + ([System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($FileItem.FullName)))
    }
    catch {
        Write-Error -Exception $_.Exception
    }
}