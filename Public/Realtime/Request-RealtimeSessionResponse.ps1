function Request-RealtimeSessionResponse {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Instructions,

        [Parameter()]
        [Alias('Modalities')] # for backward compatibility
        [ValidateSet('text', 'audio')]
        [string[]]$OutputModalities = @('text'),

        [Parameter()]
        [Completions('alloy', 'ash', 'ballad', 'coral', 'echo', 'sage', 'shimmer', 'verse', 'marin', 'cedar')]
        [string][LowerCaseTransformation()]$Voice,

        [Parameter()]
        [Completions(
            'pcm16',
            'g711_ulaw',
            'g711_alaw'
        )]
        [string][LowerCaseTransformation()]$OutputAudioFormat,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [Completions('none', 'auto', 'required')]
        [string]$ToolChoice,

        [Parameter()]
        [ValidateRange(0.6, 1.2)]
        [float]$Temperature,

        [Parameter()]
        [ValidateRange(-1, 4096)]
        [int]$MaxOutputTokens = -1,

        [Parameter()]
        [Completions('auto', 'none')]
        [String]$Conversation,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        <#
          In OpenAI's API, this corresponds to the "Input" parameter name.
          But avoid using the variable name $Input for variable name,
          because it is used as an automatic variable in PowerShell.
        #>
        [Parameter()]
        [AllowEmptyCollection()]
        [Alias('Input')]
        [object[]]$InputObject
    )

    begin {
        $MessageObject = @{type = 'response.create'; response = @{} }
    }

    process {
        if (-not [string]::IsNullOrEmpty($EventId)) {
            $MessageObject.event_id = $EventId
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $MessageObject.response.instructions = $Instructions
        }
        if ($PSBoundParameters.ContainsKey('OutputModalities')) {
            $MessageObject.response.output_modalities = $OutputModalities
        }
        if ($PSBoundParameters.ContainsKey('Tools')) {
            $MessageObject.response.tools = $Tools
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            $MessageObject.response.tool_choice = $ToolChoice
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $MessageObject.response.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('MaxOutputTokens')) {
            if ($MaxOutputTokens -lt 0) {
                $MessageObject.response.max_output_tokens = 'inf'
            }
            else {
                $MessageObject.response.max_output_tokens = $MaxOutputTokens
            }
        }
        if ($PSBoundParameters.ContainsKey('Conversation')) {
            $MessageObject.response.conversation = $Conversation
        }
        if ($PSBoundParameters.ContainsKey('MetaData')) {
            $MessageObject.response.metadata = $MetaData
        }
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            $MessageObject.response.input = $InputObject
        }

        #Output audio settings
        $OutputAudioSettings = @{}
        if ($PSBoundParameters.ContainsKey('Voice')) {
            $OutputAudioSettings.voice = $Voice
        }
        if ($PSBoundParameters.ContainsKey('OutputAudioFormat')) {
            switch ($OutputAudioFormat) {
                'pcm16' {
                    $OutputAudioSettings.format = @{
                        type = 'audio/pcm'
                        rate = 24000
                    }
                }
                'g711_ulaw' {
                    $OutputAudioSettings.format = @{
                        type = 'audio/pcmu'
                    }
                }
                'g711_alaw' {
                    $OutputAudioSettings.format = @{
                        type = 'audio/pcma'
                    }
                }
                default {
                    $OutputAudioSettings.format = $OutputAudioFormat
                }
            }
        }
        if ($OutputAudioSettings.Keys.Count -gt 0) {
            if (-not $MessageObject.response.ContainsKey('audio')) {
                $MessageObject.response.audio = @{}
            }
            $MessageObject.response.audio.output = $OutputAudioSettings
        }

        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}