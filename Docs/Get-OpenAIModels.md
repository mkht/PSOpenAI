---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-OpenAIModels.md
schema: 2.0.0
---

# Get-OpenAIModels

## SYNOPSIS
Lists the currently available models.

## SYNTAX

```
Get-OpenAIModels
    [[-Name] <String>]
    [-Token <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Lists the currently available models, and provides basic information about each one such as the owner and availability.  
You can refer to the Models documentation to understand what models are available and the differences between them.  
https://platform.openai.com/docs/api-reference/models/list

## EXAMPLES

### Example 1: List all available models.
```PowerShell
PS C:\> Get-OpenAIModels | select -ExpandProperty ID
```
```yaml
babbage
davinci
gpt-3.5-turbo-0301
text-davinci-003
...
```

### Example 2: Get specific model information.
```PowerShell
PS C:\> Get-OpenAIModels -Name "gpt-3.5-turbo"
```
```yaml
id         : gpt-3.5-turbo
object     : model
owned_by   : openai
permission : {@{id=modelperm-QvbW9EnkbwPtWZu...
root       : gpt-3.5-turbo
parent     :
created    : 2023/02/28 18:56:42
```

## PARAMETERS

### -Name
Specifies the model name which you wish to get.  
If not specified, lists all available models.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Model, ID

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Token
Specifies API key for authentication.  
The type of data should `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_TOKEN` or `$env:OPENAI_TOKEN`

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### [pscustomobject]

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/models/list](https://platform.openai.com/docs/api-reference/models/list)

