---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Remove-RealtimeSessionItem.md
schema: 2.0.0
---

# Remove-RealtimeSessionItem

## SYNOPSIS
Remove an item from the conversation history. 

## SYNTAX

```
Remove-RealtimeSessionItem
    [-ItemId] <String>
    [-EventId <String>]
```

## DESCRIPTION
Remove an item from the conversation history. 

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-RealtimeSessionItem -ItemId 'msg_001'
```

## PARAMETERS

### -ItemId
The ID of the item to delete.

```yaml
Type: String
Required: True
Position: Named
```

### -EventId
Optional client-generated ID used to identify this event.

```yaml
Type: String
Required: False
Position: Named
```

## INPUTS


## OUTPUTS

## NOTES

## RELATED LINKS

[https://developers.openai.com/api/docs/guides/realtime-conversations/](https://developers.openai.com/api/docs/guides/realtime-conversations/)
