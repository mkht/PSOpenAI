---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-ThreadRunStep.md
schema: 2.0.0
---

# Get-ThreadRunStep

## SYNOPSIS
Retrieves a run step.

## SYNTAX

### Get
```
Get-ThreadRunStep
    [-RunId] <String>
    [-ThreadId] <String>
    [-StepId] <String>
    [-Include <String[]>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

### List
```
Get-ThreadRunStep
    [-RunId] <String>
    [-ThreadId] <String>
    [-All]
    [-Limit <Int32>]
    [-Order <String>]
    [-Include <String[]>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Retrieves a run step.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-Thread 'thread_abc123' | Get-ThreadRun | Get-ThreadRunStep -All
```

List all run step objects associated with the Thread whose ID is `thread_abc123`.


## PARAMETERS

### -RunId
The ID of the run to retrieve.

```yaml
Type: String
Aliases: run_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -ThreadId
The ID of the thread to retrieve.

```yaml
Type: String
Parameter Sets: Get
Aliases: thread_id
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName)
```

### -StepId
The ID of the step to retrieve.

```yaml
Type: String
Parameter Sets: Get
Aliases: step_id
Required: True
Position: 2
Accept pipeline input: True (ByPropertyName)
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
When this switch is specified, all Step objects will be retrieved.

```yaml
Type: SwitchParameter
Parameter Sets: ListAll
Required: False
Position: Named
```

### -Order
Sort order by the created timestamp of the objects. `asc` for ascending order and `desc` for descending order. The default is `asc`

```yaml
Type: String
Parameter Sets: List, ListAll
Accepted values: asc, desc
Required: False
Position: Named
Default value: asc
```

### -Include
A list of additional fields to include in the response.

```yaml
Type: String[]
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

[https://platform.openai.com/docs/api-reference/runs/getRunStep](https://platform.openai.com/docs/api-reference/runs/getRunStep)
[https://platform.openai.com/docs/api-reference/runs/listRunSteps](https://platform.openai.com/docs/api-reference/runs/listRunSteps)
