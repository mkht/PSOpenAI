---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Set-RealtimeSessionConfiguration.md
schema: 2.0.0
---

# Set-RealtimeSessionConfiguration

## SYNOPSIS
Set the realtime session's configuration.

## SYNTAX

```
Set-RealtimeSessionConfiguration
    [-EventId <String>]
    [-Instructions <String>]
    [-PromptId <String>]
    [-PromptVariables <IDictionary>]
    [-PromptVersion <String>]
    [-Modalities <String[]>]
    [-Voice <String>] 
    [-Speed <Double>] 
    [-InputAudioFormat <String>]
    [-OutputAudioFormat <String>]
    [-InputAudioNoiseReductionType <String>]
    [-EnableInputAudioTranscription <Boolean>]
    [-InputAudioTranscriptionModel <String>]
    [-InputAudioTranscriptionLanguage <String>]
    [-InputAudioTranscriptionPrompt <String>]
    [-EnableTurnDetection <Boolean>] 
    [-TurnDetectionType <String>] 
    [-TurnDetectionEagerness <String>] 
    [-TurnDetectionThreshold <Single>]
    [-TurnDetectionPrefixPadding <UInt16>]
    [-TurnDetectionSilenceDuration <UInt16>]
    [-TurnDetectionIdleTimeout <UInt16>]
    [-CreateResponseOnTurnEnd <Boolean>]
    [-InterruptResponse <Boolean>]
    [-Tools <IDictionary[]>]
    [-ToolChoice <String>]
    [-Temperature <Single>]
    [-MaxOutputTokens <Int32>]
    [-Tracing <String>]
    [-TracingGroupId <String>]
    [-TracingMetadata <IDictionary>]
    [-TracingWorkflowName <String>]
```

## DESCRIPTION
Set the realtime session's configuration.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-RealtimeSessionConfiguration `
    -Modalities 'audio' `
    -Voice 'marin' `
    -EnableInputAudioTranscription $true `
    -EnableTurnDetection $true
```

## PARAMETERS

### -EnableInputAudioTranscription
Enables input audio transcription.

```yaml
Type: Boolean
Required: False
Position: Named
```

### -EnableTurnDetection
Enables the server VAD mode. In this mode, the server will run voice activity detection (VAD) over the incoming audio and respond after the end of speech.

```yaml
Type: Boolean
Required: False
Position: Named
```

### -EventId
Optional client-generated ID used to identify this event.

```yaml
Type: String
Required: False
Position: Named
```

### -InputAudioFormat
The format of input audio. Options are `pcm16`, `g711_ulaw`, or `g711_alaw`.

```yaml
Type: String
Required: False
Position: Named
```

### -InputAudioNoiseReductionType
Type of noise reduction. `none` is disable, `near_field` is for close-talking microphones such as headphones, `far_field` is for far-field microphones such as laptop or conference room microphones.

```yaml
Type: String
Required: False
Position: Named
```

