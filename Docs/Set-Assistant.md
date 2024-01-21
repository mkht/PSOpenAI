---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Set-Assistant.md
schema: 2.0.0
---

# Set-Assistant

## SYNOPSIS
Modifies an assistant.

## SYNTAX

```
Set-Assistant
    [-InputObject] <Object>
    [-Name <String>]
    [-Model <String>]
    [-Description <String>]
    [-Instructions <String>]
    [-Tools <IDictionary[]>]
    [-UseCodeInterpreter <Boolean>]
    [-UseRetrieval <Boolean>]
    [-FileId <String[]>]
    [-MetaData <IDictionary>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Modifies an assistant.

## EXAMPLES

### Example 1
```powershell
PS C:\> $Assistant = Set-Assistant -Assistant 'asst_abc123' -Instructions "You are a math teacher." -UseCodeInterpreter $true
```

Modifies the assistant that has ID with `asst_abc123`.

## PARAMETERS

### -InputObject
Specifies ID of an assistant or Assistant object.

```yaml
Type: Object
Aliases: Assistant, assistant_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Name
The name of the assistant. The maximum length is 256 characters.

```yaml
Type: String
Required: False
Position: Named
```

### -Model
ID of the model to use. The default value is `gpt-3.5-turbo`.

```yaml
Type: String
Required: False
Position: Named
Default value: gpt-3.5-turbo
```

### -Description
The description of the assistant. The maximum length is 512 characters.

```yaml
Type: String
Required: False
Position: Named
```

### -Instructions
The system instructions that the assistant uses. The maximum length is 32768 characters.

```yaml
Type: String
Required: False
Position: Named
```

### -Tools
A list of tool enabled on the assistant. There can be a maximum of 128 tools per assistant.

```yaml
Type: IDictionary[]
Required: False
Position: Named
```

### -UseCodeInterpreter
Specifies Whether the code interpreter tool enable or not. The default is `$false`.

```yaml
Type: Boolean
Required: False
Position: Named
Default value: $false
```

### -UseRetrieval
Specifies Whether the retrieval tool enable or not. The default is `$false`.

```yaml
Type: Boolean
Required: False
Position: Named
Default value: $false
```

### -FileId
A list of file IDs attached to this assistant. There can be a maximum of 20 files attached to the assistant.

```yaml
Type: String[]
Aliases: file_ids
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

[https://platform.openai.com/docs/api-reference/assistants/modifyAssistant](https://platform.openai.com/docs/api-reference/assistants/modifyAssistant)
[https://platform.openai.com/docs/assistants/overview/](https://platform.openai.com/docs/assistants/overview/)

