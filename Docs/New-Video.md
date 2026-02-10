---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/New-Video.md
schema: 2.0.0
---

# New-Video

## SYNOPSIS
Creates a new video generation job.

## SYNTAX

```
New-Video
    [-Prompt] <String>
    [-InputReference <String>]
    [-Model <String>]
    [-Seconds <String>]
    [-Size <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates a new asynchronous job that generates a video with the requested model, duration, and resolution. The cmdlet returns the job metadata so that you can poll its status or download the generated content when it completes.

## EXAMPLES

### Example 1
```powershell
PS C:\> New-Video -Prompt 'Dancing Doggo'
```

Creates a new video job using the default model, duration, and resolution.

### Example 2
```powershell
PS C:\> New-Video -Prompt 'Dancing Donuts' -Model 'sora-2-pro' -Seconds 12 -Size 1280x720
```

Creates a 12-second landscape video with the `sora-2-pro` model.

## PARAMETERS

### -Prompt
Text prompt that describes the video to generate.

```yaml
Type: String
Required: True
Position: 0
```

### -InputReference
Path to an optional image reference that guides generation.

```yaml
Type: String
Aliases: input_reference
Required: False
Position: Named
```

### -Model
The video generation model to use. The default value is `sora-2`.

```yaml
Type: String
Required: False
Position: Named
Default value: sora-2
```

### -Seconds
Length of the generated video, in seconds. Supported values are `4`, `8`, and `12`. The default value is `4`.

```yaml
Type: String
Required: False
Position: Named
Default value: 4
```

### -Size
Resolution of the generated video. Supported values are `720x1280`, `1280x720`, `1024x1792`, and `1792x1024`. The default value is `720x1280`.

```yaml
Type: String
Required: False
Position: Named
Default value: 720x1280
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

[https://developers.openai.com/api/docs/guides/video-generation](https://developers.openai.com/api/docs/guides/video-generation)
[https://developers.openai.com/api/reference/resources/videos/methods/create/](https://developers.openai.com/api/reference/resources/videos/methods/create/)

