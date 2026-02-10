---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-ThreadMessage.md
schema: 2.0.0
---

# Get-ThreadMessage

## SYNOPSIS
Lists or Retrieves a Message of the Thread.

## SYNTAX

### Get
```
Get-ThreadMessage
    [-ThreadId] <String>
    -MessageId <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

### List
```
Get-ThreadMessage
    [-ThreadId] <String>
    [-All]
    [-Limit <Int32>]
    [-Order <String>]
    [-RunId <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Lists or Retrieves a Message of the Thread.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-ThreadMessage -ThreadId 'thread_abc123' -All
```

List all message objects associated with the Thread whose ID is `thread_abc123`.

### Example 2
```powershell
PS C:\> Get-ThreadMessage -ThreadId 'thread_abc123' -MessageId 'msg_abc123'
```

Retrieve a message with ID `msg_abc123` associated with the Thread whose ID is `thread_abc123`.


## PARAMETERS

### -ThreadId
The ID of the Thread for retrieve.

```yaml
Type: String
Aliases: thread_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -MessageId
The ID of the Message to retrieve.

```yaml
Type: String
Parameter Sets: Get
Aliases: message_id
Required: True
Position: Named
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Limit
A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.

```yaml
Type: Int32
Parameter Sets: List
Required: False
Position: Named
Default value: 20
```

### -RunId
Filter messages by the run ID that generated them.

```yaml
Type: String
Parameter Sets: List
Aliases: run_id
Required: False
Position: Named
```

### -All
When this switch is specified, all Message objects will be retrieved.

```yaml
Type: SwitchParameter
Parameter Sets: List
Required: False
Position: Named
```

### -Order
Sort order by the created timestamp of the objects. `asc` for ascending order and `desc` for descending order. The default is `asc`

```yaml
Type: String
Parameter Sets: List
Accepted values: asc, desc
Required: False
Position: Named
Default value: asc
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
Note : Retries will only be performed if the request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. Other errors (e.g., authentication failure) will not be performed.  

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
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

### -Organization
Specifies Organization ID which used for an API request.  
If not specified, it will try to use `$global:OPENAI_ORGANIZATION` or `$env:OPENAI_ORGANIZATION`

```yaml
Type: string
Aliases: OrgId
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

### PSCustomObject

## NOTES

## RELATED LINKS

[https://developers.openai.com/api/reference/resources/beta/subresources/threads/subresources/messages/methods/retrieve/](https://developers.openai.com/api/reference/resources/beta/subresources/threads/subresources/messages/methods/retrieve/)
[https://developers.openai.com/api/reference/resources/beta/subresources/threads/subresources/messages/methods/list/](https://developers.openai.com/api/reference/resources/beta/subresources/threads/subresources/messages/methods/list/)
