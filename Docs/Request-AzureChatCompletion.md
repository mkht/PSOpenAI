---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-AzureChatCompletion.md
schema: 2.0.0
---

# Request-AzureChatCompletion

## SYNOPSIS
Creates a completion for the chat message.

## SYNTAX

```
Request-AzureChatCompletion
    [-Message] <String>
    [-Role <String>]
    [-Name <String>]
    -Deployment <String>
    [-SystemMessage <String[]>]
    [-Images <String[]>]
    [-ImageDetail <String>]
    [-Tools <IDictionary[]>]
    [-ToolChoice <Object>]
    [-InvokeTools <String>]
    [-Temperature <Double>]
    [-TopP <Double>]
    [-NumberOfAnswers <UInt16>]
    [-Stream]
    [-StopSequence <String[]>]
    [-MaxTokens <Int32>]
    [-PresencePenalty <Double>]
    [-FrequencyPenalty <Double>]
    [-LogitBias <IDictionary>]
    [-Format <String>]
    [-Seed <Int64>]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <System.Uri>]
    [-ApiVersion <string>]
    [-ApiKey <Object>]
    [-AuthType <string>]
    [-History <Object[]>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates a completion for the chat message by Azure OpenAI Service.  
https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference?source=recommendations#chat-completions

## EXAMPLES

### Example 1
### Example 1: Ask one question to Azure OpenAI Service, and get an answer.
```PowerShell
PS C:\> $global:OPENAI_API_KEY = '<Put your api key here>'
PS C:\> $global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'
PS C:\> Request-AzureChatCompletion -Message "Who are you?" -Deployment 'YourDeploymentName' | select Answer
```
```
I am an AI language model created by OpenAI, designed to assist with ...
```

## PARAMETERS

### -Message
The messages to generate chat completions.

```yaml
Type: String
Aliases: Text
Required: False
Position: 1
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Role
The role of the messages author. One of `user` or `system`.  
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

### -Deployment
The deployment name you chose when you deployed the model.  
Deployments must be created in Azure Portal in advance.

```yaml
Type: String
Aliases: Engine, Model
Required: True
Position: Named
```

### -SystemMessage
An optional text to set the behavior of the assistant.

```yaml
Type: String[]
Aliases: system, RolePrompt
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

### -StopSequence
Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence.

```yaml
Type: String[]
Aliases: stop
Required: False
Position: Named
```

### -MaxTokens
The maximum number of tokens allowed for the generated answer.  
Maximum value depends on model. (`4096` for `gpt-3.5-turbo` or `8192` for `gpt-4`)

```yaml
Type: Int32
Aliases: max_tokens
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

### -Format
Specifies the format that the model must output.  
- `text` is default.  
- `json_object` enables JSON mode, which guarantees the message the model generates is valid JSON.  
- `raw_response` returns raw response content from API.

```yaml
Type: String
Aliases: response_format
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

### -User
A unique identifier representing for your end-user. This will help Azure OpenAI monitor and detect abuse.

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
Specifies the name of your Azure OpenAI resource endpoint such like: 
`https://{your-resource-name}.openai.azure.com/`  
If not specified, it will try to use `$global:OPENAI_API_BASE` or `$env:OPENAI_API_BASE`

```yaml
Type: System.Uri
Required: False
Position: Named
```

### -ApiVersion
The API version to use for this operation.  

```yaml
Type: string
Required: False
Position: Named
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

### -AuthType
Specifies the authentication type.  
You can choose from `azure` or `azure_ad`.  
The default value is `azure`

```yaml
Type: string
Required: False
Position: Named
Default value: "azure"
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

[https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference?source=recommendations#chat-completions](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference?source=recommendations#chat-completions)

