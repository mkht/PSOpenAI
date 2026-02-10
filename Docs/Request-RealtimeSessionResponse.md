---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-RealtimeSessionResponse.md
schema: 2.0.0
---

# Request-RealtimeSessionResponse

## SYNOPSIS
Instruct the server to generate a response.

## SYNTAX

```
Request-RealtimeSessionResponse
    [-EventId <String>]
    [-Instructions <String>]
    [-OutputModalities <String[]>]
    [-Voice <String>]
    [-OutputAudioFormat <String>]
    [-Temperature <Single>]
    [-MaxOutputTokens <Int32>]
```

## DESCRIPTION
Instruct the server to generate a response. When automatic turn detection by the server is enabled, this is usually not necessary. If turn detection is disabled, use this command to request a response from the server.

## EXAMPLES

### Example 1
```powershell
PS C:\> Request-RealtimeSessionResponse
```

## PARAMETERS

### -EventId
Optional client-generated ID used to identify this event.

```yaml
Type: String
Required: False
Position: Named
```

### -Instructions
Instructions for the model.

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

### -OutputModalities
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

### -Voice
The voice the model uses to respond.

```yaml
Type: String
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://developers.openai.com/api/docs/guides/realtime-conversations/](https://developers.openai.com/api/docs/guides/realtime-conversations/)
