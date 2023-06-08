---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-AzureEmbeddings.md
schema: 2.0.0
---

# Request-AzureEmbeddings

## SYNOPSIS
Creates an embedding vector representing the input text.

## SYNTAX

```
Request-AzureEmbeddings
    [-Text] <String[]>
    -Deployment <String>
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiVersion <String>]
    [-ApiKey <Object>]
    [-AuthType <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates an embedding vector representing the input text by Azure OpenAI Service.  
https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference#embeddings

## EXAMPLES

### Example 1: Get a vector representation of a given input.
```powershell
PS C:\> $global:OPENAI_API_KEY = '<Put your api key here>'
PS C:\> $global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'
PS C:\> Request-Embeddings -Text 'Waiter, the food was delicious...' -Deployment 'YourDeploymentName' | select -ExpandProperty data
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

### -Deployment
The deployment name you chose when you deployed the model.  
Deployments must be created in Azure Portal in advance.

```yaml
Type: String
Required: True
Position: Named
```

### -User
A unique identifier representing for your end-user. This will help Azure OpenAI monitor and detect abuse.

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

### -ApiBase
Specifies yhe name of your Azure OpenAI resource endpoint such like: 
`https://{your-resource-name}.openai.azure.com/`  
If not specified, it will try to use `$global:OPENAI_API_BASE` or `$env:OPENAI_API_BASE`

```yaml
Type: System.Uri
Required: False
Position: Named
```

### -ApiVersion
The API version to use for this operation.  

```yaml
Type: string
Required: False
Position: Named
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

### -AuthType
Specifies the authentication type.  
You can choose from `azure` or `azure_ad`.  
The default value is `azure`

```yaml
Type: string
Required: False
Position: Named
Default value: "azure"
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [pscustomobject]
## NOTES

## RELATED LINKS

[https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference#embeddings](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference#embeddings)
