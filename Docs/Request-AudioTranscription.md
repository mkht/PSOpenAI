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
    [-File] <String>
    [-Model <String>]
    [-Prompt <String>]
    [-ResponseFormat <String>]
    [-Temperature <Double>]
    [-Include <String[]>]
    [-KnownSpeakerNames <String[]>]
    [-KnownSpeakerReferences <String[]>]
    [-ChunkingStrategy <String>]
    [-ChunkingStrategyThreshold <Float>]
    [-ChunkingStrategyPrefixPadding <UInt16>]
    [-ChunkingStrategySilenceDuration <UInt16>]
    [-TimestampGranularities <String[]>]
    [-Language <String>]
    [-Stream]
    [-StreamOutputType <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [-Organization <String>]
    [<CommonParameters>]
```


## DESCRIPTION
Transcribes audio into the input language.  
https://platform.openai.com/docs/guides/speech-to-text/speech-to-text

## EXAMPLES

### Example 1: Audio-to-Text
```PowerShell
PS C:\> Request-AudioTranscription -File C:\sample\audio.mp3 -ResponseFormat text
```
```
Hello, I am david.
```

### Example 2: Speaker diarization
```PowerShell
PS C:\> $JsonResult = Request-AudioTranscription -File C:\sample\meeting.mp3 -Model gpt-4o-transcribe-diarize -ResponseFormat diarized_json
PS C:\> $JsonResult | ConvertFrom-Json
```

## PARAMETERS

### -File
(Required)
The audio file to transcribe, in one of these formats: `flac`, `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `ogg`, `wav`, or `webm`.  

```yaml
Type: String
Required: True
Position: 0
Accept pipeline input: True (ByValue)
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

### -ResponseFormat
The format of the transcript output, in one of these options: `json`, `text`, `srt`, `verbose_json`, `vtt`  or `diarized_json`.  
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

### -Include
Additional information to include in the transcription response.  
`logprobs` only works with `-ResponseFormat` set to `json` and only with the models `gpt-4o-transcribe` and `gpt-4o-mini-transcribe`

```yaml
Type: String[]
Required: False
Position: Named
```

### -KnownSpeakerNames
Optional list of speaker names that correspond to the audio samples provided in `-KnownSpeakerReferences`. Each entry should be a short identifier (for example customer or agent). Up to 4 speakers are supported.

```yaml
Type: String[]
Required: False
Position: Named
```

### -KnownSpeakerReferences
Optional list of audio samples that contain known speaker references matching `-KnownSpeakerNames`. Each sample must be between 2 and 10 seconds, and can use any of the same input audio formats supported by file.

```yaml
Type: String[]
Required: False
Position: Named
```

### -ChunkingStrategy
Controls how the audio is cut into chunks. Options are: `auto`, `server_vad`.
The default value is `auto`.

```yaml
Type: String
Required: False
Position: Named
```

### -ChunkingStrategyThreshold
Sensitivity threshold (0.0 to 1.0) for voice activity detection.

```yaml
Type: Float
Required: False
Position: Named
```

### -ChunkingStrategyPrefixPadding
Amount of audio to include before the VAD detected speech (in milliseconds).

```yaml
Type: UInt16
Required: False
Position: Named
```

### -ChunkingStrategySilenceDuration
Duration of silence to detect speech stop (in milliseconds).

```yaml
Type: UInt16
Required: False
Position: Named
```

### -TimestampGranularities
The timestamp granularities to populate for this transcription. Any of these options: `word`, or `segment`. The default is `segment`.

```yaml
Type: String[]
Aliases: timestamp_granularities
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

### -Stream
If set to true, the model response data will be streamed.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: False
```

### -StreamOutputType
The format of the stream output, `text` or `object`.  
The default value is `text`. This parameter is only used when `-Stream` is enabled.

```yaml
Type: String
Required: False
Position: Named
Default value: text
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
Specifies the maximum number of retries if the request fails.  
The default value is `0` (No retry).  
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

[https://platform.openai.com/docs/guides/speech-to-text/speech-to-text](https://platform.openai.com/docs/guides/speech-to-text/speech-to-text)

[https://platform.openai.com/docs/api-reference/audio/create](https://platform.openai.com/docs/api-reference/audio/create)

