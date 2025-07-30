---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-ChatCompletion.md
schema: 2.0.0
---

# Request-ChatCompletion

## SYNOPSIS
Creates a completion for the chat message.

## SYNTAX

```
Request-ChatCompletion
    [-Message] <String>
    [-Role <String>]
    [-Name <String>]
    [-Model <String>]
    [-SystemMessage <String[]>]
    [-DeveloperMessage <String[]>]
    [-Modalities <String[]>]
    [-Voice <String>]
    [-InputAudio <String>]
    [-InputAudioFormat <String>]
    [-AudioOutFile <String>]
    [-OutputAudioFormat <String>]
    [-Images <String[]>]
    [-ImageDetail <String>]
    [-Tools <IDictionary[]>]
    [-ToolChoice <Object>]
    [-ParallelToolCalls]
    [-InvokeTools <String>]
    [-WebSearchContextSize <String>]
    [-WebSearchUserLocationCity <String>]
    [-WebSearchUserLocationCountry <String>]
    [-WebSearchUserLocationRegion <String>]
    [-WebSearchUserLocationTimeZone <String>]
    [-Prediction <String>]
    [-Temperature <Double>]
    [-TopP <Double>]
    [-NumberOfAnswers <UInt16>]
    [-Stream]
    [-Store]
    [-ReasoningEffort <String>]
    [-MetaData <IDictionary>]
    [-StopSequence <String[]>]
    [-MaxTokens <Int32>]
    [-MaxCompletionTokens <Int32>]
    [-PresencePenalty <Double>]
    [-FrequencyPenalty <Double>]
    [-LogitBias <IDictionary>]
    [-LogProbs <Boolean>]
    [-TopLogProbs <UInt16>]
    [-Format <Object>]
    [-JsonSchema <String>]
    [-Seed <Int64>]
    [-ServiceTier <String>]
    [-PromptCacheKey <String>]
    [-SafetyIdentifier <String>]
    [-User <String>]
    [-AsBatch]
    [-CustomBatchId <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [-Organization <String>]
    [-History <Object[]>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates a completion for the chat message.  
https://platform.openai.com/docs/guides/chat/chat-completions

## EXAMPLES

### Example 1: Ask one question to ChatGPT, and get answer.
```PowerShell
PS C:\> Request-ChatCompletion -Message "Who are you?" | select Answer
```
```
I am an AI language model created by OpenAI, designed to assist with ...
```

### Example 2: Multiple questions with context preserved. (chats)
```PowerShell
PS> $FirstQA = Request-ChatCompletion -Message "What is the population of the United States?"
PS> $FirstQA.Answer

As of September 2021, the estimated population of the United States is around 331.4 million people.

PS\> $SecondQA = $FirstQA | Request-ChatCompletion -Message "Translate the previous answer into French."
PS\> $SecondQA.Answer

