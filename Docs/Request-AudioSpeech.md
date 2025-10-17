---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-AudioSpeech.md
schema: 2.0.0
---

# Request-AudioSpeech

## SYNOPSIS
Generates audio from the input text.

## SYNTAX

### Language (Default)
```
Request-AudioSpeech
    [-Text] <String>
    [-Model <String>]
    [-Voice <String>]
    [-Instructions <String>]
    [-ResponseFormat <String>]
    -OutFile <String>
    [-Speed <Double>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [-Organization <String>]
    [<CommonParameters>]
```


## DESCRIPTION
Generates audio from the input text.  
https://platform.openai.com/docs/guides/text-to-speech

## EXAMPLES

### Example 1: Text-to-Speech (Basic)
```PowerShell
Request-AudioSpeech -Text 'Hello.' -OutFile 'C:\sample\audio.mp3'
```

### Example 2: Text-to-Speech (Options)
```PowerShell
Request-AudioSpeech `
  -Text 'The quick brown fox jumped over the lazy dog.' `
  -OutFile 'C:\sample\audio.aac' `
  -Model tts-1-hd `
  -Voice Onyx `
  -Speed 1.2
```

## PARAMETERS

### -Text
(Required)  
The text to generate audio for. The maximum length is 4096 characters.

```yaml
Type: String
Aliases: Input
Required: True
Position: 0
Accept pipeline input: True (ByValue)
```

### -Model
One of the available TTS models: `tts-1`, `tts-1-hd` or `gpt-4o-mini-tts`.  
The default value is `tts-1`.

```yaml
Type: String
Required: False
Position: Named
Default value: tts-1
```

### -Voice
The voice to use when generating the audio. Supported voices are `alloy`, `ash`, `coral`, `echo`, `fable`, `onyx`, `nova`, `sage` and `shimmer`.  
The default value is `alloy`.

```yaml
Type: String
Required: False
Position: Named
Default value: alloy
```

### -Instructions
Control the voice of your generated audio with additional instructions. Does not work with `tts-1` or `tts-1-hd`.

```yaml
Type: String
Required: True
Position: Named
```

### -ResponseFormat
The format of audio. Supported formats are `mp3`, `opus`, `aac`, `flac`, `wav`, and `pcm`

```yaml
Type: String
Aliases: response_format
Required: False
Position: Named
```

### -OutFile
(Required)  
The path of the file to save.

```yaml
Type: String
Required: True
Position: Named
```

### -Speed
The speed of the generated audio. Select a value from `0.25` to `4.0`. `1.0` is the default.

```yaml
Type: Double
Required: False
Position: Named
Default value: 1.0
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

### -MaxRetryCount
Number between `0` and `100`.  
Specifies the maximum number of retries if the request fails. The default value is `0` (No retry).  
Note : Retries will only be performed if the request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. Other errors (e.g., authentication failure) will not be performed.  

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -ApiBase
Specifies an API endpoint URL such like: `https://your-api-endpoint.test/v1`  
If not specified, it will use `https://api.openai.com/v1`

```yaml
Type: System.Uri
Required: False
Position: Named
Default value: https://api.openai.com/v1
```

### -ApiKey
Specifies API key for authentication.  
The type of data should `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_API_KEY` or `$env:OPENAI_API_KEY`

```yaml
Type: Object
Required: False
Position: Named
```

### -Organization
Specifies Organization ID which used for an API request.  
If not specified, it will try to use `$global:OPENAI_ORGANIZATION` or `$env:OPENAI_ORGANIZATION`

```yaml
Type: string
Aliases: OrgId
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

### [string]
## NOTES

## RELATED LINKS
[https://platform.openai.com/docs/guides/text-to-speech](https://platform.openai.com/docs/guides/text-to-speech)

[https://platform.openai.com/docs/api-reference/audio/createSpeech](https://platform.openai.com/docs/api-reference/audio/createSpeech)
