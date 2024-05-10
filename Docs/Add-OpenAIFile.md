---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Add-OpenAIFile.md
schema: 2.0.0
---

# Add-OpenAIFile

## SYNOPSIS
Upload a file that can be used across various endpoints.

## SYNTAX

### File
```
Add-OpenAIFile
    [-File] <FileInfo>
    -Purpose <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

### Content
```
Add-OpenAIFile
    [-Content] <byte[]>
    -Name <String>
    -Purpose <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Upload a file that can be used across various endpoints.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-OpenAIFile -File "C:\sample.csv" -Purpose assistants
```

Upload `sample.csv` file to OpenAI.

### Example 2
```powershell
PS C:\> $ByteArray = [System.Text.Encoding]::UTF8.GetBytes('some text data')
PS C:\> Add-OpenAIFile -Content $ByteArray -Name 'filename.txt' -Purpose assistants
```

Upload a content of bytes to OpenAI

## PARAMETERS

### -File
The File path to be uploaded.

```yaml
Type: System.IO.FileInfo
Parameter Sets: File
Required: True
Position: 0
Accept pipeline input: True (ByValue)
```

### -Content
Byte array to be uploaded.

```yaml
Type: byte[]
Parameter Sets: Content
Required: True
Position: 0
```

### -Name
The File name to be uploaded.

```yaml
Type: String
Parameter Sets: Content
Required: True
Position: Named
```

### -Purpose
The intended purpose of the uploaded file.  
You can specify `fine-tune`, `assistants` or `batch`.

```yaml
Type: String
Required: True
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

### PSCustomObject

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/files/create](https://platform.openai.com/docs/api-reference/files/create)

