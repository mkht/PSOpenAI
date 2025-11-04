---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Set-RealtimeTranscriptionSessionConfiguration.md
schema: 2.0.0
---

# Set-RealtimeTranscriptionSessionConfiguration

## SYNOPSIS
Set the realtime transcription session's configuration.

## SYNTAX

```
Set-RealtimeTranscriptionSessionConfiguration
    [-EventId <String>]
    [-InputAudioFormat <String>]
    [-InputAudioNoiseReductionType <String>]
    [-InputAudioTranscriptionModel <String>]
    [-InputAudioTranscriptionLanguage <String>]
    [-InputAudioTranscriptionPrompt <String>]
    [-EnableTurnDetection <Boolean>] 
    [-TurnDetectionType <String>] 
    [-TurnDetectionEagerness <String>] 
    [-TurnDetectionThreshold <Single>]
    [-TurnDetectionPrefixPadding <UInt16>]
    [-TurnDetectionSilenceDuration <UInt16>]
    [-CreateResponseOnTurnEnd <Boolean>]
    [-InterruptResponse <Boolean>]
    [-Include <Single[]>]
```

## DESCRIPTION
Set the realtime transcription session's configuration.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-RealtimeTranscriptionSessionConfiguration `
    -InputAudioTranscriptionModel 'gpt-4o-transcribe'
    -InputAudioTranscriptionLanguage 'de'
    -EnableTurnDetection $true
    -TurnDetectionType 'server_vad'
    -TurnDetectionThreshold 0.5
```

## PARAMETERS

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
Not available for transcription sessions.

```yaml
Type: Boolean
Required: False
Position: Named
Default value: True
```

### -InterruptResponse
Not available for transcription sessions.

```yaml
Type: Boolean
Required: False
Position: Named
Default value: True
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/realtime-client-events/transcription_session/update](https://platform.openai.com/docs/api-reference/realtime-client-events/transcription_session/update)
