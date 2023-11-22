---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Wait-ThreadRun.md
schema: 2.0.0
---

# Wait-ThreadRun

## SYNOPSIS
Waits until the run is completed.

## SYNTAX

### StatusForWait
```
Wait-ThreadRun
    [-InputObject] <Object>
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
Wait-ThreadRun
    [-InputObject] <Object>
    [-StatusForExit <String[]>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Waits until the run is completed.

## EXAMPLES

### Example 1
```powershell
PS C:\> $Thread | Start-ThreadRun | Wait-ThreadRun
```

Start a run and wait for completes.

### Example 1
```powershell
PS C:\> $Run | Stop-ThreadRun | Wait-ThreadRun -StatusForExit 'cancelled'
```

Requests a run cancellation and wait for cancelled.

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

### -StatusForExit
By default, this cmdlet exits when the status of Run is anything other than `queued` or `in_progress`.  
If specifies one or more statuses for `-StatusForExit`, this cmdlet waits until Run reaches that status.  
This parameter cannot be used simultaneously with `-StatusForWait`.

```yaml
Type: String[]
Parameter Sets: StatusForExit
Accepted values: queued, in_progress, completed, requires_action, expired, cancelling, cancelled, failed
Required: False
Position: Named
```

### -StatusForWait
If one or more statuses are specified in `-StatusForWait`, this cmdlet will exit when Run changes to a status other than that.  
Note: Do not specify `completed` for this parameter. cmdlet may not exit permanently.  
This parameter cannot be used simultaneously with `-StatusForExit`.

```yaml
Type: String[]
Parameter Sets: StatusForWait
Accepted values: queued, in_progress, completed, requires_action, expired, cancelling, cancelled, failed
Required: False
Position: Named
Default value: queued, in_progress
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
Note 1: Retries will only be performed if the request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. Other errors (e.g., authentication failure) will not be performed.  
Note 2: Retry intervals increase exponentially with jitters, such as `1s > 2s > 4s > 8s > 16s`

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

### PSCustomObject

## NOTES

## RELATED LINKS

