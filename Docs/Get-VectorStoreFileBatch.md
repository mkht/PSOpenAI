---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-VectorStoreFileBatch.md
schema: 2.0.0
---

# Get-VectorStoreFileBatch

## SYNOPSIS
Retrieves a vector store file batch.

## SYNTAX

```
Get-VectorStoreFileBatch
    [-VectorStoreId] <String>
    [-BatchId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Retrieves a vector store file batch.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-VectorStoreFileBatch -VectorStoreId "vs_abc123" -BatchId 'vsfb_abc123'
```

Get a vector store file batch with ID `vsfb_abc123`.

## PARAMETERS

### -VectorStoreId
The ID of the vector store that the batch belongs to.

```yaml
Type: String
Aliases: vector_store_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -BatchId
The ID of the file batch being retrieved.

```yaml
Type: String
Aliases: batch_id
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName)
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

[https://developers.openai.com/api/reference/resources/vector_stores/subresources/file_batches/methods/retrieve/](https://developers.openai.com/api/reference/resources/vector_stores/subresources/file_batches/methods/retrieve/)
