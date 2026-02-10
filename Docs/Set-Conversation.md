---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Set-Conversation.md
schema: 2.0.0
---

# Set-Conversation

## SYNOPSIS
Update a conversation's metadata with the given ID.

## SYNTAX

```
Set-Conversation
    [-ConversationId] <String>
    -MetaData <IDictionary>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [<CommonParameters>]
```

## DESCRIPTION
Update a conversation. Currently, only the metadata can be modified.

## EXAMPLES

### Example 1
```powershell
PS C:\> $Conversation = Set-Conversation -ConversationId 'conv_abc123' -MetaData @{ topic = 'project-x'; priority = 'high' }
```

Update a conversation metadata with the ID `conv_abc123`.

## PARAMETERS

### -ConversationId
The ID of the conversation to update.

```yaml
Type: String
Aliases: Conversation, conversation_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -MetaData
Set of key-value pairs that can be attached to a conversation. Useful for storing additional structured information.

```yaml
Type: IDictionary
Required: True
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
Note: Retries will only be performed if the request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. Other errors (e.g., authentication failure) will not be retried.

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -ApiBase
Specifies an API endpoint URL such as: `https://your-api-endpoint.test/v1`  
If not specified, it will use `https://api.openai.com/v1`.

```yaml
Type: System.Uri
Required: False
Position: Named
Default value: https://api.openai.com/v1
```

### -ApiKey
Specifies API key for authentication.  
The type of data should be `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_API_KEY` or `$env:OPENAI_API_KEY`.

```yaml
Type: SecureString
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

### PSCustomObject

## NOTES

## RELATED LINKS

[https://developers.openai.com/api/reference/resources/conversations/methods/update/](https://developers.openai.com/api/reference/resources/conversations/methods/update/)
