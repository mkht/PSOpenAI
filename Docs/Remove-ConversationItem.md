---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Remove-ConversationItem.md
schema: 2.0.0
---

# Remove-ConversationItem

## SYNOPSIS
Delete an item from a conversation with the given ID.

## SYNTAX

```
Remove-ConversationItem
    -ConversationId <String>
    [-ItemId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [<CommonParameters>]
```

## DESCRIPTION
Delete an item from a conversation with the given ID.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-ConversationItem -ConversationId "conv_abc123" -ItemId "msg_xyz456"
```
Deletes the item with ID `msg_xyz456` from the conversation with ID `conv_abc123`.

## PARAMETERS

### -ConversationId
The ID of the conversation that contains the item.

```yaml
Type: String
Required: True
Position: Named
Aliases: Conversation, conversation_id
```

### -ItemId
The ID of the item to delete.

```yaml
Type: String
Required: True
Position: 0
Aliases: item_id
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

### None

## NOTES

## RELATED LINKS

[https://developers.openai.com/api/reference/resources/conversations/subresources/items/methods/delete/](https://developers.openai.com/api/reference/resources/conversations/subresources/items/methods/delete/)
