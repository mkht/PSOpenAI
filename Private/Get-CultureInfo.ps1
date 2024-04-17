function Get-CultureInfo {
    [CmdletBinding()]
    [OutputType([cultureinfo])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]$LanguageName
    )

    $LanguageName = $LanguageName.Trim()
    [cultureinfo]$CultureInfo = [cultureinfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures) |`
            Where-Object {
            $_.Name -eq $LanguageName `
                -or $_.EnglishName -eq $LanguageName `
                -or $_.DisplayName -eq $LanguageName `
                -or $_.NativeName -eq $LanguageName `
                -or $_.TwoLetterISOLanguageName -eq $LanguageName `
                -or $_.ThreeLetterISOLanguageName -eq $LanguageName
        } | Select-Object -First 1

    if ($CultureInfo -is [cultureinfo]) {
        $CultureInfo
    }
}