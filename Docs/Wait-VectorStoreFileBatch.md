---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Wait-VectorStoreFileBatch.md
schema: 2.0.0
---

# Wait-VectorStoreFileBatch

## SYNOPSIS
Waits until the vector store file batch is completed.

## SYNTAX

### StatusForWait
```
Wait-VectorStoreFileBatch
    [-InputObject] <Object>
    [-BatchId] <String>
    [-StatusForWait <String[]>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

### StatusForExit
```
Wait-VectorStoreFileBatch
    [-InputObject] <Object>
    [-BatchId] <String>
    [-StatusForExit <String[]>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Waits until the vector store file batch is completed.

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-VectorStoreFileBatch -InputObject 'vs_abc123' -FileId ('file-abc123', 'file-def456', 'file-ghi789') | Wait-VectorStoreFileBatch
```

Start a batch and wait for completes.

## PARAMETERS

### -InputObject
The ID of the vector store that the file batch belongs to.

```yaml
Type: Object
Aliases: VectorStore, vector_store_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -BatchId
The ID of the batch to wait.

```yaml
Type: String
Aliases: batch_id, Id
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName)
```

### -StatusForExit
By default, this cmdlet exits when the status of batch is anything other than `in_progress`.  
If specifies one or more statuses for `-StatusForExit`, this cmdlet waits until batch reaches that status.  
This parameter cannot be used simultaneously with `-StatusForWait`.

```yaml
Type: String[]
Parameter Sets: StatusForExit
Accepted values: failed, in_progress, completed, cancelling, cancelled
Required: False
Position: Named
```

### -StatusForWait
If one or more statuses are specified in `-StatusForWait`, this cmdlet will exit when a batch changes to a status other than that.  
Note: Do not specify `completed` for this parameter. cmdlet may not exit permanently.  
This parameter cannot be used simultaneously with `-StatusForExit`.

```yaml
Type: String[]
Parameter Sets: StatusForWait
Accepted values: failed, in_progress, completed, cancelling, cancelled
Required: False
Position: Named
Default value: in_progress
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
