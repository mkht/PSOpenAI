using namespace System.Runtime.InteropServices

function Get-MaskedString {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$Source,

        [Parameter(Mandatory, Position = 1)]
        [AllowNull()]
        [securestring[]][SecureStringTransformation()]$Target,

        [Parameter()]
        [uint32]$First = 0,

        [Parameter()]
        [uint32]$Last = 0,

        [Parameter()]
        [uint32]$MaxNumberOfAsterisks = [int]::MaxValue,

        [Parameter()]
        [uint32]$MinNumberOfAsterisks = 0
    )

    begin {
        # decrypt securestring
        [string[]]$PlainTarget = @()
        foreach ($t in $Target) {
            if ($null -ne $t) {
                $PlainTarget += DecryptSecureString $t
            }
        }
    }

    process {
        if ([string]::IsNullOrEmpty($Source)) {
            [string]::Empty
            return
        }

        foreach ($pt in $PlainTarget) {
            if ([string]::IsNullOrEmpty($pt)) {
                continue
            }
            if ($First + $Last -gt $pt.Length) {
                continue
            }
            [int]$numberOfAsterisks = $pt.Length - $First - $Last
            if ($numberOfAsterisks -lt $MinNumberOfAsterisks) { $numberOfAsterisks = $MinNumberOfAsterisks }
            if ($numberOfAsterisks -gt $MaxNumberOfAsterisks) { $numberOfAsterisks = $MaxNumberOfAsterisks }

            [string]$Masked = [string]::Concat(
                $pt.Substring(0, $First),
                ''.PadLeft($numberOfAsterisks, '*'),
                $pt.Substring($pt.Length - $Last, $Last)
            )

            $Source = [regex]::Replace($Source, $pt, $Masked, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }

        $Source
    }

    end {}
}
