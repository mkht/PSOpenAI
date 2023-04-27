function Initialize-OrganizationID {
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string]$OrgId,

        [Parameter()]
        [bool]$SearchGlobal = $true,

        [Parameter()]
        [bool]$SearchEnv = $true
    )

    if ([string]::IsNullOrEmpty($OrgId)) {
        # Search orgazation id below priorities.
        #   1. Global variable "OPENAI_ORGANIZATION"
        if ($SearchGlobal -and $null -ne $global:OPENAI_ORGANIZATION -and $global:OPENAI_ORGANIZATION -is [string]) {
            $OrgId = [string]$global:OPENAI_ORGANIZATION
            Write-Verbose -Message 'Organization-ID found in global variable "OPENAI_ORGANIZATION".'
        }
        #   2. Environment variable "OPENAI_ORGANIZATION"
        elseif ($SearchEnv -and $null -ne $env:OPENAI_ORGANIZATION -and $env:OPENAI_ORGANIZATION -is [string]) {
            $OrgId = [string]$env:OPENAI_ORGANIZATION
            Write-Verbose -Message 'Organization-ID found in environment variable "OPENAI_ORGANIZATION".'
        }
        else {
            $OrgId = [string]::Empty
        }
    }

    if ($OrgId.StartsWith('org-')) { $first = 6 }else { $first = 3 }
    Write-Verbose -Message (('Organization-ID to be used is {0}' -f $p) | Get-MaskedString -Target $OrgId -First $first -Last 2 -MaxNumberOfAsterisks 45)
    $OrgId
}
