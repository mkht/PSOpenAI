---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-TextEdit.md
schema: 2.0.0
---

# Request-TextEdit

## SYNOPSIS
Generate or edit text from the provided prompt and parameters.

## SYNTAX

```
Request-TextEdit 
    [-Instruction] <String>
    [-Text <String>]
    [-Model <String>]
    [-Temperature <Double>]
    [-TopP <Double>]
    [-NumberOfAnswers <UInt16>]
    [-TimeoutSec <Int32>]
    [-Token <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Generate or edit text from the provided prompt and parameters.  
https://platform.openai.com/docs/guides/completion/editing-text

## EXAMPLES

### Example 1: Fix the spelling mistakes.
```PowerShell
Request-TextEdit -Text 'What day of teh wek is it?' -Instruction "Fix the spelling mistakes" | select Answer
```
```
What day of the week is it?
```

## PARAMETERS

### -Instruction
(Required)
The prompt(s) to generate text for.

```yaml
Type: String
Aliases: Message
Required: True
Position: 1
Accept pipeline input: True (ByValue)
```

### -Text
The input text to use as a starting point for the edit.

```yaml
Type: String
Aliases: Input
Required: False
Position: Named
```

### -Model
The name of model to use.
The default value is `text-davinci-edit-001`.

```yaml
Type: String
Required: False
Position: Named
Default value: text-davinci-edit-001
Accept pipeline input: False
Accept wildcard characters: False
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

[https://platform.openai.com/docs/guides/completion/editing-text](https://platform.openai.com/docs/guides/completion/editing-text)

[https://platform.openai.com/docs/api-reference/edits/create](https://platform.openai.com/docs/api-reference/edits/create)

