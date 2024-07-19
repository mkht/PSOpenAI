function Enter-ChatGPT {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-4o',
            'gpt-4o-mini',
            'gpt-3.5-turbo-16k',
            'gpt-3.5-turbo-0613',
            'gpt-3.5-turbo-16k-0613',
            'gpt-3.5-turbo-1106',
            'gpt-3.5-turbo-0125',
            'gpt-4-0613',
            'gpt-4-32k',
            'gpt-4-32k-0613',
            'gpt-4-turbo',
            'gpt-4-turbo-2024-04-09'
        )]
        [string][LowerCaseTransformation()]$Model,

        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [Alias('RolePrompt')]
        [string]$SystemMessage = '',

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [ValidateCount(1, 4)]
        [Alias('stop')]
        [string[]]$StopSequence,

        [Parameter()]
        [ValidateRange(0, 2147483647)]
        [Alias('max_tokens')]
        [int]$MaxTokens,

        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [Alias('presence_penalty')]
        [double]$PresencePenalty,

        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [Alias('frequency_penalty')]
        [double]$FrequencyPenalty,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization,

        [Parameter()]
        [switch]$NoHeader
    )

    Begin {
        $script:Status = $null
        $script:Model = $Model
        $ConvasationList = [System.Collections.Generic.List[HashTable]]::new()
        $Parametershash = $PSBoundParameters
        if ($Parametershash.ContainsKey('Model')) {
            $null = $Parametershash.Remove('Model')
        }
        if ($Parametershash.ContainsKey('NoHeader')) {
            $null = $Parametershash.Remove('NoHeader')
        }

        #region Display header
        $ConsoleWidth = [Math]::Min(46, ($Host.UI.RawUI.WindowSize.Width - 4))
        if (-not $NoHeader) {
    (1..$ConsoleWidth) | ForEach-Object { Write-Host '/' -NoNewline }
            Write-Host ''
            Write-Host @'
   ________          __  __________ ______
  / ____/ /_  ____ _/ /_/ ____/ __ /_  __/
 / /   / __ \/ __ `/ __/ / __/ /_/ // /
/ /___/ / / / /_/ / /_/ /_/ / ____// /
\____/_/ /_/\__,_/\__/\____/_/    /_/

'@
    (1..$ConsoleWidth) | ForEach-Object { Write-Host '/' -NoNewline }
            Write-Host ''
            Write-Host ''
        }
        #endregion
    }

    Process {
        while ($true) {
            #User prompt
            Write-Host "$($PSStyle.Background.BrightBlack)$($PSStyle.Bold)User:$($PSStyle.Reset)>>>"
            [string]$UserPrompt = Get-UserPrompt

            #Parase special commands
            if ($script:Status -eq 'exit') {
                return
            }
            if (-not [string]::IsNullOrWhiteSpace($script:Model)) {
                $Parametershash.Model = $script:Model
            }

            #Request to ChatGPT
            Write-Host "$($PSStyle.Background.Green)$($PSStyle.Bold)Assistant:$($PSStyle.Reset)>>>"
            Request-ChatGPT -Message $UserPrompt -History @($ConvasationList.ToArray()) -Stream -InformationVariable answer @Parametershash | Write-Host -NoNewline
            Write-Host "`r`n"

            #Save dialogs for next chat
            $ConvasationList.Add(@{
                    'role'    = 'user'
                    'content' = $UserPrompt
                })
            $ConvasationList.Add(@{
                    'role'    = 'assistant'
                    'content' = [string](-join $answer)
                })
        }
    }

    End {}

}

function Get-UserPrompt {
    $StringBuilder = [System.Text.StringBuilder]::new()
    $Ready4Break = $false
    :outer while ($true) {
        #Retrieve from user input
        $ret = Read-Host

        #Break by double line feeds
        if ($Ready4Break -and [string]::IsNullOrEmpty($ret)) {
            break outer
        }
        $Ready4Break = [string]::IsNullOrEmpty($ret)

        #Special commands. (Starts with "#")
        if ($ret.StartsWith('#', [StringComparison]::Ordinal)) {
            switch -Wildcard ($ret.Substring(1).Trim()) {
                'end' {
                    $script:Status = 'exit'
                    return
                }

                'exit' {
                    $script:Status = 'exit'
                    return
                }

                'send' {
                    break outer
                }

                'model *' {
                    $script:Model = @($ret -split ' ')[1]
                    Write-Host ('>AI model is switched to {0}' -f $script:Model)
                    continue outer
                }
            }
        }
        $null = $StringBuilder.AppendLine($ret)
    }
    $StringBuilder.ToString().TrimEnd()
    $StringBuilder.Length = 0
}
