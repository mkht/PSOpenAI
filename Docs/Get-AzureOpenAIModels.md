---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-AzureOpenAIModels.md
schema: 2.0.0
---

# Get-AzureOpenAIModels

## SYNOPSIS
Lists the currently available models.

## SYNTAX

```
Get-AzureOpenAIModels
    [[-Name] <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiVersion <String>]
    [-ApiKey <Object>]
    [-AuthType <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Gets a list of all models that are accessible by the Azure OpenAI resource. These include base models as well as all successfully completed fine-tuned models owned by the Azure OpenAI resource.  
https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/models/list

## EXAMPLES

### Example 1: List all available models.
```PowerShell
PS C:\> $global:OPENAI_API_KEY = '<Put your api key here>'
PS C:\> $global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'
PS C:\> Get-AzureOpenAIModels | select -ExpandProperty ID
```
```yaml
text-curie-001
text-davinci-001
text-davinci-002
gpt-35-turbo
...
```

### Example 2: Get specific model information.
```PowerShell
PS C:\> Get-AzureOpenAIModels -Name "gpt-35-turbo"
```
```yaml
capabilities     : @{fine_tune=False; ...
lifecycle_status : preview
deprecation      : @{inference=1690848000}
id               : gpt-35-turbo
status           : succeeded
object           : model
created_at       : 2023/03/09 9:00:00
updated_at       : 2023/03/09 9:00:00
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
The default value is `2023-03-15-preview`

```yaml
Type: string
Required: False
Position: Named
Default value: "2023-03-15-preview"
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

## INPUTS

## OUTPUTS

### [pscustomobject]

## NOTES

## RELATED LINKS

[https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/models/list](https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/models/list)

