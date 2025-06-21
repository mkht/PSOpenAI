---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Connect-RealtimeSession.md
schema: 2.0.0
---

# Connect-RealtimeSession

## SYNOPSIS
Create a new OpenAI realtime conversation session.

## SYNTAX

```
Connect-RealtimeSession
    [-Model <String>]
    [-ApiType <OpenAIApiType>]
    [-ApiBase <Uri>]
    [-AuthType <String>]
    [-ApiKey <SecureString>]
```

## DESCRIPTION
Create a new realtime conversation session. This technically means connecting to the WebSocket endpoint provided by the OpenAI Realtime API.

Once the session is opened, the connection will continue until it is disconnected from the server side or a Disconnect-RealtimeSession is executed. You always need run Disconnect-RealtimeSession when you are finished conversation.

## EXAMPLES

### Example 1
```powershell
PS C:\> Connect-RealtimeSession -Model 'gpt-4o-realtime-preview'
```

## PARAMETERS
### -Model
It is recommended that you always specify the model you want to use.

```yaml
Type: String
Required: False
Position: Named
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

### -ApiType
Specifies API type of use. `OpenAI`(default) or `Azure`

```yaml
Type: OpenAIApiType
Accepted values: OpenAI, Azure
Required: False
Position: Named
Default value: OpenAI
```

### -AuthType
If you wish to use Entra-ID based authentication, specifies as `azure_ad`.

```yaml
Type: String
Accepted values: openai, azure, azure_ad
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/realtime](https://platform.openai.com/docs/guides/realtime)
