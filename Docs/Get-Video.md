---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-Video.md
schema: 2.0.0
---

# Get-Video

## SYNOPSIS
Retrieves one or more video generation jobs.

## SYNTAX

### Get
```
Get-Video
    [-VideoId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

### List
```
Get-Video
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
Retrieves a specific video generation job or lists recent jobs. Use the job metadata to track progress or to download video content once processing finishes.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-Video -VideoId 'video_fb4e'
```

Gets the job details for the specified video ID.

### Example 2
```powershell
PS C:\> Get-Video -Limit 5 -Order desc
```

Lists the five most recent video jobs.

### Example 3
```powershell
PS C:\> Get-Video -All
```

Lists all available video jobs by paging through the API.

## PARAMETERS

### -VideoId
The identifier of the video to retrieve.

```yaml
Type: String
Parameter Sets: Get
Aliases: video_id, Id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Limit
A number of items to retrieve. Limit can range between 1 and 100, and the default is 20.

```yaml
Type: Int32
Parameter Sets: List
Required: False
Position: Named
Default value: 20
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

### -All
When this switch is specified, all video jobs will be retrieved.

```yaml
Type: SwitchParameter
Parameter Sets: List
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

[https://platform.openai.com/docs/api-reference/videos/retrieve](https://platform.openai.com/docs/api-reference/videos/retrieve)
[https://platform.openai.com/docs/api-reference/videos/list](https://platform.openai.com/docs/api-reference/videos/list)
