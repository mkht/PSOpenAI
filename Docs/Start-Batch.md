---
external help file: PSOpenAI-help.xml
Module Name: PsopenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Start-Batch.md
schema: 2.0.0
---

# Start-Batch

## SYNOPSIS
Creates and executes a batch from an uploaded file or input objects.

## SYNTAX

### BatchInput
```
Start-Batch
    -BatchInput <Object[]>
    [-Endpoint <String>]
    [-CompletionWindow <String>]
    [-OutputExpiresAfterSeconds <Int32>]
    [-OutputExpiresAfterAnchor <String>]
    [-MetaData <IDictionary>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

### FileId
```
Start-Batch
    -FileId <String>
    [-Endpoint <String>]
    [-CompletionWindow <String>]
    [-OutputExpiresAfterSeconds <Int32>]
    [-OutputExpiresAfterAnchor <String>]
    [-MetaData <IDictionary>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates and executes a batch from an uploaded file or input objects.

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-Batch -FileId 'file-abc123'
```

Creates and executes a batch from an uploaded file. You need to upload formatted jsonl file to the OpenAI storage in advance.

### Example 2
```powershell
PS C:\> $BatchInputs = @()
PS C:\> $BatchInputs += Request-ChatCompletion -Message 'Good morning.' -Model gpt-4o-mini -AsBatch -CustomBatchId 'custom-1'
PS C:\> $BatchInputs += Request-ChatCompletion -Message 'Good night.' -Model gpt-4o-mini -AsBatch -CustomBatchId 'custom-2'

PS C:\> Start-Batch -InputObject $BatchInputs
```

Creates and executes a batch from input items.  
You can create a batch input item by using the Request-ChatCompletion cmdlet with `-AsBatch` switch.

## PARAMETERS

### -BatchInput
Specifies batch input objects.

```yaml
Type: Object[]
Parameter Sets: BatchObject
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -FileId
Specifies a input file id that is uploaded on the OpenAI storage in advance.

```yaml
Type: String
Parameter Sets: FileId
Aliases: input_file_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -CompletionWindow
The time frame within which the batch should be processed. Currently only "24h" is supported.

```yaml
Type: String
Aliases: completion_window
Required: False
Position: Named
Default value: 24h
```

### -Endpoint
The endpoint to be used for all requests in the batch. Currently "/v1/chat/completions", "/v1/embeddings", and "/v1/completions" are supported.

```yaml
Type: String
Required: False
Position: Named
Default value: /v1/chat/completions
```

### -OutputExpiresAfterSeconds
The number of seconds after the anchor time that the file will expire. Must be between 3600 (1 hour) and 2592000 (30 days).

```yaml
Type: Int32
Required: False
Position: Named
```

### -OutputExpiresAfterAnchor
Anchor timestamp after which the expiration policy applies. Supported anchors: `created_at`.

```yaml
Type: String
Required: False
Position: Named
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
Parameter Sets: (All)
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

This cmdlet will upload Batch input items to the OpenAI storage as a JSONL file implicitly.

## RELATED LINKS

[https://developers.openai.com/api/reference/resources/batches/methods/create/](https://developers.openai.com/api/reference/resources/batches/methods/create/)
