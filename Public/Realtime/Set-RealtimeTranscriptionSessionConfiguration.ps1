function Set-RealtimeTranscriptionSessionConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId,

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
        [bool]$EnableInputAudioTranscription = $true,

        [Parameter()]
        [Completions('whisper-1', 'gpt-4o-transcribe', 'gpt-4o-mini-transcribe', 'gpt-4o-transcribe-diarize')]
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
        [Completions('item.input_audio_transcription.logprobs')]
        [AllowEmptyCollection()]
        [string[]]$Include
    )

    begin {
        $MessageObject = @{type = 'session.update'; session = @{type = 'transcription' } }
    }

    process {
        if (-not [string]::IsNullOrEmpty($EventId)) {
            $MessageObject.event_id = $EventId
        }

        if ($PSBoundParameters.ContainsKey('Include')) {
            $MessageObject.session.include = $Include
        }

        # Input audio settings
        $InputAudioSettings = @{}
        if ($PSBoundParameters.ContainsKey('InputAudioFormat')) {
            switch ($InputAudioFormat) {
                'pcm16' {
                    $InputAudioSettings.format = @{
                        type = 'audio/pcm'
                        rate = 24000
                    }
                }
                'g711_ulaw' {
                    $InputAudioSettings.format = @{
                        type = 'audio/pcmu'
                    }
                }
                'g711_alaw' {
                    $InputAudioSettings.format = @{
                        type = 'audio/pcma'
                    }
                }
                default {
                    $InputAudioSettings.format = $InputAudioFormat
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('InputAudioNoiseReductionType')) {
            if ([string]::IsNullOrWhiteSpace($InputAudioNoiseReductionType) `
                    -or $InputAudioNoiseReductionType -eq 'none') {
                $InputAudioSettings.noise_reduction = $null
            }
            else {
                $InputAudioSettings.noise_reduction = @{type = $InputAudioNoiseReductionType }
            }
        }

        if (-not $EnableInputAudioTranscription) {
            $InputAudioSettings.transcription = $null
        }
        else {
            $InputAudioTranscriptionParam = @{
                model = $InputAudioTranscriptionModel
            }
            if ($PSBoundParameters.ContainsKey('InputAudioTranscriptionLanguage')) {
                $InputAudioTranscriptionParam.language = $InputAudioTranscriptionLanguage
            }
            if ($PSBoundParameters.ContainsKey('InputAudioTranscriptionPrompt')) {
                $InputAudioTranscriptionParam.prompt = $InputAudioTranscriptionPrompt
            }
            $InputAudioSettings.transcription = $InputAudioTranscriptionParam
        }

        if ($PSBoundParameters.ContainsKey('EnableTurnDetection')) {
            if (-not $EnableTurnDetection) {
                $InputAudioSettings.turn_detection = $null
            }
            else {
                $InputAudioTurnDetectionParam = @{
                    type = $TurnDetectionType
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionEagerness')) {
                    $InputAudioTurnDetectionParam.eagerness = $TurnDetectionEagerness
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionIdleTimeout')) {
                    $InputAudioTurnDetectionParam.idle_timeout_ms = $TurnDetectionIdleTimeout
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionThreshold')) {
                    $InputAudioTurnDetectionParam.threshold = $TurnDetectionThreshold
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionPrefixPadding')) {
                    $InputAudioTurnDetectionParam.prefix_padding_ms = $TurnDetectionPrefixPadding
                }
                if ($PSBoundParameters.ContainsKey('TurnDetectionSilenceDuration')) {
                    $InputAudioTurnDetectionParam.silence_duration_ms = $TurnDetectionSilenceDuration
                }
                if ($PSBoundParameters.ContainsKey('CreateResponseOnTurnEnd')) {
                    $InputAudioTurnDetectionParam.create_response = $CreateResponseOnTurnEnd
                }
                if ($PSBoundParameters.ContainsKey('InterruptResponse')) {
                    $InputAudioTurnDetectionParam.interrupt_response = $InterruptResponse
                }
            }
        }

        if ($InputAudioSettings.Keys.Count -gt 0) {
            if (-not $MessageObject.session.ContainsKey('audio')) {
                $MessageObject.session.audio = @{}
            }
            $MessageObject.session.audio.input = $InputAudioSettings
        }

        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}