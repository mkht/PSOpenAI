---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Set-VectorStore.md
schema: 2.0.0
---

# Set-VectorStore

## SYNOPSIS
Modifies a vector store.

## SYNTAX

```
Set-VectorStore
    [-VectorStoreId] <String>
    [-Name <String>]
    [-ExpiresAfterDays <UInt16>]
    [-ExpiresAfterAnchor <String>]
    [-MetaData <IDictionary>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Modifies a vector store.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-VectorStore -VectorStoreId 'vs_abc123' -Name 'NewName-123'
```

Modifies a name of vector store.

## PARAMETERS

### -VectorStoreId
The ID of the vector store to modify.

```yaml
Type: String
Aliases: vector_store_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -Name
New name of the vector store.

```yaml
Type: String
Required: False
Position: Named
```

### -ExpiresAfterDays
The number of days after the anchor time that the vector store will expire.

```yaml
Type: UInt16
Required: False
Position: Named
```

### -ExpiresAfterAnchor
Anchor timestamp after which the expiration policy applies. Supported anchors: `last_active_at`.

```yaml
Type: String
Required: False
Position: Named
Default value: last_active_at
```

### -MetaData
Set of 16 key-value pairs that can be attached to an object. This can be useful for storing additional information about the object in a structured format.

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

[https://developers.openai.com/api/reference/resources/vector_stores/methods/update/](https://developers.openai.com/api/reference/resources/vector_stores/methods/update/)
