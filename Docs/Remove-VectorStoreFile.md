---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Remove-VectorStoreFile.md
schema: 2.0.0
---

# Remove-VectorStoreFile

## SYNOPSIS
Delete a vector store file.
## SYNTAX

```
Remove-VectorStoreFile
    [-VectorStoreId] <String>
    [-FileId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Delete a vector store file. This will remove the file from the vector store but the file itself will not be deleted. To delete the file, use `Remove-OpenAIFile`.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-VectorStoreFile -VectorStoreId 'vs_abc123' -FileId 'file-abc123'
```

Deletes a file with ID `file-abc123` from the vector store with ID `vs_ab123`

## PARAMETERS

### -VectorStoreId
The ID of the vector store that the file belongs to.

```yaml
Type: String
Aliases: vector_store_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -FileId
The ID of the file being removed.

```yaml
Type: String
Aliases: file_id
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

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/vector-stores-files/deleteFile](https://platform.openai.com/docs/api-reference/vector-stores-files/deleteFile)
