---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Wait-Batch.md
schema: 2.0.0
---

# Wait-Batch

## SYNOPSIS
Waits until the batch is completed.

## SYNTAX

```
Wait-Batch
    [-BatchId] <String>
    [-StatusForWait <String[]>]
    [-StatusForExit <String[]>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-PollIntervalSec <Float>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Waits until the batch is completed.

## EXAMPLES

### Example 1
```powershell
PS C:\> $BatchInputs | Start-Batch | Wait-Batch
```

Start a batch and wait for completes.

### Example 2
```powershell
PS C:\> $Batch | Stop-Batch | Wait-Batch -StatusForExit 'cancelled'
```

Requests a batch cancellation and wait for cancelled.

## PARAMETERS

### -BatchId
The batch id to cancel.

```yaml
Type: Object
Aliases: Id, batch_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -StatusForExit
By default, this cmdlet exits when the status of batch is anything other than 'validating', 'in_progress' or 'finalizing'.  
If specifies one or more statuses for `-StatusForExit`, this cmdlet waits until batch reaches that status.  

```yaml
Type: String[]
Accepted values: validating, failed, in_progress, finalizing, completed, expired, cancelling, cancelled
Required: False
Position: Named
```

### -StatusForWait
If one or more statuses are specified in `-StatusForWait`, this cmdlet will exit when a batch changes to a status other than that.  
Note: Do not specify `completed` for this parameter. cmdlet may not exit permanently.  

```yaml
Type: String[]
Accepted values: validating, failed, in_progress, finalizing, completed, expired, cancelling, cancelled
Required: False
Position: Named
Default value: validating, in_progress, finalizing
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

### -PollIntervalSec
Specifies the interval in seconds to poll the batch status.
The default value is `1`.

```yaml
Type: Float
Required: False
Position: Named
Default value: 1.0
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
