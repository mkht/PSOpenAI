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
    [-AssistantId] <String>
    [-Name <String>]
    [-Model <String>]
    [-Description <String>]
    [-Instructions <String>]
    [-UseCodeInterpreter]
    [-UseFileSearch]
    [-Functions]
    [-FileIdsForCodeInterpreter <Object[]>]
    [-VectorStoresForFileSearch <Object[]>]
    [-FileIdsForFileSearch <Object[]>]
    [-MaxNumberOfFileSearchResults <UInt16>]
    [-RankerForFileSearch <String>]
    [-ScoreThresholdForFileSearch <Double>]
    [-Temperature <Double>]
    [-TopP <Double>]
    [-MetaData <IDictionary>]
    [-Format <Object>]
    [-JsonSchema <String>]
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
PS C:\> $Assistant = Set-Assistant -AssistantId 'asst_abc123' -Instructions "You are a math teacher." -UseCodeInterpreter $true
```

Modifies the assistant that has ID with `asst_abc123`.

## PARAMETERS

### -AssistantId
Specifies ID of an assistant.

```yaml
Type: String
Aliases: assistant_id
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
The system instructions that the assistant uses. The maximum length is 256,000 characters.

```yaml
Type: String
Required: False
Position: Named
```

### -UseCodeInterpreter
Specifies Whether the code interpreter tool enable or not. The default is `$false`.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: $false
```

### -UseFileSearch
Specifies Whether the file_search tool enable or not. The default is `$false`.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: $false
```

### -Functions
A list of functions the model may call. Use this to provide a list of functions the model may generate JSON inputs for.  

```yaml
Type: IDictionary[]
Required: False
Position: Named
```

### -FileIdsForCodeInterpreter
A list of file IDs made available to the code_interpreter tool. There can be a maximum of 20 files associated with the tool.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -VectorStoresForFileSearch
The vector store attached to this assistant. There can be a maximum of 1 vector store attached to the assistant.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -MaxNumberOfFileSearchResults
The maximum number of results the file search tool should output. This number should be between 1 and 50 inclusive.

```yaml
Type: UInt16
Required: False
Position: Named
```

### -RankerForFileSearch
The ranker to use for the file search. If not specified will use the auto ranker.

```yaml
Type: String
Required: False
Position: Named
```

### -ScoreThresholdForFileSearch
The score threshold for the file search. All values must be a floating point number between 0 and 1.

```yaml
Type: double
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

### -Temperature
What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.

```yaml
Type: double
Required: False
Position: Named
```

### -TopP
An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.

```yaml
Type: double
Aliases: top_p
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

### -Format
Specifies the format that the model must output.  
- `auto` is default.  
- `json_object` enables JSON mode, which ensures the message the model generates is valid JSON.  
- `json_schema` enables Structured Outputs which ensures the model will match your supplied JSON schema.
- `raw_response` returns raw response content from API.

```yaml
Type: Object
Aliases: response_format
Required: False
Position: Named
```

### -JsonSchema
Specifies an object or data structure to represent the JSON Schema that the model should be constrained to follow.  
Required if `json_schema` is specified for `-Format`. Otherwise, it is ignored.

```yaml
Type: String
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

[https://platform.openai.com/docs/api-reference/assistants/modifyAssistant](https://platform.openai.com/docs/api-reference/assistants/modifyAssistant)
[https://platform.openai.com/docs/assistants/overview/](https://platform.openai.com/docs/assistants/overview/)

