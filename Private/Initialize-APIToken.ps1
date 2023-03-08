function Initialize-APIToken {
    [CmdletBinding()]
    [OutputType([securestring])]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [object]$Token,

        [Parameter()]
        [bool]$SearchGlobal = $true,

        [Parameter()]
        [bool]$SearchEnv = $true
    )

    # The type of Token should be [string] or [securestring]
    [securestring]$SecureToken = $null
    if ($Token -is [string]) {
        $SecureToken = (ConvertTo-SecureString -AsPlainText -String $Token -Force)
    }
    elseif ($Token -as [securestring]) {
        $SecureToken = $Token
    }
    elseif ($null -eq $Token) {
        # Search token below priorities.
        #   1. Global variable "OPENAI_TOKEN"
        if ($SearchGlobal -and $null -ne $global:OPENAI_TOKEN -and $global:OPENAI_TOKEN -is [string]) {
            $Token = [string]$global:OPENAI_TOKEN
            $SecureToken = (ConvertTo-SecureString -AsPlainText -String $Token -Force)
        }
        #   2. Environment variable "OPENAI_TOKEN"
        elseif ($SearchEnv -and $null -ne $env:OPENAI_TOKEN -and $env:OPENAI_TOKEN -as [string]) {
            $Token = [string]$env:OPENAI_TOKEN
            $SecureToken = (ConvertTo-SecureString -AsPlainText -String $Token -Force)
        }
    }
    else {
        Write-Error -Exception ([System.ArgumentException]::new('The type of Token should be [string] or [securestring]'))
        return
    }

    if ($null -eq $SecureToken) {
        Write-Error -Exception ([System.ArgumentException]::new('Please specify your OpenAI token to "Token" parameter.'))
        return
    }
    else {
        $SecureToken
    }
}
