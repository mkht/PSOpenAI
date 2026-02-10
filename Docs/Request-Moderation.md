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
    [-Images <String[]>]
    [-Model <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Given a input text, outputs if the model classifies it as violating OpenAI's content policy.  
The moderation endpoint is free to use when monitoring the inputs and outputs of OpenAI APIs.  
https://developers.openai.com/api/docs/guides/moderation/

## EXAMPLES

### Example 1
```PowerShell
PS C:\> $Result = Request-Moderation -Text "I want to kill them."
PS C:\> $Result.results[0].categories
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
A string of text to classify for moderation.

```yaml
Type: String[]
Aliases: Input
Required: False
Position: 1
Accept pipeline input: True (ByValue)
```

### -Images
An array of images to passing the model. You can specifies local image file or remote url.  

```yaml
Type: String[]
Required: False
Position: Named
```

### -Model
The content moderation model you would like to use.

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
Specifies an API endpoint URL such like: `https://your-api-endpoint.test/v1`  
If not specified, it will use `https://api.openai.com/v1`

```yaml
Type: System.Uri
Required: False
Position: Named
Default value: https://api.openai.com/v1
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

[https://developers.openai.com/api/docs/guides/moderation/](https://developers.openai.com/api/docs/guides/moderation/)

[https://developers.openai.com/api/reference/resources/moderations/](https://developers.openai.com/api/reference/resources/moderations/)

