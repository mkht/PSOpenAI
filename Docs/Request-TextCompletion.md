---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-TextCompletion.md
schema: 2.0.0
---

# Request-TextCompletion

## SYNOPSIS
Creates a completion for the provided prompt and parameters.

## SYNTAX

```
Request-TextCompletion
    [[-Prompt] <String[]>]
    [-Suffix <String>]
    [-Model <String>]
    [-Temperature <Double>]
    [-TopP <Double>]
    [-NumberOfAnswers <UInt16>]
    [-StopSequence <String[]>]
    [-MaxTokens <Int32>]
    [-PresencePenalty <Double>]
    [-FrequencyPenalty <Double>]
    [-User <String>]
    [-Echo <Boolean>]
    [-BestOf <UInt16>]
    [-TimeoutSec <Int32>]
    [-Token <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Given a prompt, the AI model will return one or more predicted completions.  
https://platform.openai.com/docs/guides/completion/text-completion

## EXAMPLES

### Example 1: Estimate the sentences that follow.
```PowerShell
Request-TextCompletion -Prompt 'This is a hamburger store.' | select Answer
```
```
We serves
-classic hamburgers
-tofu burgers
```

## PARAMETERS

### -Prompt
(Required)
The prompt(s) to generate completions for

```yaml
Type: String[]
Aliases: Message
Required: False
Position: 1
Accept pipeline input: True (ByValue)
```

### -Suffix
The suffix that comes after a completion of inserted text.

```yaml
Type: String
Required: False
Position: Named
```

### -Model
The name of model to use.
The default value is `text-davinci-003`.

```yaml
Type: String
Required: False
Position: Named
Default value: text-davinci-003
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
How many texts to generate for each prompt.
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
The max value depends on models.

```yaml
Type: Int32
Aliases: max_tokens
Required: False
Position: Named
Default value: 2048
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

### -Echo
Echo back the prompt in addition to the completion.
The default value is `$false`.

```yaml
Type: Boolean
Required: False
Position: Named
Default value: $false
```

### -BestOf
Generates best_of completions server-side and returns the "best" (the one with the highest log probability per token).

```yaml
Type: UInt16
Aliases: best_of
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

[https://platform.openai.com/docs/guides/completion/text-completion](https://platform.openai.com/docs/guides/completion/text-completion)

[https://platform.openai.com/docs/api-reference/completions/create](https://platform.openai.com/docs/api-reference/completions/create)

