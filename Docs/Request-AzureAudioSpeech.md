---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-AzureAudioSpeech.md
schema: 2.0.0
---

# Request-AzureAudioSpeech

## SYNOPSIS
Generates audio from the input text.

## SYNTAX

### Language (Default)
```
Request-AzureAudioSpeech
    [-Text] <String>
    -Deployment <String>
    [-Voice <String>]
    [-Format <String>]
    -OutFile <String>
    [-Speed <Double>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiVersion <String>]
    [-ApiKey <Object>]
    [-AuthType <String>]
    [<CommonParameters>]
```


## DESCRIPTION
Generates audio from the input text.  
https://learn.microsoft.com/en-us/azure/ai-services/openai/text-to-speech-quickstart

## EXAMPLES

### Example 1: Text-to-Speech (Basic)
```PowerShell
Request-AzureAzureAudioSpeech -Text 'Hello.' -Deployment 'tts-1' -OutFile 'C:\sample\audio.mp3'
```

### Example 2: Text-to-Speech (Options)
```PowerShell
Request-AzureAudioSpeech `
  -Text 'The quick brown fox jumped over the lazy dog.' `
  -OutFile 'C:\sample\audio.aac' `
  -Deployment 'tts-1-hd' `
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

### -Deployment
The deployment name you chose when you deployed the model.  
Deployments must be created in Azure OpenAI Studio in advance.

```yaml
Type: String
Aliases: Engine, Model
Required: True
Position: Named
```

### -Voice
The voice to use when generating the audio. Supported voices are `alloy`, `echo`, `fable`, `onyx`, `nova`, and `shimmer`.  
The default value is `alloy`.

```yaml
Type: String
Required: False
Position: Named
Default value: alloy
```

### -Format
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
Aliases: Token
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
[https://learn.microsoft.com/en-us/azure/ai-services/openai/text-to-speech-quickstart](https://learn.microsoft.com/en-us/azure/ai-services/openai/text-to-speech-quickstart)

[https://platform.openai.com/docs/guides/text-to-speech](https://platform.openai.com/docs/guides/text-to-speech)

