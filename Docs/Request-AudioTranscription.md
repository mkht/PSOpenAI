---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-AudioTranscription.md
schema: 2.0.0
---

# Request-AudioTranscription

## SYNOPSIS
Transcribes audio into the input language.

## SYNTAX

### Language (Default)
```
Request-AudioTranscription
    [[-File] <String>]
    [-Model <String>]
    [-Prompt <String>]
    [-Format <String>]
    [-Temperature <Double>]
    [-Language <String>]
    [-TimeoutSec <Int32>]
    [-Token <Object>]
    [<CommonParameters>]
```


## DESCRIPTION
Transcribes audio into the input language.  
https://platform.openai.com/docs/guides/speech-to-text/speech-to-text

## EXAMPLES

### Example 1: Audio-to-Text
```PowerShell
PS C:\> Request-AudioTranscription -File C:\sample\audio.mp3 -Format text
```
```yaml
Hello, I am david.
```

## PARAMETERS

### -File
(Required)
The audio file to transcribe, in one of these formats: `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, or `webm`.

```yaml
Type: String
Required: True
Position: 1
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Model
The name of model to use.
The default value is `whisper-1`.

```yaml
Type: String
Required: False
Position: Named
Default value: whisper-1
```

### -Prompt
An optional text to guide the model's style or continue a previous audio segment.  
The prompt should match the audio language.

```yaml
Type: String
Required: False
Position: Named
```

### -Format
The format of the transcript output, in one of these options: `json`, `text`, `srt`, `verbose_json`, or `vtt`.  
The default value is `text`.

```yaml
Type: String
Aliases: response_format
Required: False
Position: Named
Default value: text
```

### -Temperature
The sampling temperature, between `0` and `1`.  
Higher values like `0.8` will make the output more random, while lower values like `0.2` will make it more focused and deterministic.

```yaml
Type: Double
Required: False
Position: Named
```

### -Language
The language of the input audio.  
Supplying the input language in `ISO-639-1` format will improve accuracy and latency.

```yaml
Type: String
Required: False
Position: Named
```

### -TimeoutSec
Specifies how long the request can be pending before it times out.  
The default value is `0` (infinite).

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -Token
Specifies API key for authentication.  
The type of data should `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_TOKEN` or `$env:OPENAI_TOKEN`

```yaml
Type: Object
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

### [string]
## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/speech-to-text/speech-to-text](https://platform.openai.com/docs/guides/speech-to-text/speech-to-text)

[https://platform.openai.com/docs/api-reference/audio/create](https://platform.openai.com/docs/api-reference/audio/create)

