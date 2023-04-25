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
Request-ChatGPT
    [-Message] <String>
    [-Name <String[]>]
    [-Model <String>]
    [-RolePrompt <String[]>]
    [-Temperature <Double>]
    [-TopP <Double>]
    [-NumberOfAnswers <UInt16>]
    [-Stream]
    [-StopSequence <String[]>]
    [-MaxTokens <Int32>]
    [-PresencePenalty <Double>]
    [-FrequencyPenalty <Double>]
    [-LogitBias <IDictionary>]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
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
PS C:\> Request-ChatGPT -Message "Who are you?" | select Answer
```
```
I am an AI language model created by OpenAI, designed to assist with ...
```

### Example 2: Multiple questions with context preserved. (chats)
```PowerShell
PS> $FirstQA = Request-ChatGPT -Message "What is the population of the United States?"
PS> $FirstQA.Answer

As of September 2021, the estimated population of the United States is around 331.4 million people.

PS\> $SecondQA = $FirstQA | Request-ChatGPT -Message "Translate the previous answer into French."
PS\> $SecondQA.Answer

En septembre 2021, la population estimée des États-Unis est d'environ 331,4 millions de personnes.
```

### Example 3: Stream completions.
```PowerShell
PS C:\> Request-ChatGPT 'Please describe ChatGPT in 100 charactors.' -Stream | Write-Host -NoNewline
```

![stream](/Docs/images/StreamOutput.gif)


## PARAMETERS

### -Message
The messages to generate chat completions.

```yaml
Type: String
Required: False
Position: 1
Accept pipeline input: True (ByValueFromPipeline)
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
Default value: gpt-3.5-turbo
```

### -RolePrompt
An optional text to set the behavior of the assistant.

```yaml
Type: String[]
Aliases: system
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

### -User
A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.

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
Note 1: Retries will only be performed if the request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. Other errors (e.g., authentication failure) will not be performed.  
Note 2: Retry intervals increase exponentially with jitters, such as `1s > 2s > 4s > 8s > 16s`

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -ApiKey
Specifies API key for authentication.  
The type of data should `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_API_KEY` or `$env:OPENAI_API_KEY`

```yaml
Type: Object
Aliases: Token
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
Accept pipeline input: True (ByValueFromPipeline)
```

## INPUTS

## OUTPUTS

### [pscustomobject]
## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/chat/chat-completions](https://platform.openai.com/docs/guides/chat/chat-completions)

[https://platform.openai.com/docs/api-reference/chat/create](https://platform.openai.com/docs/api-reference/chat/create)

