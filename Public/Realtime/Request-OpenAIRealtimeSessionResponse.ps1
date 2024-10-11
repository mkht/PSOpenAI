function Request-OpenAIRealtimeSessionResponse {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Instructions,

        [Parameter()]
        [ValidateSet('text', 'audio')]
        [string[]]$Modalities = @('text'),

        [Parameter()]
        [Completions(
            'alloy',
            'echo',
            'shimmer'
        )]
        [string][LowerCaseTransformation()]$Voice,

        [Parameter()]
        [Completions(
            'pcm16',
            'g711_ulaw',
            'g711_alaw'
        )]
        [string][LowerCaseTransformation()]$OutputAudioFormat,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [float]$Temperature,

        [Parameter()]
        [ValidateRange(-1, 4096)]
        [int]$MaxOutputTokens = -1
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
        if ($PSBoundParameters.ContainsKey('Modalities')) {
            $MessageObject.response.modalities = $Modalities
        }
        if ($PSBoundParameters.ContainsKey('Voice')) {
            $MessageObject.response.voice = $Voice
        }
        if ($PSBoundParameters.ContainsKey('OutputAudioFormat')) {
            $MessageObject.response.output_audio_format = $OutputAudioFormat
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $MessageObject.response.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('MaxOutputTokens')) {
            if ($MaxOutputTokens -lt 0) {
                $MessageObject.response.max_output_tokens = 'inf'
            }
            else {
                $MessageObject.response.max_output_tokens = $Temperature
            }
        }

        PSOpenAI\Send-OpenAIRealtimeSessionMessage -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}