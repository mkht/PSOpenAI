#Requires -Modules Microsoft.PowerShell.PSResourceGet

param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$NugetApiKey,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ExcludeDirs = @('.git', '.github', 'Tests', 'Docs', 'Guides', '.vscode', 'src'),

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ExcludeFiles = @('.gitignore', '.gitmodules', '.gitattributes', 'PSScriptAnalyzerRules.psd1', 'AGENTS.md', '*.tmp'),

    [switch]$WhatIf
)

$ModuleDir = $PSScriptRoot
$ModuleName = Split-Path $ModuleDir -Leaf
$MySelfName = Split-Path $PSCommandPath -Leaf
$Destination = Join-Path $env:TEMP $ModuleName

if (Test-Path $Destination) {
    Remove-Item $Destination -Force -Recurse -ErrorAction Stop
}

if ($ExcludeDirs -notcontains '.git') {
    $ExcludeDirs += '.git'
}

if ($ExcludeFiles -notcontains $MySelfName) {
    $ExcludeFiles += $MySelfName
}

try {
    robocopy $ModuleDir $Destination /MIR /XD $ExcludeDirs /XF $ExcludeFiles /NP > $null

    Set-Location $Destination
    Publish-PSResource -Path ./ -Repository PSGallery -ApiKey $NugetApiKey -Verbose -WhatIf:$WhatIf
}
finally {
    Set-Location $ModuleDir
    Remove-Item $Destination -Force -Recurse -ErrorAction Continue
}
