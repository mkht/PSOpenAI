---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/New-VideoRemix.md
schema: 2.0.0
---

# New-Video

## SYNOPSIS
Creates a new video remix job.

## SYNTAX

```
New-Video
    [-Prompt] <String>
    [-VideoId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Remix lets you take an existing video and make targeted adjustments without regenerating everything from scratch. You can provide a text prompt to guide the changes you want to make, and the model will generate a new version of the video that incorporates those changes while preserving the original content as much as possible.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-VideoRemix -Prompt 'Change the background to a sunny beach' -VideoId 'video_abc123'
```

Creates a new video remix job using the specified prompt and video ID.


## PARAMETERS

### -Prompt
Updated text prompt that directs the remix generation.

```yaml
Type: String
Required: True
Position: 0
```

### -VideoId
The identifier of the video to delete.

```yaml
Type: String
Aliases: video_id, Id
Required: True
Position: 1
Accept pipeline input: True (ByPropertyName, ByValue)
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

[https://developers.openai.com/api/reference/resources/videos/methods/remix/](https://developers.openai.com/api/reference/resources/videos/methods/remix/)

