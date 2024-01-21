---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-AzureAudioTranscription.md
schema: 2.0.0
---

# Request-AzureAudioTranscription

## SYNOPSIS
Transcribes audio into the input language.

## SYNTAX

### Language (Default)
```
Request-AzureAudioTranscription
    [[-File] <String>]
    -Deployment <String>
    [-Prompt <String>]
    [-Format <String>]
    [-Temperature <Double>]
    [-Language <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <System.Uri>]
    [-ApiVersion <string>]
    [-ApiKey <Object>]
    [-AuthType <string>]
    [<CommonParameters>]
```


## DESCRIPTION
Transcribes audio into the input language.  
https://learn.microsoft.com/en-us/azure/ai-services/openai/reference#speech-to-text

## EXAMPLES

### Example 1: Audio-to-Text
```PowerShell
PS C:\> $global:OPENAI_API_KEY = '<Put your api key here>'
PS C:\> $global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'
PS C:\> Request-AzureAudioTranscription -File C:\sample\audio.mp3 -Format text -Deployment 'YourDeploymentName'
```
```
Hello, I am david.
```

## PARAMETERS

### -File
(Required)
The audio file to transcribe, in one of these formats: `flac`, `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `ogg`, `wav`, or `webm`.  
The file size limit for the Azure OpenAI Whisper model is 25 MB.

```yaml
Type: String
Required: True
Position: 1
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Deployment
The deployment name you chose when you deployed the model.  
Deployments must be created in Azure Portal in advance.

```yaml
Type: String
Aliases: Engine
Required: True
Position: Named
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
Specifies the name of your Azure OpenAI resource endpoint such like: `https://{your-resource-name}.openai.azure.com/`  
If not specified, it will try to use `$global:OPENAI_API_BASE` or `$env:OPENAI_API_BASE`

```yaml
Type: System.Uri
Required: False
Position: Named
```

### -ApiVersion
The API version to use for this operation.  

```yaml
Type: string
Required: False
Position: Named
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

### -AuthType
Specifies the authentication type.  
You can choose from `azure` or `azure_ad`.  
The default value is `azure`

```yaml
Type: string
Required: False
Position: Named
Default value: "azure"
```

## INPUTS

## OUTPUTS

### [string]
## NOTES

## RELATED LINKS

[https://learn.microsoft.com/en-us/azure/ai-services/openai/reference#speech-to-text](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference#speech-to-text)

