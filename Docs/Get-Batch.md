---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-Batch.md
schema: 2.0.0
---

# Get-Batch

## SYNOPSIS
Retrieves a batch.

## SYNTAX

### Get
```
Get-Batch 
    [-BatchId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiType <OpenAIApiType>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
```

### List
```
Get-Batch
    [-All]
    [-Limit <Int32>] 
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiType <OpenAIApiType>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
```

## DESCRIPTION
Get an batch or List multiple batches

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-Batch -Limit 5
```

Get latest 5 batches.

### Example 2
```powershell
PS C:\> Get-Batch -All
```

Get all batches.

### Example 3
```powershell
PS C:\> Get-Batch -BatchId 'batch_abc123'
```

Get a batch with ID of `batch_abc123`.

## PARAMETERS

### -BatchId
The ID of the batch to retrieve.

```yaml
Type: String
Parameter Sets: Get
Aliases: Id, batch_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
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
When this switch is specified, all batch objects will be retrieved.

```yaml
Type: SwitchParameter
Parameter Sets: List
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

[https://platform.openai.com/docs/api-reference/batch/list](https://platform.openai.com/docs/api-reference/batch/list)
[https://platform.openai.com/docs/api-reference/batch/retrieve](https://platform.openai.com/docs/api-reference/batch/retrieve)
