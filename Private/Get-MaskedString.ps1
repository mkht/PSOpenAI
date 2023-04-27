using namespace System.Runtime.InteropServices

function Get-MaskedString {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Source,

        [Parameter(Mandatory, Position = 1)]
        [securestring][SecureStringTransformation()]$Target,

        [Parameter()]
        [uint]$First = 0,

        [Parameter()]
        [uint]$Last = 0,

        [Parameter()]
        [uint]$MaxNumberOfAsterisks = [int]::MaxValue,

        [Parameter()]
        [uint]$MinNumberOfAsterisks = 0
    )

    begin {
        # decrypt securestring
        [string]$PlainTarget = ''
        if ($null -ne $Source) {
            $bstr = [Marshal]::SecureStringToBSTR($Target)
            $PlainTarget = [Marshal]::PtrToStringBSTR($bstr)
        }
    }

    process {
        if ([string]::IsNullOrEmpty($Source)) {
            [string]::Empty
            return
        }
        if ([string]::IsNullOrEmpty($PlainTarget)) {
            $Source
            return
        }
        if ($First + $Last -gt $PlainTarget.Length) {
            $Source
            return
        }
        [int]$numberOfAsterisks = $PlainTarget.Length - $First - $Last
        if ($numberOfAsterisks -lt $MinNumberOfAsterisks) { $numberOfAsterisks = $MinNumberOfAsterisks }
        if ($numberOfAsterisks -gt $MaxNumberOfAsterisks) { $numberOfAsterisks = $MaxNumberOfAsterisks }

        [string]$Masked = [string]::Concat(
            $PlainTarget.Substring(0, $First),
            ''.PadLeft($numberOfAsterisks, '*'),
            $PlainTarget.Substring($PlainTarget.Length - $Last, $Last)
        )

        [regex]::Replace($Source, $PlainTarget, $Masked, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }

    end {}
}
