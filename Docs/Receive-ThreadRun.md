---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Receive-ThreadRun.md
schema: 2.0.0
---

# Receive-ThreadRun

## SYNOPSIS
Gets the results of the Run.

## SYNTAX

```
Receive-ThreadRun
    [-RunId] <String>
    [-ThreadId] <String>
    [-Wait]
    [-AutoRemoveThread]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Gets the results of the Run. Return is a Thread object.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-ThreadRun -RunId 'run_abc123' -ThreadId 'thread_abc123' | Receive-ThreadRun
```

Gets the results of the specified Run.

### Example 2
```powershell
PS C:\> Start-ThreadRun -ThreadId 'thread_abc123' | Receive-ThreadRun -Wait
```

When the Wait switch is used, it waits until that Run is completed and then returns the result.


## PARAMETERS

### -RunId
The ID of the run to retrieve.

```yaml
Type: String
Aliases: run_id
Required: True
Position: 0
Accept pipeline input: True (ByValue, ByPropertyName)
```

### -ThreadId
The ID of the thread that was run.

```yaml
Type: String
Aliases: thread_id
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName)
```

### -Wait
When the Wait switch is used, it waits until that Run is completed and then returns the result.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -AutoRemoveThread
Remove the Thread associated with the Run after retrieving the results of the Run.

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

