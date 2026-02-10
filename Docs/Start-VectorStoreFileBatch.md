---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Start-VectorStoreFileBatch.md
schema: 2.0.0
---

# Start-VectorStoreFileBatch

## SYNOPSIS
Create and run vector store file batch.

## SYNTAX

```
Start-VectorStoreFileBatch
    [-VectorStoreId] <String>
    [-Attributes <Hashtable>]
    [-Files] <Object[]>
    [-ChunkingStrategy <String>]
    [-MaxChunkSizeTokens <Int32>]
    [-ChunkOverlapTokens <Int32>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Create and run vector store file batch.

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-VectorStoreFileBatch -VectorStoreId 'vs_abc123' -Files ('file-abc123', 'file-def456', 'file-ghi789')
```

Start a batch for adding 3 files to the vector store with ID `vs_abc123`

## PARAMETERS

### -VectorStoreId
The ID of the vector store for which to create a File Batch.

```yaml
Type: String
Aliases: vector_store_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -Attributes
Set of 16 key-value pairs that can be attached to an object. 

```yaml
Type: Hashtable
Required: False
Position: Named
```

### -Files
A list of File IDs that the vector store should use.

```yaml
Type: object[]
Aliases: file_ids, FileId
Required: True
Position: 1
```

### -ChunkingStrategy
The chunking strategy used to chunk the file(s). If not set, will use the "auto" strategy.

```yaml
Type: String
Aliases: chunking_strategy
Required: False
Position: Named
```

### -MaxChunkSizeTokens
The maximum number of tokens in each chunk. The default value is 800. The minimum value is 100 and the maximum value is 4096.  
Note that the parameter only acceptable when the ChunkingStrategy is "static".

```yaml
Type: String
Aliases: max_chunk_size_tokens
Required: False
Position: Named
Default value: 800
```

### -ChunkOverlapTokens
The number of tokens that overlap between chunks. The default value is 400. The value must not exceed half of MaxChunkSizeTokens.  
Note that the parameter only acceptable when the ChunkingStrategy is "static".

```yaml
Type: String
Aliases: chunk_overlap_tokens
Required: False
Position: Named
Default value: 400
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

[https://developers.openai.com/api/reference/resources/vector_stores/subresources/file_batches/methods/create/](https://developers.openai.com/api/reference/resources/vector_stores/subresources/file_batches/methods/create/)
