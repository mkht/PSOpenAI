---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Remove-AzureOpenAIDeployments.md
schema: 2.0.0
---

# Remove-AzureOpenAIDeployments

## SYNOPSIS
Deletes the deployment specified by the given deployment-id.

## SYNTAX

```
Remove-AzureOpenAIDeployments
    [-Deployment] <String>
    [-ApiBase <Uri>]
    [-ApiVersion <String>]
    [-ApiKey <SecureString>]
    [-AuthType <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-Force]
    [-WhatIf]
    [-Confirm]
    [<CommonParameters>]
```

## DESCRIPTION
Deletes the deployment specified by the given deployment-id.  
https://learn.microsoft.com/en-us/rest/api/cognitiveservices/azureopenaistable/deployments/delete

## EXAMPLES

### Example 1: Delete a deployment.
```powershell
PS C:\> $global:OPENAI_API_KEY = '<Put your api key here>'
PS C:\> $global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'
PS C:\> Remove-AzureOpenAIDeployments -Deployment 'deployment-afa0669ca01e4693ae3a93baf40f26d6'
```

### Example 2: Specifies a target from pipeline.
```powershell
PS C:\> Get-AzureOpenAIDeployments -Deployment 'deployment-afa0669ca01e4693ae3a93baf40f26d6' | Remove-AzureOpenAIDeployments -Force
```

## PARAMETERS

### -Deployment
The name (id) of the deployment for deleting.

```yaml
Type: String
Aliases: Engine, id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
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

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Aliases: cf
Required: False
Position: Named
```

### -Force
Supress prompts for confirmation.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Aliases: wi
Required: False
Position: Named
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Void

## NOTES

## RELATED LINKS
