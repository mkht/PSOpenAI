function Set-RealtimeSessionConfiguration {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Instructions,

        [Parameter()]
        [string]$PromptId,

        [Parameter()]
        [System.Collections.IDictionary]$PromptVariables,

        [Parameter()]
        [string]$PromptVersion,

        [Parameter()]
        [ValidateSet('text', 'audio')]
        [string[]]$Modalities = @('text'),

        [Parameter()]
        [Completions('alloy', 'ash', 'ballad', 'coral', 'echo', 'sage', 'shimmer', 'verse', 'marin', 'cedar')]
        [string][LowerCaseTransformation()]$Voice,

        [Parameter()]
        [ValidateRange(0.25, 1.5)]
        [double]$Speed,

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
        [AllowEmptyString()]
        [Completions('near_field', 'far_field', 'none')]
        [string][LowerCaseTransformation()]$InputAudioNoiseReductionType,

        [Parameter()]
        [bool]$EnableInputAudioTranscription,

        [Parameter()]
        [Completions('whisper-1', 'gpt-4o-transcribe-latest', 'gpt-4o-transcribe', 'gpt-4o-transcribe-diarize', 'gpt-4o-mini-transcribe')]
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

        [Parameter()]
        [uint16]$TurnDetectionIdleTimeout,

        [Parameter()]
        [bool]$CreateResponseOnTurnEnd = $true,

        [Parameter()]
        [bool]$InterruptResponse = $true,

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
        [Completions('auto')]
        [AllowEmptyString()]
        [string]$Tracing,

        [Parameter()]
        [string]$TracingGroupId,

        [Parameter()]
        [System.Collections.IDictionary]$TracingMetadata,

        [Parameter()]
        [string]$TracingWorkflowName
    )

    begin {
        $MessageObject = @{type = 'session.update'; session = @{type = 'realtime' } }
    }

    process {
        if (-not [string]::IsNullOrEmpty($EventId)) {
            $MessageObject.event_id = $EventId
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $MessageObject.session.instructions = $Instructions
        }
        if ($PSBoundParameters.ContainsKey('Modalities')) {
            $MessageObject.session.output_modalities = $Modalities
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $MessageObject.session.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('MaxOutputTokens')) {
            if ($MaxOutputTokens -lt 0) {
                $MessageObject.session.max_output_tokens = 'inf'
            }
            else {
                $MessageObject.session.max_output_tokens = $MaxOutputTokens
            }
        }

        if ($PSBoundParameters.ContainsKey('PromptId')) {
            $MessageObject.session.prompt = @{id = $PromptId }
            if ($PSBoundParameters.ContainsKey('PromptVariables')) {
                $MessageObject.session.prompt.variables = $PromptVariables
            }
            if ($PSBoundParameters.ContainsKey('PromptVersion')) {
                $MessageObject.session.prompt.version = $PromptVersion
            }
        }

        if ($PSBoundParameters.ContainsKey('Tools')) {
            $MessageObject.session.tools = $Tools
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            $MessageObject.session.tool_choice = $ToolChoice
        }

        $TracingObject = @{}
        if ($PSBoundParameters.ContainsKey('TracingGroupId')) {
            $TracingObject.group_id = $TracingGroupId
        }
        if ($PSBoundParameters.ContainsKey('TracingMetadata')) {
            $TracingObject.metadata = $TracingMetadata
        }
        if ($PSBoundParameters.ContainsKey('TracingWorkflowName')) {
            $TracingObject.workflow_name = $TracingWorkflowName
        }

        if ($TracingObject.Keys.Count -gt 0) {
            $MessageObject.session.tracing = $TracingObject
        }
        else {
            if ($Tracing) {
                $MessageObject.session.tracing = $Tracing
            }
        }

        # Input audio settings
        $InputAudioSettings = @{}
        if ($PSBoundParameters.ContainsKey('InputAudioFormat')) {
            $InputAudioSettings.format = $InputAudioFormat
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

        if ($PSBoundParameters.ContainsKey('EnableInputAudioTranscription')) {
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

        # Output audio settings
        $OutputAudioSettings = @{}
        if ($PSBoundParameters.ContainsKey('OutputAudioFormat')) {
            $OutputAudioSettings.format = $OutputAudioFormat
        }
        if ($PSBoundParameters.ContainsKey('Speed')) {
            $OutputAudioSettings.speed = $Speed
        }
        if ($PSBoundParameters.ContainsKey('Voice')) {
            $OutputAudioSettings.voice = $Voice
        }

        if ($OutputAudioSettings.Keys.Count -gt 0) {
            if (-not $MessageObject.session.ContainsKey('audio')) {
                $MessageObject.session.audio = @{}
            }
            $MessageObject.session.audio.output = $OutputAudioSettings
        }

        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}