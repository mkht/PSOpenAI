# Ported from
# https://github.com/PowerShell/PowerShell/blob/fef05d1a9b480bee2a7fa0058774fb669c4241e1/src/Microsoft.PowerShell.Commands.Utility/commands/utility/WebCmdlet/PSUserAgent.cs
function Get-UserAgent {
    [OutputType([string])]
    param ()
    $OS = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription.Trim()
    $PlatformName = if ($null -eq $IsWindows -or $IsWindows) {
        $pattern = [regex]::new('\d+(\.\d+)+')
        $versionText = $pattern.Match($OS).Value
        $windowsPlatformversion = $null
        if ([version]::TryParse($versionText, [ref]$windowsPlatformversion)) {
            "Windows NT $($windowsPlatformversion.Major).$($windowsPlatformversion.Minor)"
        }
        else {
            'Windows NT'
        }
    }
    elseif ($IsMacOS) {
        'Macintosh'
    }
    elseif ($IsLinux) {
        'Linux'
    }
    else {
        [string]::Empty
    }
    "Mozilla/5.0 ($PlatformName; $OS; $([cultureinfo]::CurrentCulture.Name)) PowerShell/$($PSVersionTable.PSVersion)"
}
