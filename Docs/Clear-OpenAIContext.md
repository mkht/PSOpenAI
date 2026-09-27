---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Clear-OpenAIContext.md
schema: 2.0.0
---

# Set-OpenAIContext

## SYNOPSIS
Resets the common parameter context set by Set-OpenAIContext.

## SYNTAX

```
Clear-OpenAIContext
```

## DESCRIPTION
Resets the common parameter context set by Set-OpenAIContext.

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-OpenAIContext -ApiKey 'API_KEY'
PS C:\> Clear-OpenAIContext
PS C:\> Get-OpenAIContext

ApiKey        : 
ApiBase       : 
Organization  : 
TimeoutSec    : 0
MaxRetryCount : 0
```

## PARAMETERS

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
