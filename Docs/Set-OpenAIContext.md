---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Set-OpenAIContext.md
schema: 2.0.0
---

# Set-OpenAIContext

## SYNOPSIS
Sets common parameters that are implicitly used when executing functions.

## SYNTAX

```
Set-OpenAIContext
    [-ApiKey <SecureString>]
    [-ApiType <OpenAIApiType>]
    [-ApiBase <Uri>]
    [-ApiVersion <String>]
    [-AuthType <String>]
    [-Organization <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [<CommonParameters>]
```

## DESCRIPTION
Parameters set in the context are implicitly used when each function is executed. This eliminates the need to specify the same parameters repeatedly. Any parameters explicitly specified for each function take precedence over those set in the context.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-OpenAIContext -ApiType 'Azure' -ApiKey 'AZURE_API_KEY' -ApiBase 'https://my-endpoint.openai.azure.com/'
PS C:\> Request-ChatCompletion -Message 'Hello Azure OpenAI'
```

Because the context is set to use Azure, Request-ChatCompletion is executed to Azure instead of the default OpenAI.

## PARAMETERS

### -ApiKey
Specifies API key for authentication.  
API key specified in the context take precedence over environment and global variables.

```yaml
Type: Object
Required: False
Position: Named
```

### -ApiType
Specify whether to call OpenAI or Azure OpenAI Service. Supported values are "OpenAI" or "Azure".

```yaml
Type: String
Required: False
Position: Named
```

### -ApiBase
Specifies an API endpoint URL such like: `https://your-api-endpoint.test/v1`  
URL specified in the context take precedence over environment and global variables.

```yaml
Type: System.Uri
Required: False
Position: Named
```

### -ApiVersion
Specify a string representing the API version. This is only valid when using the Azure OpenAI Service.

```yaml
Type: String
Required: False
Position: Named
```

### -AuthType
Specify the authentication type to be used. Valid values are "OpenAI", "Azure", or "Azure_AD".

```yaml
Type: String
Required: False
Position: Named
```

### -Organization
Specifies Organization ID which used for an API request. Specified value in the context take precedence over environment and global variables.

```yaml
Type: string
Aliases: OrgId
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
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
