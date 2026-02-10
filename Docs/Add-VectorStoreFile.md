---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Add-VectorStoreFile.md
schema: 2.0.0
---

# Add-VectorStoreFile

## SYNOPSIS
Attach a file to a vector store.

## SYNTAX

```
Add-VectorStoreFile
    [-VectorStoreId] <Object>
    [-FileId] <String>
    [-ChunkingStrategy <String>]
    [-MaxChunkSizeTokens <Int32>]
    [-ChunkOverlapTokens <Int32>]
    [-PassThru]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Attach a file to a vector store.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-VectorStoreFile -VectorStoreId 'vs_abc123' -FileId 'file-abc123'
```

Attach a file with ID `file-abc123` to the vector store with ID `vs_abc123`.

### Example 2
```powershell
PS C:\> $Store = Get-VectorStoreFile -VectorStoreId 'vs_abc123'
PS C:\> $Store = $Store | Add-VectorStoreFile -FileId 'file-abc123' -PassThru
```

Attach a file with ID `file-abc123` to the vector store with ID `vs_abc123`. Then, updates the object of `$Store`

## PARAMETERS

### -VectorStoreId
The ID of the vector store for which to add a File.

```yaml
Type: String
Aliases: vector_store_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -FileId
A File ID that the vector store should use.

```yaml
Type: String
Aliases: file_id
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName, ByValue)
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

### -PassThru
Returns a Vector Store object that the file added. By default, this cmdlet doesn't return any output.

```yaml
Type: SwitchParameter
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

[https://developers.openai.com/api/reference/resources/vector_stores/subresources/files/methods/create/](https://developers.openai.com/api/reference/resources/vector_stores/subresources/files/methods/create/)
