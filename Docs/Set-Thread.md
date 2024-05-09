---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Set-Thread.md
schema: 2.0.0
---

# Set-Thread

## SYNOPSIS
Modifies a thread.

## SYNTAX

```
Set-Thread
    [-ThreadId] <String>
    [-FileIdsForCodeInterpreter <Object[]>]
    [-VectorStoresForFileSearch <Object[]>]
    [-FileIdsForFileSearch <Object[]>]
    [-MetaData <IDictionary>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Modifies a thread. Currently only the metadata can be modified.

## EXAMPLES

### Example 1
```powershell
PS C:\> $Thread = Set-Thread -ThreadId 'thread_abc123' -MetaData $MetaData
```

Modifies a thread.

## PARAMETERS

### -ThreadId
The ID of the thread to modify.

```yaml
Type: String
Aliases: thread_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -FileIdsForCodeInterpreter
A list of file IDs made available to the code_interpreter tool. There can be a maximum of 20 files associated with the tool.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -VectorStoresForFileSearch
The vector store attached to this thread. There can be a maximum of 1 vector store attached to the thread.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -FileIdsForFileSearch
A list of file IDs to add to the vector store. There can be a maximum of 10000 files in a vector store.

```yaml
Type: Object[]
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

[https://platform.openai.com/docs/api-reference/threads/modifyThread](https://platform.openai.com/docs/api-reference/threads/modifyThread)
