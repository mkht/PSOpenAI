---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/New-Container.md
schema: 2.0.0
---

# New-Container

## SYNOPSIS
Create Container.

## SYNTAX

```
New-Container
    [-Name] <String>
    [-ExpiresAfterMinutes <UInt32>]
    [-ExpiresAfterAnchor <String>]
    [-FileId <String[]>]
    [-MemoryLimit <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Create a new Container for CodeInterpreter tools.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-Container -Name "My Container"
```
Creates a new container with the name "My Container".

### 例 2
```powershell
PS C:\> New-Container -Name "My Container" -FileId ('file-abc123', 'file-def456')
```
Creates a new container with the name "My Container" and copies two files to the container.

## PARAMETERS

### -Name
Name of the container to create.

```yaml
Type: String
Required: True
Position: 0
```

### -ExpiresAfterMinutes
Container expiration time in minutes.

```yaml
Type: UInt32
Required: False
Position: Named
```

### -ExpiresAfterAnchor
Time anchor for the expiration time. Currently only 'last_active_at' is supported.

```yaml
Type: String
Required: False
Position: Named
Default value: last_active_at
```

### -FileId
IDs of files to copy to the container.

```yaml
Type: String[]
Aliases: file_ids
Required: False
Position: Named
```

### -MemoryLimit
Optional memory limit for the container. Defaults to `1g`. Supported values are `1g`, `4g`, `16g`, and `64g`.
```yaml
Type: String
Aliases: memory_limit
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

### PSCustomObject

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/containers/createContainers](https://platform.openai.com/docs/api-reference/containers/createContainers)