### -InputAudioTranscriptionModel
The model to use for transcription, current options are `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, and `whisper-1`

```yaml
Type: String
Required: False
Position: Named
Default value: whisper-1
```

### -InputAudioTranscriptionLanguage
The language of the input audio. Supplying the input language in ISO-639-1 (e.g. en) format will improve accuracy and latency.

```yaml
Type: String
Required: False
Position: Named
```

### -InputAudioTranscriptionPrompt
An optional text to guide the model's style or continue a previous audio segment. The prompt should match the audio language.

```yaml
Type: String
Required: False
Position: Named
```

### -Instructions
The default system instructions (i.e. system message) prepended to model calls. This field allows the client to guide the model on desired responses.

```yaml
Type: String
Required: False
Position: Named
```

### -PromptId
The unique identifier of the prompt template to use.

```yaml
Type: String
Required: False
Position: Named
```

### -PromptVariables
Optional map of values to substitute in for variables in your prompt. The substitution values can either be strings, or other Response input types like images or files.

```yaml
Type: IDictionary
Required: False
Position: Named
```

### -PromptVersion
Optional version of the prompt template.

```yaml
Type: String
Required: False
Position: Named
```

### -MaxOutputTokens
Maximum number of output tokens for a single assistant response. Provide an integer between 1 and 4096 to limit output tokens, or -1 for no limitations.

```yaml
Type: Int32
Required: False
Position: Named
Default value: -1
```

### -Modalities
The set of modalities the model can respond with.

```yaml
Type: String[]
Accepted values: text, audio
Required: False
Position: Named
```

### -OutputAudioFormat
The format of output audio. Options are `pcm16`, `g711_ulaw`, or `g711_alaw`.

```yaml
Type: String
Required: False
Position: Named
```

### -Temperature
Sampling temperature for the model, limited to [0.6, 1.2].

```yaml
Type: Single
Required: False
Position: Named
```

### -ToolChoice
How the model chooses tools. Options are `auto`, `none`, `required`, or specify a function.

```yaml
Type: String
Required: False
Position: Named
```

### -Tools
Tools (functions) available to the model.

```yaml
Type: IDictionary[]
Required: False
Position: Named
```

### -TurnDetectionPrefixPadding
Amount of audio to include before the VAD detected speech (in milliseconds).

```yaml
Type: UInt16
Required: False
Position: Named
```

### -TurnDetectionSilenceDuration
Duration of silence to detect speech stop (in milliseconds). With shorter values the model will respond more quickly, but may jump in on short pauses from the user.

```yaml
Type: UInt16
Required: False
Position: Named
```

### -TurnDetectionThreshold
Activation threshold for VAD (0.0 to 1.0), this defaults to 0.5. A higher threshold will require louder audio to activate the model, and thus might perform better in noisy environments.

```yaml
Type: Single
Required: False
Position: Named
```

### -TurnDetectionType
Type of turn detection, `server_vad` is automatically chunks the audio based on periods of silence, `semantic_vad` is chunks the audio when the model believes based on the words said by the user that they have completed their utterance.

```yaml
Type: String
Required: False
Position: Named
Default value: server_vad
```

### -TurnDetectionEagerness
Used only for `semantic_vad` mode. The eagerness of the model to respond. `low` will wait longer for the user to continue speaking, `high` will respond more quickly. `auto` is the default and is equivalent to `medium`.

```yaml
Type: String
Required: False
Position: Named
Default value: auto
```

### -CreateResponseOnTurnEnd
Whether or not to automatically generate a response when VAD is enabled. true by default.

```yaml
Type: Boolean
Required: False
Position: Named
Default value: True
```

### -InterruptResponse
Whether or not to automatically interrupt any ongoing response with output to the default conversation when a VAD start event occurs. true by default.

```yaml
Type: Boolean
Required: False
Position: Named
Default value: True
```

### -Voice
The voice the model uses to respond. Cannot be changed once the model has responded with audio at least once.

```yaml
Type: String
Required: False
Position: Named
```

### -Speed
The speed of the model's spoken response. 1.0 is the default speed. 0.25 is the minimum speed. 1.5 is the maximum speed.

```yaml
Type: Double
Required: False
Position: Named
```

### -Tracing
Configuration options for tracing. Set to null to disable tracing. Once tracing is enabled for a session, the configuration cannot be modified. `auto` will create a trace for the session with default settings.

```yaml
Type: String
Required: False
Position: Named
```

### -TracingGroupId
The group id to attach to this trace to enable filtering and grouping in the traces dashboard.

```yaml
Type: String
Required: False
Position: Named
```

### -TracingMetadata
The arbitrary metadata to attach to this trace to enable filtering in the traces dashboard.

```yaml
Type: IDictionary
Required: False
Position: Named
```

### -TracingWorkflowName
The name of the workflow to attach to this trace. This is used to name the trace in the traces dashboard.

```yaml
Type: String
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/realtime-client-events/session/update](https://platform.openai.com/docs/api-reference/realtime-client-events/session/update)
