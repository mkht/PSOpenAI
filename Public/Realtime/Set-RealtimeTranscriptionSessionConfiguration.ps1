function Set-RealtimeTranscriptionSessionConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId,

        [Parameter()]
        [ValidateSet('text', 'audio')]
        [string[]]$Modalities = @('text'),

        [Parameter()]
        [Completions(
            'pcm16',
            'g711_ulaw',
            'g711_alaw'
        )]
        [string][LowerCaseTransformation()]$InputAudioFormat,

        [Parameter()]
        [AllowEmptyString()]
        [Completions('near_field', 'far_field', 'none')]
        [string][LowerCaseTransformation()]$InputAudioNoiseReductionType,

        [Parameter()]
        [Completions('gpt-4o-transcribe', 'gpt-4o-mini-transcribe', 'whisper-1')]
        [string][LowerCaseTransformation()]$InputAudioTranscriptionModel = 'whisper-1',

        [Parameter()]
        [string]$InputAudioTranscriptionLanguage,

        [Parameter()]
        [string]$InputAudioTranscriptionPrompt,

        [Parameter()]
        [bool]$EnableTurnDetection,

        [Parameter()]
        [Completions('server_vad', 'semantic_vad')]
        [string]$TurnDetectionType = 'server_vad',

        [Parameter()]
        [Completions('low', 'medium', 'high', 'auto')]
        [string]$TurnDetectionEagerness = 'auto',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [float]$TurnDetectionThreshold,

        [Parameter()]
        [uint16]$TurnDetectionPrefixPadding,

        [Parameter()]
        [uint16]$TurnDetectionSilenceDuration,

        # Not available for transcription sessions.
        [Parameter()]
        [bool]$CreateResponseOnTurnEnd = $true,

        # Not available for transcription sessions.
        [Parameter()]
        [bool]$InterruptResponse = $true,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$Include
    )

    begin {
        $MessageObject = @{type = 'transcription_session.update'; session = @{} }
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
        if ($PSBoundParameters.ContainsKey('InputAudioFormat')) {
            $MessageObject.session.input_audio_format = $InputAudioFormat
        }

        if ($PSBoundParameters.ContainsKey('InputAudioNoiseReductionType')) {
            if ([string]::IsNullOrWhiteSpace($InputAudioNoiseReductionType) `
                    -or $InputAudioNoiseReductionType -eq 'none') {
                $MessageObject.session.input_audio_noise_reduction = $null
            }
            else {
                $MessageObject.session.input_audio_noise_reduction = @{type = $InputAudioNoiseReductionType }
            }
        }

        $InputAudioTranscriptionParam = @{
            model = $InputAudioTranscriptionModel
        }
        if ($PSBoundParameters.ContainsKey('InputAudioTranscriptionLanguage')) {
            $InputAudioTranscriptionParam.language = $InputAudioTranscriptionLanguage
        }
        if ($PSBoundParameters.ContainsKey('InputAudioTranscriptionPrompt')) {
            $InputAudioTranscriptionParam.prompt = $InputAudioTranscriptionPrompt
        }
        $MessageObject.session.input_audio_transcription = $InputAudioTranscriptionParam

        if ($PSBoundParameters.ContainsKey('EnableTurnDetection')) {
            if (-not $EnableTurnDetection) {
                $MessageObject.session.turn_detection = $null
            }
            else {
                $MessageObject.session.turn_detection = @{type = $TurnDetectionType }
                if ($PSBoundParameters.ContainsKey('TurnDetectionEagerness')) {
                    $MessageObject.session.turn_detection.eagerness = $TurnDetectionEagerness
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionThreshold')) {
                    $MessageObject.session.turn_detection.threshold = $TurnDetectionThreshold
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionPrefixPadding')) {
                    $MessageObject.session.turn_detection.prefix_padding_ms = $TurnDetectionPrefixPadding
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionThreshold')) {
                    $MessageObject.session.turn_detection.silence_duration_ms = $TurnDetectionSilenceDuration
                }
                if ($PSBoundParameters.ContainsKey('CreateResponseOnTurnEnd')) {
                    $MessageObject.session.turn_detection.create_response = $CreateResponseOnTurnEnd
                }
                if ($PSBoundParameters.ContainsKey('InterruptResponse')) {
                    $MessageObject.session.turn_detection.interrupt_response = $InterruptResponse
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('Include')) {
            $MessageObject.session.include = $Include
        }

        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}