---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-Moderation.md
schema: 2.0.0
---

# Request-Moderation

## SYNOPSIS
Given a input text, outputs if the model classifies it as violating OpenAI's content policy.

## SYNTAX

```
Request-Moderation
    [-Text] <String[]>
    [-Model <String>]
    [-TimeoutSec <Int32>]
    [-Token <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Given a input text, outputs if the model classifies it as violating OpenAI's content policy.  
The moderation endpoint is free to use when monitoring the inputs and outputs of OpenAI APIs.  
https://platform.openai.com/docs/guides/moderation/overview

## EXAMPLES

### Example 1
```PowerShell
PS C:\> $Result = Request-Moderation -Text "I want to kill them."
PS C:\> $Result.results.categories
```
```yaml
sexual           : False
hate             : False
violence         : True
self-harm        : False
sexual/minors    : False
hate/threatening : False
violence/graphic : False
```

## PARAMETERS

### -Text
(Required)
The input text to classify.

```yaml
Type: String[]
Aliases: Input
Required: True
Position: 1
Accept pipeline input: True (ByValue)
```

### -Model
The name of model to use.  
Two content moderations models are available: `text-moderation-stable` and `text-moderation-latest`.  
The default value is `text-moderation-latest`.

```yaml
Type: String
Required: False
Position: Named
Default value: text-moderation-latest
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

[https://platform.openai.com/docs/guides/moderation/overview](https://platform.openai.com/docs/guides/moderation/overview)

[https://platform.openai.com/docs/api-reference/moderations](https://platform.openai.com/docs/api-reference/moderations)

