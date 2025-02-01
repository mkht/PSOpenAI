function Set-RealtimeSessionConfiguration {
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
            'ash',
            'ballad',
            'coral',
            'echo',
            'sage',
            'shimmer',
            'verse'
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
        [string]$InputAudioTranscriptionLanguage,

        [Parameter()]
        [string]$InputAudioTranscriptionPrompt,

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
        [bool]$CreateResponseOnTurnEnd = $true,

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
                if ($PSBoundParameters.ContainsKey('CreateResponseOnTurnEnd')) {
                    $MessageObject.session.turn_detection.create_response = $CreateResponseOnTurnEnd
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
                $MessageObject.session.max_response_output_tokens = $MaxResponseOutputTokens
            }
        }

        if ($PSBoundParameters.ContainsKey('Tools')) {
            $MessageObject.session.tools = $Tools
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            $MessageObject.session.tool_choice = $ToolChoice
        }

        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}