---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-ContainerFile.md
schema: 2.0.0
---

# Get-ContainerFile

## SYNOPSIS
Retrieve Container File.

## SYNTAX

### Get
```
Get-ContainerFile
    [-ContainerId] <String>
    [-FileId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

### List
```
Get-ContainerFile
    [-ContainerId] <String>
    [-All]
    [-Limit <Int32>]
    [-Order <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Get a single file attached to a container, or list multiple files attached to a container.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-ContainerFile -ContainerId 'cont_abc123' -FileId 'file-abc123'
```
Get the file with ID `file-abc123` attached to the container with ID `cont_abc123`.

### Example 2
```powershell
PS C:\> Get-ContainerFile -ContainerId 'cont_abc123' -Limit 5 -Order desc
```
Get the latest 5 files attached to the container with ID `cont_abc123`.

### Example 3
```powershell
PS C:\> Get-ContainerFile -ContainerId 'cont_abc123' -All
```
Get all files attached to the container with ID `cont_abc123`.

## PARAMETERS

### -ContainerId
The ID of the container.

```yaml
Type: String
Aliases: Container, container_id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -FileId
The ID of the file to retrieve.

```yaml
Type: String
Aliases: File, file_id
Parameter Sets: Get
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Limit
A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 20.

```yaml
Type: Int32
Parameter Sets: List
Required: False
Position: Named
Default value: 20
```

### -All
When this switch is specified, all files attached to the container will be retrieved.

```yaml
Type: SwitchParameter
Parameter Sets: List
Required: False
Position: Named
```

### -Order
Sort order by the created timestamp of the objects. `asc` for ascending order and `desc` for descending order. The default is `asc`.

```yaml
Type: String
Parameter Sets: List
Accepted values: asc, desc
Required: False
Position: Named
Default value: asc
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

### PSCustomObject

## NOTES

## RELATED LINKS
[https://developers.openai.com/api/reference/resources/containers/subresources/files/methods/retrieve/](https://developers.openai.com/api/reference/resources/containers/subresources/files/methods/retrieve/)
[https://developers.openai.com/api/reference/resources/containers/subresources/files/methods/list/](https://developers.openai.com/api/reference/resources/containers/subresources/files/methods/list/)
