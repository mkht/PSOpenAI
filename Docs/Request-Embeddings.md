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
    [-EncodingFormat <String>]
    [-Dimensions <Int32>]
    [-User <String>]
    [-AsBatch]
    [-CustomBatchId <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [-Organization <String>]
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

### -EncodingFormat
The format to return the embeddings in. Can be either `float` or `base64`
The default value is `float`.

```yaml
Type: String
Aliases: encoding_format
Required: False
Position: Named
Default value: float
```

### -Dimensions
The number of dimensions the resulting output embeddings should have. Only supported in `text-embedding-3` and later models.

```yaml
Type: Int32
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

### -AsBatch
If this is specified, this cmdlet returns an object for Batch input  
It does not perform an API request to OpenAI. It is useful with `Start-Batch` cmdlet.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: False
```

### -CustomBatchId
A unique id that will be used to match outputs to inputs of batch. Must be unique for each request in a batch.  
This parameter is valid only when the `-AsBatch` swicth is used. Otherwise, it is simply ignored.
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [pscustomobject]
## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/embeddings](https://platform.openai.com/docs/guides/embeddings)

[https://platform.openai.com/docs/api-reference/embeddings](https://platform.openai.com/docs/api-reference/embeddings)
