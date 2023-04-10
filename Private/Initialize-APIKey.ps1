function Initialize-APIKey {
    [CmdletBinding()]
    [OutputType([securestring])]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('Token')]  #for backword compatibility
        [AllowNull()]
        [object]$ApiKey,

        [Parameter()]
        [bool]$SearchGlobal = $true,

        [Parameter()]
        [bool]$SearchEnv = $true
    )

    # The type of ApiKey should be [string] or [securestring]
    [securestring]$SecureToken = $null
    if ($ApiKey -is [string]) {
        $SecureToken = (ConvertTo-SecureString -AsPlainText -String $ApiKey -Force)
    }
    elseif ($ApiKey -as [securestring]) {
        $SecureToken = $ApiKey
    }
    elseif ($null -eq $ApiKey) {
        # Search API key below priorities.
        #   1. Global variable "OPENAI_API_KEY"
        if ($SearchGlobal -and $null -ne $global:OPENAI_API_KEY -and $global:OPENAI_API_KEY -is [string]) {
            $ApiKey = [string]$global:OPENAI_API_KEY
            $SecureToken = (ConvertTo-SecureString -AsPlainText -String $ApiKey -Force)
        }
        #   2. Environment variable "OPENAI_API_KEY"
        elseif ($SearchEnv -and $null -ne $env:OPENAI_API_KEY -and $env:OPENAI_API_KEY -as [string]) {
            $ApiKey = [string]$env:OPENAI_API_KEY
            $SecureToken = (ConvertTo-SecureString -AsPlainText -String $ApiKey -Force)
        }
        #   3. Global variable "OPENAI_TOKEN" (For backward compatibility)
        elseif ($SearchGlobal -and $null -ne $global:OPENAI_TOKEN -and $global:OPENAI_TOKEN -is [string]) {
            $ApiKey = [string]$global:OPENAI_TOKEN
            $SecureToken = (ConvertTo-SecureString -AsPlainText -String $ApiKey -Force)
        }
        #   4. Environment variable "OPENAI_TOKEN" (For backward compatibility)
        elseif ($SearchEnv -and $null -ne $env:OPENAI_TOKEN -and $env:OPENAI_TOKEN -as [string]) {
            $ApiKey = [string]$env:OPENAI_TOKEN
            $SecureToken = (ConvertTo-SecureString -AsPlainText -String $ApiKey -Force)
        }
    }
    else {
        Write-Error -Exception ([System.ArgumentException]::new('The type of ApiKey should be [string] or [securestring]'))
        return
    }

    if ($null -eq $SecureToken) {
        Write-Error -Exception ([System.ArgumentException]::new('Please specify your OpenAI API key to "ApiKey" parameter.'))
        return
    }
    else {
        $SecureToken
    }
}
