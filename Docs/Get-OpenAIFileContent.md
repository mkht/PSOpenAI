---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-OpenAIFileContent.md
schema: 2.0.0
---

# Get-OpenAIFileContent

## SYNOPSIS
Retrieves the contents of a file.

## SYNTAX

```
Get-OpenAIFileContent
    [-FileId] <String>
    [-OutFile <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Retrieves the contents of a file. You can choose to output as a byte array or save to a file.  
Note: The OpenAI API specification limits the types of files whose contents can be retrieved.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-OpenAIFileContent -FileId 'file-abc123' -OutFile C:\file.csv
```

Retrieve the contents of the file whose ID is file-abc123 and save it to C:\file.csv

## PARAMETERS

### -FileId
The ID of the file to use for this request.

```yaml
Type: String
Aliases: Id, file_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -OutFile
The path of the file to save.

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

### [System.Byte[]]

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/files/retrieve-contents](https://platform.openai.com/docs/api-reference/files/retrieve-contents)
