---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Start-ThreadRun.md
schema: 2.0.0
---

# Start-ThreadRun

## SYNOPSIS
Starts a run.

## SYNTAX

```
Start-ThreadRun
    [-InputObject] <Object>
    -Assistant <Object>
    [-Model <String>]
    [-Instructions <String>]
    [-AdditionalInstructions <String>]
    [-Tools <IDictionary[]>]
    [-UseCodeInterpreter <Boolean>]
    [-UseRetrieval <Boolean>]
    [-MetaData <IDictionary>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Starts a run.

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-ThreadRun -Thread 'thread_abc123' -Assistant 'asst_abc123'
```

Starts a run of the thread with spcified assiatnt.


## PARAMETERS

### -InputObject
The ID of the thread to run.

```yaml
Type: Object
Aliases: Thread, thread_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Assistant
The ID of the assistant to use to execute this run.

```yaml
Type: Object
Aliases: assistant_id
Required: True
Position: Named
Accept pipeline input: True (ByPropertyName)
```

### -Model
The name of the Model to be used to execute this run. If a value is provided here, it will override the model associated with the assistant. If not, the model associated with the assistant will be used.

```yaml
Type: String
Required: False
Position: Named
```

### -Instructions
Overrides the instructions of the assistant. This is useful for modifying the behavior on a per-run basis.

```yaml
Type: String
Required: False
Position: Named
```

### -AdditionalInstructions
Appends additional instructions at the end of the instructions for the run. This is useful for modifying the behavior on a per-run basis without overriding other instructions.

```yaml
Type: String
Aliases: additional_instructions
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

### -Tools
Override the tools the assistant can use for this run.

```yaml
Type: IDictionary[]
Required: False
Position: Named
```

### -UseCodeInterpreter
Override whether the code interpreter tool enable or not.

```yaml
Type: Boolean
Required: False
Position: Named
```

### -UseRetrieval
Override whether the retrieval tool enable or not.

```yaml
Type: Boolean
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

[https://platform.openai.com/docs/api-reference/runs/createRun](https://platform.openai.com/docs/api-reference/runs/createRun)

