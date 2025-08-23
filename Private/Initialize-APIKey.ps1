using namespace System.Runtime.InteropServices

function Initialize-APIKey {
    [CmdletBinding()]
    [OutputType([securestring])]
    param(
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

    $pattern = switch -CaseSensitive -Wildcard ($p) {
        'sk-proj-*' { '(sk-proj-.{3})[a-z0-9\-_.~+/]+([^\s]{2})'; continue }
        'sk-*' { '(sk-.{3})[a-z0-9\-_.~+/]+([^\s]{2})'; continue }
        default { '^(.{3})[a-z0-9\-_.~+/]+([^\s]{2})' }
    }

    ## Set up masking patterns
    $MaskPatterns = [System.Collections.Generic.List[Tuple[regex, string]]]::new()
    $MaskPatterns.Add([Tuple[regex, string]]::new($pattern, '$1***************$2'))
    $MaskPatterns.Add([Tuple[regex, string]]::new([regex]::Escape($p), '<OpenAI API Key>'))

    Write-Verbose -Message ('API key to be used is ' + (Get-MaskedString -Input $p -MaskPatterns $MaskPatterns))
    $p = $null
    $ApiKey
}
