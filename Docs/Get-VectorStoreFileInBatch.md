---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-VectorStoreFileInBatch.md
schema: 2.0.0
---

# Get-VectorStoreFileInBatch

## SYNOPSIS
Returns a list of vector store files in a batch.

## SYNTAX

### List
```
Get-VectorStoreFileInBatch
    [-VectorStoreId] <String>
    [-BatchId] <String>
    [-All]
    [-Limit <Int32>]
    [-Order <String>]
    [-Filter <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Returns a list of vector store files in a batch.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-VectorStoreFileInBatch -VectorStoreId 'vs_abc123' -BatchId 'vsfb_abc123' -All
```

Get all files in the vector store batch with ID of `vsfb_abc123`.

## PARAMETERS

### -VectorStoreId
The ID of the vector store that the batch belongs to.

```yaml
Type: String
Parameter Sets: List
Aliases: vector_store_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -BatchId
The ID of the file batch being retrieved.

```yaml
Type: String
Parameter Sets: List
Aliases: batch_id
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName)
```

### -Filter
Filter by file status. One of `in_progress`, `completed`, `failed`, `cancelled`.

```yaml
Type: String
Parameter Sets: List
Required: False
Position: Named
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

### -All
When this switch is specified, all files in a batch will be retrieved.

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

[https://developers.openai.com/api/reference/resources/vector_stores/subresources/file_batches/methods/list_files/](https://developers.openai.com/api/reference/resources/vector_stores/subresources/file_batches/methods/list_files/)
