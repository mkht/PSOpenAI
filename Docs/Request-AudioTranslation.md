---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-AudioTranslation.md
schema: 2.0.0
---

# Request-AudioTranslation

## SYNOPSIS
Translates audio into English.

## SYNTAX

```
Request-AudioTranslation
    [[-File] <String>]
    [-Model <String>]
    [-Prompt <String>]
    [-Format <String>]
    [-Temperature <Double>]
    [-TimeoutSec <Int32>]
    [-Token <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Translates audio into English.  
https://platform.openai.com/docs/guides/speech-to-text/speech-to-text

## EXAMPLES

### Example 1: Japanese speech to English text.
```PowerShell
Request-AudioTranslation -File C:\sample\japanese.mp3 -Format text
```
```
Hello, My name is tanaka yoshio.
```

## PARAMETERS

### -File
(Required)
The audio file to translate, in one of these formats: `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, or `webm`.

```yaml
Type: String
Required: False
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
The prompt should be in English.

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

