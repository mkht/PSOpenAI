---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-Conversation.md
schema: 2.0.0
---

# Get-Conversation

## SYNOPSIS
Get a conversation with the given ID.
## SYNTAX

```
Get-Conversation
    [-ConversationId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [<CommonParameters>]
```

## DESCRIPTION
Get a conversation with the given ID.

## EXAMPLES

### Example 1
```powershell
PS C:\> $Conversation = Get-Conversation -ConversationId 'conv_abc123'
```

Retrieves a Conversation object with the ID `conv_abc123`.

## PARAMETERS

### -ConversationId
The unique identifier of the conversation to retrieve.

```yaml
Type: String
Aliases: conversation_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
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

[https://platform.openai.com/docs/api-reference/conversations/retrieve](https://platform.openai.com/docs/api-reference/conversations/retrieve)
