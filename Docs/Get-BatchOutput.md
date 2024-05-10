---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-BatchOutput.md
schema: 2.0.0
---

# Get-BatchOutput

## SYNOPSIS
Retrieve batch output (result) items.

## SYNTAX

```
Get-BatchOutput
    [-BatchId] <String>
    [-Wait]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Retrieve batch output (result) items.

## EXAMPLES

### Example 1
```powershell
PS C:\> $Result = Get-BatchOutput 'batch_abc123'
```

Get an output data in the specified ID of batch

## PARAMETERS

### -BatchId
Specifies a Batch ID.

```yaml
Type: String
Aliases: Id, batch_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Wait
When the Wait switch is used, it waits until that the Batch is completed and then returns the result.

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

Batch output items are stored on OpenAI storage as JSONL files. This cmdlet does not delete files on the storage.

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/batch/requestOutput](https://platform.openai.com/docs/api-reference/batch/requestOutput)
