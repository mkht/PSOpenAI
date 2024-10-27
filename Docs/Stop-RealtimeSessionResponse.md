---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Stop-RealtimeSessionResponse.md
schema: 2.0.0
---

# Stop-RealtimeSessionResponse

## SYNOPSIS
Send the event to cancel an in-progress response.

## SYNTAX

```
Stop-RealtimeSessionResponse
    [-EventId <String>]
```

## DESCRIPTION
Send the event to cancel an in-progress response.

## EXAMPLES

### Example 1
```powershell
PS C:\> Stop-RealtimeSessionResponse
```

## PARAMETERS

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

[https://platform.openai.com/docs/api-reference/realtime-client-events/response/cancel](https://platform.openai.com/docs/api-reference/realtime-client-events/response/cancel)
