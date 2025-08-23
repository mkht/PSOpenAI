using namespace System.Text.RegularExpressions
using namespace System.Collections.Generic

function Get-MaskedString {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [string]$InputString,

        [Parameter()]
        [int]$MaxLength = 8192,

        [Parameter()]
        [List[Tuple[regex, string]]]$MaskPatterns = @()
    )

    begin {
        #Regex options
        $RegexOptions = [RegexOptions]::IgnoreCase -bor `
            [RegexOptions]::Multiline -bor `
            [RegexOptions]::CultureInvariant

        $RegexMatchTimeout = [TimeSpan]::FromSeconds(3)
    }

    process {
        if ([string]::IsNullOrWhiteSpace($InputString)) {
            return $InputString
        }

        foreach ($pattern in $MaskPatterns) {
            try {
                $InputString = [regex]::Replace($InputString, $pattern.Item1, $pattern.Item2, $RegexOptions, $RegexMatchTimeout)
            }
            catch {
                $InputString = '...<some error occurred during processing>...'
            }
        }

        if ($InputString.Length -gt $MaxLength) {
            $InputString = $InputString.Substring(0, $MaxLength) + ' ...<truncated>'
        }

        $InputString
    }

    end {}
}
