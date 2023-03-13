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
    [-Model <String>]
    [-RolePrompt <String>]
    [-Temperature <Double>]
    [-TopP <Double>]
    [-NumberOfAnswers <UInt16>]
    [-StopSequence <String[]>]
    [-MaxTokens <Int32>]
    [-PresencePenalty <Double>]
    [-FrequencyPenalty <Double>]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-Token <Object>]
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

## PARAMETERS

### -Message
(Required)
The messages to generate chat completions.

```yaml
Type: String
Required: True
Position: 1
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
Type: String
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
The max value is `4096`.

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

### -Token
Specifies API key for authentication.  
The type of data should `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_TOKEN` or `$env:OPENAI_TOKEN`

```yaml
Type: Object
Required: False
Position: Named
```


## INPUTS

## OUTPUTS

### [pscustomobject]
## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/chat/chat-completions](https://platform.openai.com/docs/guides/chat/chat-completions)

[https://platform.openai.com/docs/api-reference/chat/create](https://platform.openai.com/docs/api-reference/chat/create)

