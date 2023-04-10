---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-Embeddings.md
schema: 2.0.0
---

# Request-Embeddings

## SYNOPSIS
Creates an embedding vector representing the input text.

## SYNTAX

```
Request-Embeddings
    [-Text] <String[]>
    [-Model <String>]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-Token <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates an embedding vector representing the input text.  
https://platform.openai.com/docs/guides/embeddings

## EXAMPLES

### Example 1: Get a vector representation of a given input.
```powershell
Request-Embeddings -Text 'Waiter, the food was delicious...' | select -ExpandProperty data
```

```yaml
object    : embedding
index     : 0
embedding : {0.01004226, -0.01884855, 0.01824344, -0.01565562…}
Text      : Waiter, the food was delicious...
```

## PARAMETERS

### -Text
(Required)
Input text to get embeddings for

```yaml
Type: String[]
Aliases: Input
Required: True
Position: 1
Accept pipeline input: True (ByValue)
```

### -Model
The name of model to use.
The default value is `text-embedding-ada-002`.

```yaml
Type: String
Required: False
Position: Named
Default value: text-embedding-ada-002
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

### -Token
Specifies API key for authentication.  
The type of data should `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_TOKEN` or `$env:OPENAI_TOKEN`

```yaml
Type: Object
Required: False
Position: Named
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [pscustomobject]
## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/embeddings](https://platform.openai.com/docs/guides/embeddings)

[https://platform.openai.com/docs/api-reference/embeddings](https://platform.openai.com/docs/api-reference/embeddings)