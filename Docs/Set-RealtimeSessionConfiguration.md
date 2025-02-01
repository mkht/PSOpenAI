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
    [-Modalities <String[]>]
    [-Voice <String>] 
    [-InputAudioFormat <String>]
    [-OutputAudioFormat <String>]
    [-EnableInputAudioTranscription <Boolean>]
    [-InputAudioTranscriptionModel <String>]
    [-InputAudioTranscriptionLanguage <String>]
    [-InputAudioTranscriptionPrompt <String>]
    [-EnableTurnDetection <Boolean>] 
    [-TurnDetectionType <String>] 
    [-TurnDetectionThreshold <Single>]
    [-TurnDetectionPrefixPadding <UInt16>]
    [-TurnDetectionSilenceDuration <UInt16>]
    [-CreateResponseOnTurnEnd <Boolean>]
    [-Tools <IDictionary[]>]
    [-ToolChoice <String>]
    [-Temperature <Single>]
    [-MaxResponseOutputTokens <Int32>]
```

## DESCRIPTION
Set the realtime session's configuration.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-RealtimeSessionConfiguration `
    -Modalities 'text','audio' `
    -Voice 'shimmer' `
    -EnableInputAudioTranscription $true `
    -EnableTurnDetection $true
    -Temperature 1.0
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

### -InputAudioTranscriptionModel
The model to use for transcription, `whisper-1` is the only currently supported model.

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

### -MaxResponseOutputTokens
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
Type of turn detection, only `server_vad` is currently supported.
```yaml
Type: String
Required: False
Position: Named
Default value: server_vad
```

### -CreateResponseOnTurnEnd
Whether or not to automatically generate a response when VAD is enabled. true by default.
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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/realtime-client-events/session/update](https://platform.openai.com/docs/api-reference/realtime-client-events/session/update)
