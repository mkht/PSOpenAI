---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Remove-Assistant.md
schema: 2.0.0
---

# Remove-Assistant

## SYNOPSIS
Delete an assistant.

## SYNTAX

```
Remove-Assistant
    [-InputObject] <Object>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Delete an assistant.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-Assistant -Assistant 'asst_abc123'
```

Remove an assistant that has the ID with `asst_abc123`

### Example 2
```powershell
PS C:\> Get-Assistant -All | Remove-Assistant
```

Remove all assistants.


## PARAMETERS

### -InputObject
Specifies ID of an assistant or Assistant object.

```yaml
Type: Object
Aliases: Assistant, assistant_id
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
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

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/assistants/deleteAssistant](https://platform.openai.com/docs/api-reference/assistants/deleteAssistant)

