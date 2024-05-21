---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-OpenAIContext.md
schema: 2.0.0
---

# Set-OpenAIContext

## SYNOPSIS
Gets common parameters that are implicitly used when executing functions.

## SYNTAX

```
Get-OpenAIContext
```

## DESCRIPTION
Gets the common parameter context that is set by Set-OpenAIContext.
Note: Objects obtained with Get-OpenAIContext are read-only, and changes to their property values are not reflected in the context. To set the context, use Set-OpenAIContext.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-OpenAIContext -ApiType 'Azure' -ApiKey 'AZURE_API_KEY' -ApiBase 'https://my-endpoint.openai.azure.com/'
PS C:\> Get-OpenAIContext

ApiKey        : System.Security.SecureString
ApiType       : Azure
ApiBase       : https://my-endpoint.openai.azure.com/
ApiVersion    : 
AuthType      : azure
Organization  : 
TimeoutSec    : 0
MaxRetryCount : 0
```

## PARAMETERS

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
