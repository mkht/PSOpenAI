
$PrivateDirectory = Join-Path $PSScriptRoot 'Private'
$PublicDirectory = Join-Path $PSScriptRoot 'Public'

$PrivateFunctions = Get-ChildItem -LiteralPath $PrivateDirectory -Recurse -Filter '*.ps1' -File
$PublicFunctions = Get-ChildItem -LiteralPath $PublicDirectory -Recurse -Filter '*.ps1' -File

# Include Private functions
$PrivateFunctions | % {
    . $_.FullName
}

# Include Public functions
$PublicFunctions | % {
    . $_.FullName
}

# Export public functions
$ExportFunctions = [string[]]@()
$PublicFunctions | % {
    if (Test-Path -LiteralPath "Function:/$($_.BaseName)") {
        $ExportFunctions += $_.BaseName
    }
}
if ($ExportFunctions.Count -ge 1) {
    Export-ModuleMember -Function $ExportFunctions -Alias *
}
