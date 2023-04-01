---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version:
schema: 2.0.0
---

# Enter-ChatGPT

## SYNOPSIS
Communicate with ChatGPT interactively on the console.

## SYNTAX

```
Enter-ChatGPT [[-Model] <String>] [[-RolePrompt] <String>] [[-Temperature] <Double>] [[-TopP] <Double>]
 [[-StopSequence] <String[]>] [[-MaxTokens] <Int32>] [[-PresencePenalty] <Double>]
 [[-FrequencyPenalty] <Double>] [[-TimeoutSec] <Int32>] [[-Token] <Object>] [-NoHeader] [<CommonParameters>]
```

## DESCRIPTION
Communicate with ChatGPT interactively on the console.  
This command will wait for user input on the terminal. You type your question to ChatGPT and press Enter twice to send the question and see the answer from ChatGPT. You may then ask additional questions.

## EXAMPLES

### Example 1
```powershell
PS C:\> Enter-ChatGPT -Token 'YOUR_OPENAI_APIKEY' -NoHeader
```

![Interactive Chat](/Docs/images/InteractiveChat.gif)


## PARAMETERS

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

### -NoHeader
Suppresses the display of header strings

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
