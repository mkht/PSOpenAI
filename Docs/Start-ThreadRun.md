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

### ThreadAndRun
```
Start-ThreadRun
    [-Assistant] <String>
    -Message <String>
    [-Model <String>]
    [-Instructions <String>]
    [-AdditionalMessages <Object[]>]
    [-Role <String>]
    [-FileIdsForCodeInterpreter <Object[]>]
    [-VectorStoresForFileSearch <Object[]>]
    [-MaxPromptTokens <Int32>]
    [-MaxCompletionTokens <Int32>]
    [-TruncationStrategyType <String>]
    [-TruncationStrategyLastMessages <Int32>]
    [-ToolChoice <String>]
    [-ToolChoiceFunctionName <String>]
    [-UseCodeInterpreter]
    [-UseFileSearch]
    [-Functions <IDictionary>]
    [-MetaData <IDictionary>]
    [-Temperature <Double>]
    [-Stream]
    [-Format <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [-AdditionalQuery <IDictionary>]
    [-AdditionalHeaders <IDictionary>]
    [-AdditionalBody <Object>]
    [<CommonParameters>]
```

### Run
```
Start-ThreadRun
    [-ThreadId] <String>
    [-Assistant] <Object>
    [-Model <String>]
    [-Instructions <String>]
    [-AdditionalInstructions <String>]
    [-AdditionalMessages <Object[]>]
    [-MaxPromptTokens <Int32>]
    [-MaxCompletionTokens <Int32>]
    [-TruncationStrategyType <String>]
    [-TruncationStrategyLastMessages <Int32>]
    [-ToolChoice <String>]
    [-ToolChoiceFunctionName <String>]
    [-UseCodeInterpreter]
    [-UseFileSearch]
    [-Functions <IDictionary>]
    [-MetaData <IDictionary>]
    [-Temperature <Double>]
    [-Stream]
    [-Format <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [-AdditionalQuery <IDictionary>]
    [-AdditionalHeaders <IDictionary>]
    [-AdditionalBody <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Starts a run.

## EXAMPLES

### Example 1
```powershell
PS C:\> Start-ThreadRun -ThreadId 'thread_abc123' -Assistant 'asst_abc123'
```

Starts a run of the thread with spcified assiatnt.

## PARAMETERS

### -ThreadId
The ID of the thread to run.

```yaml
Type: String
Aliases: thread_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Assistant
The ID of the assistant to use to execute this run.

```yaml
Type: Object
Aliases: assistant_id, AssistantId
Required: True
Position: 1
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

### -AdditionalMessages
Adds additional messages to the thread before creating the run.

```yaml
Type: Object[]
Aliases: additional_messages
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

### -Temperature
What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.

```yaml
Type: Double
Required: False
Position: Named
```

### -Functions
A list of functions the model may call. Use this to provide a list of functions the model may generate JSON inputs for.  

```yaml
Type: IDictionary[]
Required: False
Position: Named
```

### -UseCodeInterpreter
Override whether the code interpreter tool enable or not.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -UseFileSearch
Override whether the file_search tool enable or not.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -Stream
If set, partial message deltas will be sent, like in ChatGPT.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: False
```

### -Format
Specifies the output format of this function.  
  - default will only outputs text message.
  - json_object enables JSON mode, which guarantees the message the model generates is valid JSON.
  - raw_response returns raw response content from API.

```yaml
Type: String
Aliases: response_format
Required: False
Position: Named
Default value: default
```

### -TimeoutSec
Specifies how long the request can be pending before it times out. The default value is 0 (infinite).

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -MaxRetryCount
Number between 0 and 100. Specifies the maximum number of retries if the request fails. The default value is 0 (No retry).  
Note : Retries will only be performed if the request fails with a 429 (Rate limit reached) or 5xx (Server side errors) error. Other errors (e.g., authentication failure) will not be performed.

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -ApiBase
Specifies an API endpoint URL such like: https://your-api-endpoint.test/v1 If not specified, it will use https://api.openai.com/v1

```yaml
Type: Uri
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

### -FileId
A list of File IDs that the message should use. There can be a maximum of 10 files attached to a message. Useful for tools like file_search and code_interpreter that can access and use files.

```yaml
Type: String[]
Aliases: file_ids
Required: False
Position: Named
```

### -MaxPromptTokens
The maximum number of prompt tokens that may be used over the course of the run.

```yaml
Type: Int32
Aliases: max_prompt_tokens
Required: False
Position: Named
```

### -MaxCompletionTokens
The maximum number of completion tokens that may be used over the course of the run.

```yaml
Type: Int32
Aliases: max_completion_tokens
Required: False
Position: Named
```

### -Message
The content of the message.

```yaml
Type: String
Aliases: Content, Text
Required: True
Position: Named
```

### -Role
The role of the entity that is creating the message. Allowed value is `user` or `assistant`.

```yaml
Type: String
Required: False
Position: Named
```

### -ToolChoice
Controls which (if any) tool is called by the model. You can choose from `auto`, `none`, `code_interpreter`, `retrieve` or `function`.

```yaml
Type: String
Aliases: tool_choice
Required: False
Position: Named
```

### -ToolChoiceFunctionName
The name of the function to call. You must specify this param when the ToolChoice is specified to `function`.

```yaml
Type: String
Required: False
Position: Named
```

### -TruncationStrategyType
The truncation strategy to use for the thread. The default is `auto`. You can choose from `auto` or `last_messages`

```yaml
Type: String
Aliases: last_messages
Required: False
Position: Named
Default value: auto
```

### -TruncationStrategyLastMessages
The number of most recent messages from the thread when constructing the context for the run.

```yaml
Type: Int32
Aliases: last_messages
Required: False
Position: Named
```

### -AdditionalQuery
If you want to explicitly send an extra query params, you can do so.

```yaml
Type: IDictionary
Required: False
Position: Named
```

### -AdditionalHeaders
If you want to explicitly send an extra headers, you can do so.

```yaml
Type: IDictionary
Required: False
Position: Named
```

### -AdditionalBody
If you want to explicitly send an extra body, you can do so.

```yaml
Type: Object
Required: False
Position: Named
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/runs/createRun](https://platform.openai.com/docs/api-reference/runs/createRun)

