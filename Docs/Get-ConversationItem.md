---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-ConversationItem.md
schema: 2.0.0
---

# Get-ConversationItem

## SYNOPSIS
List items or get a specific item from a conversation.

## SYNTAX

### List items
```
Get-ConversationItem
    [-ConversationId] <String>
    [-Limit <Int32>]
    [-All]
    [-After <String>]
    [-Order <String>]
    [-Include <String[]>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [<CommonParameters>]
```

### Get a specific item
```
Get-ConversationItem
    [-ConversationId] <String>
    [-ItemId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [<CommonParameters>]
```

## DESCRIPTION
Retrieves items from a conversation or a specific item by its ID.  
Supports pagination, ordering, and additional query options.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-ConversationItem -ConversationId 'conv_abc123' -Limit 10
```
Retrieves the list of items in the conversation with ID `conv_abc123`. Limits the result to 10 items.

### Example 2
```powershell
PS C:\> Get-ConversationItem -ConversationId 'conv_abc123' -ItemId 'item_xyz789'
```
Retrieves a specific item with ID `item_xyz789` from the conversation `conv_abc123`.

### Example 3
```powershell
PS C:\> Get-ConversationItem -ConversationId 'conv_abc123' -All
```
Retrieves all items from the conversation, handling pagination automatically.

## PARAMETERS

### -ConversationId
The unique identifier of the conversation.

```yaml
Type: String
Aliases: Conversation, conversation_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -ItemId
The unique identifier of the item to retrieve.

```yaml
Type: String
Aliases: item_id
Required: True (when using 'Get' parameter set)
Position: 1
Accept pipeline input: True (ByPropertyName)
```

### -Limit
The maximum number of items to retrieve per request.  
Default is `20`. Maximum is `100`.

```yaml
Type: Int32
Required: False
Position: Named
Default value: 20
```

### -All
If specified, retrieves all items by automatically handling pagination.

```yaml
Type: Switch
Required: False
Position: Named
```

### -After
A cursor for pagination. Retrieves items after the specified item ID.

```yaml
Type: String
Required: False
Position: Named
```

### -Order
The order in which to return items. Allowed values: `asc`, `desc`. Default is `asc`.

```yaml
Type: String
Required: False
Position: Named
Default value: asc
```

### -Include
Specify additional output data to include in the model response. 

```yaml
Type: String[]
Required: False
Position: Named
```

### -TimeoutSec
Specifies how long the request can be pending before it times out.  
Default is `0` (infinite).

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -MaxRetryCount
Specifies the maximum number of retries if the request fails.  
Default is `0` (No retry).

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -ApiBase
Specifies the API endpoint URL.

```yaml
Type: System.Uri
Required: False
Position: Named
```

### -ApiKey
Specifies the API key for authentication.

```yaml
Type: SecureString
Required: False
Position: Named
```


## INPUTS

### String

## OUTPUTS

### PSCustomObject

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/conversations/list-items](https://platform.openai.com/docs/api-reference/conversations/list-items)
