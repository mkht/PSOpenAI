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

    if ($null -eq $ApiKey) {
        # Search API key below priorities.
        #   1. Global variable "OPENAI_API_KEY"
        if ($SearchGlobal -and $null -ne $global:OPENAI_API_KEY -and $global:OPENAI_API_KEY -is [string]) {
            $ApiKey = [string]$global:OPENAI_API_KEY
            Write-Verbose -Message 'API Key found in global variable "OPENAI_API_KEY".'
        }
        #   2. Environment variable "OPENAI_API_KEY"
        elseif ($SearchEnv -and $null -ne $env:OPENAI_API_KEY -and $env:OPENAI_API_KEY -is [string]) {
            $ApiKey = [string]$env:OPENAI_API_KEY
            Write-Verbose -Message 'API Key found in environment variable "OPENAI_API_KEY".'
        }
        #   3. Global variable "OPENAI_TOKEN" (For backward compatibility)
        elseif ($SearchGlobal -and $null -ne $global:OPENAI_TOKEN -and $global:OPENAI_TOKEN -is [string]) {
            $ApiKey = [string]$global:OPENAI_TOKEN
            Write-Verbose -Message 'API Key found in global variable "OPENAI_TOKEN".'
        }
        #   4. Environment variable "OPENAI_TOKEN" (For backward compatibility)
        elseif ($SearchEnv -and $null -ne $env:OPENAI_TOKEN -and $env:OPENAI_TOKEN -is [string]) {
            $ApiKey = [string]$env:OPENAI_TOKEN
            Write-Verbose -Message 'API Key found in environment variable "OPENAI_TOKEN".'
        }
        else {
            Write-Error -Exception ([System.ArgumentException]::new('Please specify your OpenAI API key to "ApiKey" parameter.'))
            return
        }
    }

    $ApiKey
}
