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
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiKey <Object>]
    [-Organization <string>]
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
gpt-3.5-turbo-0613
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
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

## INPUTS

## OUTPUTS

### [pscustomobject]

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/models/list](https://platform.openai.com/docs/api-reference/models/list)

