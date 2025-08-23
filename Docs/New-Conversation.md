---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/New-Conversation.md
schema: 2.0.0
---

# New-Conversation

## SYNOPSIS
Create a new conversation.

## SYNTAX

```
New-Conversation
    [-MetaData <IDictionary>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [<CommonParameters>]
```

## DESCRIPTION
Create a new conversation.

## EXAMPLES

### Example 1
```powershell
PS C:\> $Conversation = New-Conversation
```
Creates a new conversation.

## PARAMETERS

### -MetaData
A dictionary of metadata to associate with the conversation.

```yaml
Type: IDictionary
Required: False
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

[https://platform.openai.com/docs/api-reference/conversations/create](https://platform.openai.com/docs/api-reference/conversations/create)