En septembre 2021, la population estimée des États-Unis est d'environ 331,4 millions de personnes.
```

### Example 3: Stream completions.
```PowerShell
PS C:\> Request-ChatCompletion 'Please describe ChatGPT in 100 charactors.' -Stream | Write-Host -NoNewline
```

![stream](/Docs/images/StreamOutput.gif)

### Example 4: Function calling
```PowerShell
PS C:\> $PingFunction = New-ChatCompletionFunction -Command 'Test-Connection' -IncludeParameters ('TargetName','Count')
PS C:\> $Message = 'Ping the Google Public DNS address three times and briefly report the results.'
PS C:\> $GPTPingAnswer = Request-ChatCompletion -Message $Message -Model gpt-4o -Tools $PingFunction -InvokeTools Auto
PS C:\> $GPTPingAnswer | select Answer
```

### Example 5: Image input (Vision)
```PowerShell
PS C:\> Request-ChatCompletion -Message $Message -Model gpt-4o -Images "C:\image.png"
```

### Example 6: Audio input / output
```PowerShell
PS C:\> Request-ChatCompletion -Modalities text, audio -InputAudio 'C:\hello.mp3' -AudioOutFile 'C:\response.mp3' -Model gpt-4o-audio-preview
```

## PARAMETERS

### -Message
The messages to generate chat completions.

```yaml
Type: String
Aliases: Text
Required: False
Position: 1
Accept pipeline input: True (ByValue)
```

### -Role
The role of the messages author. One of `user`, `system`, `developer` or `function`.  
The default is `user`.

```yaml
Type: String
Required: False
Position: Named
```

### -Name
The name of the author of this message.  
This is an optional field, and may contain a-z, A-Z, 0-9, hyphens, and underscores, with a maximum length of 64 characters.

```yaml
Type: String
Required: False
Position: Named
```

### -Model
The name of model to use.
The default value is `gpt-3.5-turbo`.

```yaml
Type: String
Required: False
Position: Named
Accept pipeline input: True (ByPropertyName)
Default value: gpt-3.5-turbo
```

### -SystemMessage
An optional text to set the behavior of the assistant.

```yaml
Type: String[]
Aliases: system, RolePrompt
Required: False
Position: Named
```

### -DeveloperMessage
Developer-provided instructions that the model should follow, regardless of messages sent by the user. With o1 models and newer, developer messages replace the previous system messages.

```yaml
Type: String[]
Required: False
Position: Named
```

### -Modalities
Output types that you would like the model to generate for this request.  
Some models can generate both text and audio. To request that responses, you can specify: `("text", "audio")`

```yaml
Type: String[]
Required: False
Position: Named
```

### -Voice
The voice the model uses to respond.

```yaml
Type: String
Required: False
Position: Named
```

### -InputAudio
The path of the audio file to passing the model. Supported formats are `wav` and `mp3`.

```yaml
Type: String
Aliases: input_audio
Required: False
Position: Named
```

### -InputAudioFormat
Specifies the format of the input audio file. If not specified, the format is automatically determined from the file extension.

```yaml
Type: String
Required: False
Position: Named
```

### -AudioOutFile
Specifies where audio response from the model will be saved. If the model does not return a audio response, nothing is saved.

```yaml
Type: String
Required: False
Position: Named
```

### -OutputAudioFormat
Specifies the format of the output audio file. The default value is `mp3`.

```yaml
Type: String
Required: False
Position: Named
```

### -Images
An array of images to passing the model. You can specifies local image file or remote url.  

```yaml
Type: String[]
Required: False
Position: Named
```

### -ImageDetail
Controls how the model processes the image and generates its textual understanding. You can select from `Low` or `High`.  
See more details : https://platform.openai.com/docs/guides/vision/low-or-high-fidelity-image-understanding

```yaml
Type: String
Required: False
Position: Named
Default value: Auto
```

### -Tools
A list of tools the model may call. Use this to provide a list of functions the model may generate JSON inputs for.  
https://github.com/mkht/PSOpenAI/blob/main/Guides/How_to_call_functions_with_ChatGPT.ipynb

```yaml
Type: System.Collections.IDictionary[]
Required: False
Position: Named
```

### -ToolChoice
Controls how the model responds to function calls.  
- `none` means the model does not call a function, and responds to the end-user.  
- `auto` means the model can pick between an end-user or calling a function.  
Specifying a particular function via `@{type = "function"; function = @{name = "my_function"}}` forces the model to call that function.

```yaml
Type: Object
Aliases: tool_choice
Required: False
Position: Named
```

### -ParallelToolCalls
Whether to enable parallel function calling during tool use. The default is true (enabled)

```yaml
Type: SwitchParameter
Aliases: parallel_tool_calls
Required: False
Position: Named
Default value: True
```

### -InvokeTools
Selects the action to be taken when the GPT model requests a function call.  
- `None`: The requested function is not executed. This is the default.  
- `Auto`: Automatically executes the requested function.  
- `Confirm`: Displays a confirmation to the user before executing the requested function.

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchContextSize
High level guidance for the amount of context window space to use for the web search. One of `low`, `medium`, or `high`

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchUserLocationCity
Approximate location parameters for the web search.

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchUserLocationCountry
Approximate location parameters for the web search.

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchUserLocationRegion
Approximate location parameters for the web search.

```yaml
Type: String
Required: False
Position: Named
```

### -WebSearchUserLocationTimeZone
Approximate location parameters for the web search.

```yaml
Type: String
Required: False
Position: Named
```

### -Prediction
Static predicted output content, such as the content of a text file that is being regenerated.

```yaml
Type: String
Required: False
Position: Named
```

### -Temperature
What sampling temperature to use, between `0` and `2`.  
Higher values like `0.8` will make the output more random, while lower values like `0.2` will make it more focused and deterministic.

```yaml
Type: Double
Required: False
Position: Named
```

### -TopP
An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass.  
So `0.1` means only the tokens comprising the top `10%` probability mass are considered.

```yaml
Type: Double
Aliases: top_p
Required: False
Position: Named
```

### -NumberOfAnswers
How many chat completion choices to generate for each input message.  
The default value is `1`.

```yaml
Type: UInt16
Aliases: n
Required: False
Position: Named
Default value: 1
```

### -Stream
If set, partial message deltas will be sent, like in ChatGPT.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: False
```

