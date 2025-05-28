---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Remove-Container.md
schema: 2.0.0
---

# Remove-Container

## SYNOPSIS
Delete Container

## SYNTAX

```
Remove-Container
    [-ContainerId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Delete Container

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-Container 'cont_abc123'
```
Delete a container with ID `cont_abc123`.

## PARAMETERS

### -ContainerId
The ID of the container to delete.

```yaml
Type: String
Aliases: container_id, Container
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
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
Type: Object
Required: False
Position: Named
```

### -Organization
Specifies Organization ID used for an API request.  
If not specified, it will try to use `$global:OPENAI_ORGANIZATION` or `$env:OPENAI_ORGANIZATION`.

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

[https://platform.openai.com/docs/api-reference/containers/deleteContainer](https://platform.openai.com/docs/api-reference/containers/deleteContainer)
