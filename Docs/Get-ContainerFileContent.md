---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-ContainerFileContent.md
schema: 2.0.0
---

# Get-ContainerFileContent

## SYNOPSIS
Retrieve Container File Content

## SYNTAX

```
Get-ContainerFileContent
    [-ContainerId] <String>
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
Get the content of a file attached to a container.  
You can specify the container and file by their IDs, or pass a ContainerFile object.  
The content can be saved to a local file or output as a byte array.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-ContainerFileContent -ContainerId 'cont_abc123' -FileId 'file-abc123' -OutFile 'C:\data\sample.pdf'
```
Download the file content and save it to `C:\data\sample.pdf`.

### Example 2
```powershell
PS C:\> $ContentBytes = Get-ContainerFileContent -ContainerId 'cont_abc123' -FileId 'file-abc123'
```
Download the file content and output as a byte array.

### Example 3
```powershell
PS C:\> $File = Get-ContainerFile -ContainerId 'cont_abc123' -FileId 'file-abc123'
PS C:\> Get-ContainerFileContent -ContainerFile $File -OutFile 'C:\data\sample.pdf'
```
Download the file content using a ContainerFile object and save it to a local file.

## PARAMETERS

### -ContainerId
The ID of the container.

```yaml
Type: String
Aliases: Container, container_id
Parameter Sets: Id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -FileId
The ID of the file to retrieve.

```yaml
Type: String
Aliases: file_id
Parameter Sets: Id
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -ContainerFile
A ContainerFile object from Get-ContainerFile.

```yaml
Type: PSCustomObject
Parameter Sets: ContainerFile
Required: True
Position: 0
Accept pipeline input: True (ByValue)
```

### -OutFile
The path to the local file to save the content.  
If not specified, the content is output as a byte array.

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
Note: Retries will only be performed if the request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. Other errors (e.g., authentication failure) will not be retried.

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -ApiBase
Specifies an API endpoint URL such as: `https://your-api-endpoint.test/v1`  
If not specified, it will use `https://api.openai.com/v1`.

```yaml
Type: System.Uri
Required: False
Position: Named
Default value: https://api.openai.com/v1
```

### -ApiKey
Specifies API key for authentication.  
The type of data should be `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_API_KEY` or `$env:OPENAI_API_KEY`.

```yaml
Type: Object
Required: False
Position: Named
```

### -Organization
Specifies Organization ID used for an API request.  
If not specified, it will try to use `$global:OPENAI_ORGANIZATION` or `$env:OPENAI_ORGANIZATION`.

```yaml
Type: string
Aliases: OrgId
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

### Byte[]
If `-OutFile` is not specified, outputs the file content as a byte array.

## NOTES

## RELATED LINKS

[https://developers.openai.com/api/reference/resources/containers/subresources/files/subresources/content/methods/retrieve/](https://developers.openai.com/api/reference/resources/containers/subresources/files/subresources/content/methods/retrieve/)
