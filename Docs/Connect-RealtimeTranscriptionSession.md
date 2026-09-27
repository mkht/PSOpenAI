---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Connect-RealtimeTranscriptionSession.md
schema: 2.0.0
---

# Connect-RealtimeTranscriptionSession

## SYNOPSIS
Create a new OpenAI realtime transcription session.

## SYNTAX

```
Connect-RealtimeTranscriptionSession
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
```

## DESCRIPTION
Create a new realtime transcription session. This technically means connecting to the WebSocket endpoint provided by the OpenAI Realtime API.

Once the session is opened, the connection will continue until it is disconnected from the server side or a DisConnect-RealtimeSession is executed. You always need run DisConnect-RealtimeSession when you are finished conversation.

## EXAMPLES

### Example 1
```powershell
PS C:\> Connect-RealtimeTranscriptionSession
```

## PARAMETERS

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://developers.openai.com/api/docs/guides/realtime-transcription](https://developers.openai.com/api/docs/guides/realtime-transcription)
