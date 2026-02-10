---
external help file: PSOpenAI-help.xml
Module Name: PsopenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Stop-Batch.md
schema: 2.0.0
---

# Stop-Batch

## SYNOPSIS
Cancels an in-progress batch.

## SYNTAX

```
Stop-Batch
    [-BatchId] <String>
    [-Wait]
    [-Force]
    [-PassThru]
    [-InputObject] <Object>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Cancels an in-progress batch.

## EXAMPLES

### Example 1
```powershell
PS C:\> $Batch = Start-Batch -FileId 'file_abc123'
PS C:\> $Batch = $Batch | Stop-Batch -Force -PassThru
PS C:\> $Batch.status    # cancelling
```

Cancels an in-progress batch.

### Example 1
```powershell
PS C:\> $Batch = Start-Batch -FileId 'file_abc123'
PS C:\> $Batch = $Batch | Stop-Batch -Force -Wait -PassThru
PS C:\> $Batch.status    # cancelled
```

Cancels an in-progress batch. Then the cmdlet waits until the batch has been cancelled.

## PARAMETERS

### -BatchId
The batch id to cancel.

```yaml
Type: String
Aliases: Id, batch_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -Wait
By default, This cmdlet does not wait completes cancellation.  
When the switch specified, Waits for complete.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -Force
By default, This cmdlet only requests cancel a batch that the status is 'validating', 'in_progress' or 'finalizing'.  
When the switch specified, Always requests cancel any status of the batch.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -PassThru
By default, This cmdlet returns nothing.
When the PassThru switch specified, This cmdlet returns Batch object.

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

## RELATED LINKS

[https://developers.openai.com/api/reference/resources/batches/methods/cancel/](https://developers.openai.com/api/reference/resources/batches/methods/cancel/)
