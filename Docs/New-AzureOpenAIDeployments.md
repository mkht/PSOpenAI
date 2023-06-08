---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/New-AzureOpenAIDeployments.md
schema: 2.0.0
---

# New-AzureOpenAIDeployments

## SYNOPSIS
Creates a new deployment for the Azure OpenAI resource according to the given specification.

## SYNTAX

```
New-AzureOpenAIDeployments
    [-Model] <String>
    [-ScaleType <String>]
    [-ScaleCapacity <Int32>]
    [-ApiBase <Uri>]
    [-ApiVersion <String>]
    [-ApiKey <SecureString>]
    [-AuthType <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates a new deployment for the Azure OpenAI resource according to the given specification.  
https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/deployments/create

## EXAMPLES

### Example 1: Creating a deployment.
```powershell
PS C:\> $global:OPENAI_API_KEY = '<Put your api key here>'
PS C:\> $global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'
PS C:\> New-AzureOpenAIDeployments -Model text-davinci-002
```

```yaml
scale_settings : @{scale_type=standard}
model          : text-davinci-002
owner          : organization-owner
id             : deployment-afa0669ca01e4693ae3a93baf40f26d6
status         : succeeded
object         : deployment
created_at     : 2023/04/28 12:53:27
updated_at     : 2023/04/28 12:53:27
```

## PARAMETERS

### -Model
The OpenAI model identifier (model-id) to deploy.

```yaml
Type: String
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -ScaleType
Defines how scaling operations will be executed.

```yaml
Type: String
Accepted values: standard, manual
Required: False
Position: Named
Default value: "standard"
```

### -ScaleCapacity
The constant reserved capacity of the inference endpoint for this deployment. This parameter is effenctive only when the `-ScaleType` as `manual`.

```yaml
Type: Int32
Required: False
Position: Named
Default value: 1
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [pscustomobject]

## NOTES

## RELATED LINKS
