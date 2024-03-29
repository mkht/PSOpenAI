---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Stop-ThreadRun.md
schema: 2.0.0
---

# Stop-ThreadRun

## SYNOPSIS
Cancels a run that is in_progress.

## SYNTAX

```
Stop-ThreadRun
    [-InputObject] <Object>
    [-Wait]
    [-Force]
    [-PassThru]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Cancels a run that is in_progress.

## EXAMPLES

### Example 1
```powershell
PS C:\> Stop-ThreadRun -Run 'run_abc123'
```

Cancels a run.

## PARAMETERS

### -InputObject
The run object to cancel.

```yaml
Type: Object
Aliases: Run
Required: True
Position: 0
Accept pipeline input: True (ByValue)
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
By default, This cmdlet only requests cancel a run that the status is `queued`, `in_progress` or `requires_action`.  
When the switch specified, Always requests cancel any status of the run.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -PassThru
By default, This cmdlet returns nothing.
When the PassThru switch specified, This cmdlet returns Run object.

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
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
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

[https://platform.openai.com/docs/api-reference/runs/cancelRun](https://platform.openai.com/docs/api-reference/runs/cancelRun)

