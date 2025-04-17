---
external help file: PSOpenAI-help.xml
Module Name: psOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-Response.md
schema: 2.0.0
---

# Request-Response

## SYNOPSIS
Creates a model response.

## SYNTAX

```
Request-Response
    [[-Message] <String>]
    [-Role <String>]
    [-Model <String>]
    [-SystemMessage <String[]>]
    [-DeveloperMessage <String[]>]
    [-Instructions <String>]
    [-PreviousResponseId <String>]
    [-Images <String[]>] 
    [-ImageDetail <String>]
    [-Files <String[]>] 
    [-ToolChoice <Object>] 
    [-ParallelToolCalls <Boolean>]
    [-Functions <IDictionary[]>]
    [-UseFileSearch] 
    [-FileSearchVectorStoreIds <String[]>]
    [-FileSearchMaxNumberOfResults <Int32>]
    [-FileSearchRanker <String>]
    [-FileSearchScoreThreshold <Double>]
    [-UseWebSearch]
    [-WebSearchType <String>]
    [-WebSearchContextSize <String>]
    [-WebSearchUserLocationCity <String>]
    [-WebSearchUserLocationCountry <String>]
    [-WebSearchUserLocationRegion <String>]
    [-WebSearchUserLocationTimeZone <String>]
    [-UseComputerUse]
    [-ComputerUseEnvironment <String>]
    [-ComputerUseDisplayHeight <Int32>]
    [-ComputerUseDisplayWidth <Int32>]
    [-Include <String[]>]
    [-Truncation <String>]
    [-Temperature <Double>] 
    [-TopP <Double>] 
    [-Store <Boolean>]
    [-Stream]
    [-StreamOutputType <String>] 
    [-ReasoningEffort <String>] 
    [-ReasoningSummary <String>]
    [-MetaData <IDictionary>]
    [-MaxOutputTokens <Int32>] 
    [-OutputType <Object>]
    [-OutputRawResponse]
    [-JsonSchema <String>]
    [-JsonSchemaName <String>] 
    [-JsonSchemaDescription <String>] 
    [-JsonSchemaStrict <Boolean>] 
    [-ServiceTier <String>]
    [-User <String>]
    [-Organization <String>]
    [-AsBatch]
    [-CustomBatchId <String>] 
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>] 
    [-ApiKey <SecureString>]
    [-History <Object[]>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates a model response. Provide text or image inputs to generate text or JSON outputs.

## EXAMPLES

### Example 1: Text input
```powershell
PS C:\> Request-Response "How do I make sauerkraut?" -Model 'gpt-4o' | select output_text
```
```
Making sauerkraut is a simple process that involves fermenting cabbage. ...
```

### Example 2: Image input
```powershell
PS C:\> Request-Response "What is this?" -Images 'C:\donut.png' -Model 'gpt-4o'
```

### Example 3: File input
```powershell
PS C:\> Request-Response "Summarize this document" -Images 'C:\recipient.pdf' -Model 'o3-mini'
```

### Example 4: Web search
```powershell
PS C:\> Request-Response "Tell me a recent top 3 tech news." -UseWebSearch -Model 'gpt-4o'
```

### Example 5: Streaming output
```powershell
PS C:\> Request-Response "Implement Zeller's congruence in PowerShell." -Stream | Write-Host -NoNewline
```

## PARAMETERS

### -Message
A text input to the model.

```yaml
Type: String
Aliases: UserMessage, input
Required: False
Position: 0
```

### -Role
The role of the message input. One of `user`, `system`, or `developer`. The default is `user`.

```yaml
Type: String
Required: False
Position: Named
```

### -Model
The name of model to use.  
The default value is `gpt-4o-mini`.

```yaml
Type: String
Required: False
Position: Named
Accept pipeline input: True (ByPropertyName)
Default value: gpt-4o-mini
```

### -SystemMessage
(Instead of this parameter, the use of the `-Instructions` parameter is recommended.)  
Instructions that the model should follow.

```yaml
Type: String[]
Required: False
Position: Named
```

### -DeveloperMessage
(Instead of this parameter, the use of the `-Instructions` parameter is recommended.)  
Instructions that the model should follow.

```yaml
Type: String[]
Required: False
Position: Named
```

### -Instructions
Inserts a system (or developer) message as the first item in the model's context.

```yaml
Type: String
Required: False
Position: Named
```

### -PreviousResponseId
The unique ID of the previous response to the model. Use this to create multi-turn conversations.

```yaml
Type: String
Aliases: previous_response_id
Required: False
Position: Named
Accept pipeline input: True (ByPropertyName)
```

### -Images
A list of images to passing the model. You can specify local image file or remote url.  

```yaml
Type: String[]
Required: False
Position: Named
```

### -ImageDetail
Controls how the model processes the image and generates its textual understanding. You can select from `Low` or `High`.  

```yaml
Type: String
Accepted values: auto, low, high
Required: False
Position: Named
Default value: auto
```

### -Files
A file input to the model.  
You can speciy a list of the local file path or the ID of the file to be uploaded.

```yaml
Type: String[]
Required: False
Position: Named
```

### -ToolChoice
How the model should select which tool (or tools) to use when generating a response.

```yaml
Type: String
Aliases: tool_choice
Required: False
Position: Named
```

### -ParallelToolCalls
Whether to allow the model to run tool calls in parallel.

```yaml
Type: Boolean
Aliases: parallel_tool_calls
Required: False
Position: Named
```

### -Functions
A list of functions the model may call.

```yaml
Type: IDictionary[]
Required: False
Position: Named
```

### -UseFileSearch
If you want to use the File search built-in tool, Should specify this switch as enabled.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -FileSearchVectorStoreIds
The IDs of the vector stores to search.

```yaml
Type: String[]
Required: False
Position: Named
```

### -FileSearchMaxNumberOfResults
The maximum number of results to return.

```yaml
Type: Int32
Required: False
Position: Named
```

### -FileSearchRanker
The ranker to use for the file search.

```yaml
Type: String
Required: False
Position: Named
```

### -FileSearchScoreThreshold
The score threshold for the file search, a number between 0 and 1. Numbers closer to 1 will attempt to return only the most relevant results, but may return fewer results.

```yaml
Type: Double
Required: False
Position: Named
```

### -UseWebSearch
If you want to use the Web search built-in tool, Should specify this switch as enabled.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -WebSearchType
The type of the web search tool.

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchContextSize
High level guidance for the amount of context window space to use for the search. One of `low`, `medium`, or `high`. `medium` is the default.

```yaml
Type: String
Accepted values: low, medium, high
Required: False
Position: Named
Default value: medium
```

### -WebSearchUserLocationCity
Free text input for the city of the user, e.g. `San Francisco`.

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchUserLocationCountry
The two-letter ISO country code of the user, e.g. `US`.

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchUserLocationRegion
Free text input for the region of the user, e.g. `California`.

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchUserLocationTimeZone
The IANA timezone of the user, e.g. `America/Los_Angeles`.

```yaml
Type: String
Required: False
Position: Named
```

### -UseComputerUse
If you want to use the Computer-use built-in tool, Should specify this switch as enabled.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -ComputerUseEnvironment
The type of computer environment to control.  
Possible values: `browser`, `mac`, `windows`, `ubuntu`.

```yaml
Type: String
Required: False
Position: Named
```

### -ComputerUseDisplayHeight
The height of the computer display.

```yaml
Type: Int32
Required: False
Position: Named
```

### -ComputerUseDisplayWidth
The width of the computer display.

```yaml
Type: Int32
Required: False
Position: Named
```

### -Include
Specify additional output data to include in the model response.

```yaml
Type: String[]
Required: False
Position: Named
```

### -Truncation
The truncation strategy to use for the model response. `disabled` (default) or `auto`.

```yaml
Type: String
Required: False
Position: Named
Default value: disabled
```

### -Temperature
What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random.

```yaml
Type: Double
Required: False
Position: Named
```

### -TopP
An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.

```yaml
Type: Double
Aliases: top_p
Required: False
Position: Named
```

### -Store
Whether to store the generated model response for later retrieval via API. The default is `$true`.

```yaml
Type: Boolean
Required: False
Position: Named
Default value: True
```

### -Stream
If set, the model response data will be streamed to the client.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -StreamOutputType
Specifying the format that the function output. This parameter is only valid for the stream output.  
  - `text`   : Output only text deltas that the model generated. (Default)  
  - `object` : Output all events that the API respond.  

```yaml
Type: String
Accepted values: text, object
Required: False
Position: Named
Default value: text
```

### -ReasoningEffort
**o-series models only**  
Constrains effort on reasoning for reasoning models. Currently supported values are low, medium, and high.

```yaml
Type: String
Required: False
Position: Named
```

### -ReasoningSummary
A summary of the reasoning performed by the model. This can be useful for debugging and understanding the model's reasoning process. One of `auto`, `concise` or `detailed`.

```yaml
Type: String
Required: False
Position: Named
```

### -MetaData
Developer-defined tags and values used for filtering completions in the dashboard.

```yaml
Type: IDictionary
Required: False
Position: Named
```

### -MaxOutputTokens
An upper bound for the number of tokens that can be generated for a response.

```yaml
Type: Int32
Aliases: max_output_tokens
Required: False
Position: Named
```

### -OutputType
An object specifying the format that the model must output.  
  - `text`        : Default response format. Used to generate text responses.  
  - `json_schema` : Enables Structured Outputs  
  - `json_object` : Enables the older JSON mode (Not recommended)  

```yaml
Type: Object
Required: False
Position: Named
```

### -OutputRawResponse
If specifies this switch, an output of this function to be a raw response value from the API. (Normally JSON formatted string.)

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -JsonSchema
The schema for the response format, described as a JSON Schema object.

```yaml
Type: String
Required: False
Position: Named
```

### -JsonSchemaName
The name of the response format.

```yaml
Type: String
Required: False
Position: Named
```

### -JsonSchemaDescription
A description of what the response format is for, used by the model to determine how to respond in the format.

```yaml
Type: String
Required: False
Position: Named
```

### -JsonSchemaStrict
Whether to enable strict schema adherence when generating the output.

```yaml
Type: Boolean
Required: False
Position: Named
```

### -ServiceTier
Specifies the latency tier to use for processing the request. This parameter is relevant for customers subscribed to the scale tier service.

```yaml
Type: String
Aliases: service_tier
Required: False
Position: Named
```

### -User
A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.

```yaml
Type: String
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

### -AsBatch
If this is specified, this cmdlet returns an object for Batch input  
It does not perform an API request to OpenAI. It is useful with `Start-Batch` cmdlet.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: False
```

### -CustomBatchId
A unique id that will be used to match outputs to inputs of batch. Must be unique for each request in a batch.  
This parameter is valid only when the `-AsBatch` swicth is used.

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

### -History
An object for keeping the conversation history.

```yaml
Type: Object[]
Required: False
Position: Named
Accept pipeline input: True (ByPropertyName)
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/responses](https://platform.openai.com/docs/api-reference/responses)
