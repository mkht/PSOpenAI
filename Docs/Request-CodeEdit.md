---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-CodeEdit.md
schema: 2.0.0
---

# Request-CodeEdit

## SYNOPSIS
Generate or edit code from the provided prompt and parameters.

## SYNTAX

```
Request-CodeEdit
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
Generate or edit code from the provided prompt and parameters.  
https://platform.openai.com/docs/guides/code/editing-code

## EXAMPLES

### Example 1: Create code from instruction.
```PowerShell
Request-CodeEdit -Instruction 'Fizz Buzz in PowerShell' | select Answer
```
```PowerShell
For ($x=1; $x -le 10; $x++)
{
if ($x%3 -eq 0 -and $x%5 -eq 0)
{"FizzBuzz";}
ElseIf ($x%3 -eq 0)
{ "Fizz";}
ElseIf ($x%5 -eq 0)
{"Buzz";}
Else
{ $x;}
}
```
## PARAMETERS

### -Instruction
(Required)
The prompt(s) to generate codes for.

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
The default value is `code-davinci-edit-001`.

```yaml
Type: String
Required: False
Position: Named
Default value: code-davinci-edit-001
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
How many codes to generate for each prompt.  
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

[https://platform.openai.com/docs/guides/code/editing-code](https://platform.openai.com/docs/guides/code/editing-code)

[https://platform.openai.com/docs/api-reference/edits/create](https://platform.openai.com/docs/api-reference/edits/create)

