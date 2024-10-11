function Set-OpenAIRealtimeSessionConfiguration {
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
        [string][LowerCaseTransformation()]$InputAudioFormat,

        [Parameter()]
        [Completions(
            'pcm16',
            'g711_ulaw',
            'g711_alaw'
        )]
        [string][LowerCaseTransformation()]$OutputAudioFormat,

        [Parameter()]
        [bool]$EnableInputAudioTranscription,

        [Parameter()]
        [Completions('whisper-1')]
        [string][LowerCaseTransformation()]$InputAudioTranscriptionModel = 'whisper-1',

        [Parameter()]
        [bool]$EnableTurnDetection,

        [Parameter()]
        [Completions('server_vad')]
        [string]$TurnDetectionType = 'server_vad',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [float]$TurnDetectionThreshold,

        [Parameter()]
        [uint16]$TurnDetectionPrefixPadding,

        [Parameter()]
        [uint16]$TurnDetectionSilenceDuration,

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [float]$Temperature,

        [Parameter()]
        [ValidateRange(-1, 4096)]
        [int]$MaxResponseOutputTokens = -1
    )

    begin {
        $MessageObject = @{type = 'session.update'; session = @{} }
    }

    process {
        if (-not [string]::IsNullOrEmpty($EventId)) {
            $MessageObject.event_id = $EventId
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $MessageObject.session.instructions = $Instructions
        }
        if ($PSBoundParameters.ContainsKey('Modalities')) {
            $MessageObject.session.modalities = $Modalities
        }
        if ($PSBoundParameters.ContainsKey('Voice')) {
            $MessageObject.session.voice = $Voice
        }
        if ($PSBoundParameters.ContainsKey('InputAudioFormat')) {
            $MessageObject.session.input_audio_format = $InputAudioFormat
        }
        if ($PSBoundParameters.ContainsKey('OutputAudioFormat')) {
            $MessageObject.session.output_audio_format = $OutputAudioFormat
        }

        if ($PSBoundParameters.ContainsKey('EnableInputAudioTranscription')) {
            if (-not $EnableInputAudioTranscription) {
                $MessageObject.session.input_audio_transcription = $null
            }
            else {
                $MessageObject.session.input_audio_transcription = @{enabled = $true }
                $MessageObject.session.input_audio_transcription.model = $InputAudioTranscriptionModel
            }
        }

        if ($PSBoundParameters.ContainsKey('EnableTurnDetection')) {
            if (-not $EnableTurnDetection) {
                $MessageObject.session.turn_detection = $null
            }
            else {
                $MessageObject.session.turn_detection = @{type = $TurnDetectionType }
                if ($PSBoundParameters.ContainsKey('TurnDetectionThreshold')) {
                    $MessageObject.session.turn_detection.threshold = $TurnDetectionThreshold
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionPrefixPadding')) {
                    $MessageObject.session.turn_detection.prefix_padding_ms = $TurnDetectionPrefixPadding
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionThreshold')) {
                    $MessageObject.session.turn_detection.silence_duration_ms = $TurnDetectionSilenceDuration
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $MessageObject.session.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('MaxResponseOutputTokens')) {
            if ($MaxResponseOutputTokens -lt 0) {
                $MessageObject.session.max_response_output_tokens = 'inf'
            }
            else {
                $MessageObject.session.max_response_output_tokens = $Temperature
            }
        }

        PSOpenAI\Send-OpenAIRealtimeSessionMessage -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}