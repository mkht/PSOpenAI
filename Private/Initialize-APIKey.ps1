using namespace System.Runtime.InteropServices

function Initialize-APIKey {
    [CmdletBinding()]
    [OutputType([securestring])]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [bool]$SearchGlobal = $true,

        [Parameter()]
        [bool]$SearchEnv = $true
    )

    if ($null -ne $ApiKey) {
        $p = DecryptSecureString $ApiKey
    }
    else {
        # Search API key below priorities.
        #   1. Global variable "OPENAI_API_KEY"
        if ($SearchGlobal -and $null -ne $global:OPENAI_API_KEY -and $global:OPENAI_API_KEY -is [string]) {
            $p = [string]$global:OPENAI_API_KEY
            $ApiKey = $p
            Write-Verbose -Message 'API Key found in global variable "OPENAI_API_KEY".'

        }
        #   2. Environment variable "OPENAI_API_KEY"
        elseif ($SearchEnv -and $null -ne $env:OPENAI_API_KEY -and $env:OPENAI_API_KEY -is [string]) {
            $p = [string]$env:OPENAI_API_KEY
            $ApiKey = $p
            Write-Verbose -Message 'API Key found in environment variable "OPENAI_API_KEY".'
        }
        else {
            Write-Error -Exception ([System.ArgumentException]::new('Please specify your OpenAI API key to "ApiKey" parameter.'))
            return
        }
    }

    if ($p.StartsWith('sk-', [StringComparison]::Ordinal)) { $first = 6 }else { $first = 3 }
    Write-Verbose -Message (('API key to be used is {0}' -f $p) | Get-MaskedString -Target $p -First $first -Last 2 -MaxNumberOfAsterisks 45)
    $p = $null
    $ApiKey
}