### -Store
Whether or not to store the output of this chat completion request for use in model distillation or evals.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: False
```

### -ReasoningEffort
**o-series models only**  
Constrains effort on reasoning for reasoning models. Currently supported values are low, medium, and high.  
Reducing reasoning effort can result in faster responses and fewer tokens used on reasoning in a response.

```yaml
Type: String
Aliases: reasoning_effort
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

### -StopSequence
Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence.

```yaml
Type: String[]
Aliases: stop
Required: False
Position: Named
```

### -MaxTokens
This value is now deprecated in favor of MaxCompletionTokens.

```yaml
Type: Int32
Aliases: max_tokens
Required: False
Position: Named
```

### -MaxCompletionTokens
An upper bound for the number of tokens that can be generated for a completion, including visible output tokens and reasoning tokens.

```yaml
Type: Int32
Aliases: max_completion_tokens
Required: False
Position: Named
```

### -PresencePenalty
Number between `-2.0` and `2.0`.  
Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.

```yaml
Type: Double
Aliases: presence_penalty
Required: False
Position: Named
```

### -FrequencyPenalty
Number between `-2.0` and `2.0`.  
Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.

```yaml
Type: Double
Aliases: frequency_penalty
Required: False
Position: Named
```

### -LogitBias
Modify the likelihood of specified tokens appearing in the completion.  
Accepts a maps of tokens to an associated bias value from `-100` to `100`. You can use `ConvertTo-Token` to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between `-1` and `1` should decrease or increase likelihood of selection; values like `-100` or `100` should result in a ban or exclusive selection of the relevant token.  
As an example, you can pass like so: `@{23182 = 20; 88847 = -100}`  
ID 23182 maps to "apple" and ID 88847 maps to "banana". Thus, this example increases the likelihood of the word "apple" being included in the response from the AI and greatly reduces the likelihood of the word "banana" being included.

```yaml
Type: IDictionary
Aliases: logit_bias
Required: False
Position: Named
```

### -LogProbs
Whether to return log probabilities of the output tokens or not. If true, returns the log probabilities of each output token returned in the `content` of `message`.

```yaml
Type: Boolean
Required: False
Position: Named
```

### -TopLogProbs
An integer between 0 and 20 specifying the number of most likely tokens to return at each token position, each with an associated log probability. `logprobs` must be set to `true` if this parameter is used.

```yaml
Type: UInt16
Aliases: top_logprobs
Required: False
Position: Named
```

### -Format
Specifies the format that the model must output.  
- `text` is default.  
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

### -Seed
If specified, the system will make a best effort to sample deterministically, such that repeated requests with the same seed and parameters should return the same result.

```yaml
Type: Int64
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

### -PromptCacheKey
Used by OpenAI to cache responses for similar requests to optimize your cache hit rates.

```yaml
Type: String
Aliases: prompt_cache_key
Required: False
Position: Named
```

### -SafetyIdentifier
A stable identifier used to help detect users of your application that may be violating OpenAI's usage policies. The IDs should be a string that uniquely identifies each user.

```yaml
Type: String
Aliases: safety_identifier
Required: False
Position: Named
```

### -User
(deprecated) This field is being replaced by `SafetyIdentifier` and `PromptCacheKey`.

```yaml
Type: String
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
This parameter is valid only when the `-AsBatch` swicth is used. Otherwise, it is simply ignored.
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

### [pscustomobject]
## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/chat/chat-completions](https://platform.openai.com/docs/guides/chat/chat-completions)

[https://platform.openai.com/docs/api-reference/chat/create](https://platform.openai.com/docs/api-reference/chat/create)

