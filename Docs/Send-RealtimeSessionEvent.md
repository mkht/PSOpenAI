---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Send-RealtimeSessionEvent.md
schema: 2.0.0
---

# Send-RealtimeSessionEvent

## SYNOPSIS
Send any client event to the server.

## SYNTAX

```
Send-RealtimeSessionEvent 
    [-Message] <String>
```

## DESCRIPTION
Sends an arbitrary message expressed as a JSON string to the session. This is useful for sending custom events that PSOpenAI does not support in its functions.

## EXAMPLES

### Example 1
```powershell
PS C:\> Send-RealtimeSessionEvent -Message '{"event_id": "event_567", "type": "response.cancel"}'
```

## PARAMETERS

### -Message
JSON-formatted message.

```yaml
Type: String
Required: True
Position: 0
Accept pipeline input: True (ByValue)
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/realtime-client-events](https://platform.openai.com/docs/api-reference/realtime-client-events)
