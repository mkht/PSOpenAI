function Initialize-OrganizationID {
    [CmdletBinding()]
    [OutputType([string])]
    param(
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

    if ([string]::IsNullOrEmpty($OrgId)) {
        # Write-Verbose -Message ('Organization-ID was not found. Not to be used.')
    }
    else {
        $pattern = switch -CaseSensitive -Wildcard ($OrgId) {
            'org-*' { '^(.{6})[a-z0-9\-_.~+/]+([^\s]{2})'; continue }
            default { '^(.{3})[a-z0-9\-_.~+/]+([^\s]{2})' }
        }

        ## Set up masking patterns
        $MaskPatterns = [System.Collections.Generic.List[Tuple[regex, string]]]::new()
        $MaskPatterns.Add([Tuple[regex, string]]::new($pattern, '$1***************$2'))
        $MaskPatterns.Add([Tuple[regex, string]]::new([regex]::Escape($OrgId), '<OpenAI Organization ID>'))

        Write-Verbose -Message ('Organization-ID to be used is ' + (Get-MaskedString -Input $OrgId -MaskPatterns $MaskPatterns))
    }
    $OrgId
}
